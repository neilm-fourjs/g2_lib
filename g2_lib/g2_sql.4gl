--------------------------------------------------------------------------------
#+ Genero Genero Library Functions - by Neil J Martin ( neilm@4js.com )
#+ This library is intended as an example of useful library code for use with
#+ Genero 4.00 and above
#+  
#+ No warrantee of any kind, express or implied, is included with this software;
#+ use at your own risk, responsibility for damages (if any) to anyone resulting
#+ from the use of this software rests entirely with the user.
#+  
#+ No includes required.

&ifdef gen320
IMPORT FGL g2_core
&else
PACKAGE g2_lib
IMPORT FGL g2_lib.g2_core
&endif

IMPORT util

CONSTANT SQL_FIRST = 0
CONSTANT SQL_PREV = -1
CONSTANT SQL_NEXT = -2
CONSTANT SQL_LAST = -3

PUBLIC TYPE t_fields RECORD
	colName STRING,
	colType STRING,
	colLength SMALLINT,
	isNumeric BOOLEAN,
	isKey BOOLEAN,
	value STRING,
	para_no SMALLINT,
	formOnly BOOLEAN,
	noEntry BOOLEAN,
	defValue STRING
END RECORD

PUBLIC TYPE sql RECORD
	handle base.SqlHandle,
	table_name STRING,
	key_field STRING,
	key_field_num SMALLINT,
	where_clause STRING,
	column_list STRING,
	rows_count INTEGER,
	current_row INTEGER,
	fields DYNAMIC ARRAY OF t_fields,
	json_rec util.JSONObject
END RECORD

----------------------------------------------------------------------------------------------------
-- Initialize the record for the sql
--
-- @param l_tabName the Table name.
-- @param l_cols list of columns or "*"
-- @param l_keyField the column to use for the primary key
-- @param l_where the WHERE clause
FUNCTION (this sql) g2_SQLinit(l_tabName STRING, l_cols STRING, l_keyField STRING, l_where STRING)
	LET this.table_name = l_tabName
	LET this.column_list = l_cols
	LET this.key_field = l_keyField
	IF l_where.getLength() < 1 THEN
		LET l_where = "1=1"
	END IF
	LET this.where_clause = l_where
	CALL this.g2_SQLcursor()
END FUNCTION
----------------------------------------------------------------------------------------------------
-- Open the SQL cursor as a SCROLL cursor
FUNCTION (this sql) g2_SQLcursor()
	DEFINE l_sql STRING
	DEFINE x SMALLINT
	IF this.handle IS NOT NULL THEN
		CALL this.g2_SQLclose()
	END IF
	LET l_sql =
			"select " || this.column_list || " from " || this.table_name || " where " || this.where_clause
	LET this.handle = base.SqlHandle.create()
	TRY
		CALL this.handle.prepare(l_sql)
	CATCH
		CALL g2_core.g2_errPopup(
				SFMT(% "Failed to doing prepare for select from '%1'\n%2!", this.table_name, SQLERRMESSAGE))
		EXIT PROGRAM
	END TRY
	CALL this.handle.openScrollCursor()
	CALL this.fields.clear()
	FOR x = 1 TO this.handle.getResultCount()
		LET this.fields[x].colName = this.handle.getResultName(x)
		LET this.fields[x].colType = this.handle.getResultType(x)
		LET this.fields[x].formOnly = FALSE
		LET this.fields[x].isKey = FALSE
		IF this.fields[x].colName.trim() = this.key_field.trim() THEN
			LET this.fields[x].isKey = TRUE
			LET this.key_field_num = x
		END IF
		CALL this.g2_SQLsetColumnProps(x)
	END FOR
	IF this.key_field_num = 0 THEN
		CALL g2_core.g2_errPopup(
				SFMT(% "The key field '%1' doesn't appear to be in the table!", this.key_field.trim()))
		EXIT PROGRAM
	END IF
	IF this.where_clause != "1=2" THEN -- count all the rows for the where clause
-- TODO: Error handling!
		PREPARE count_pre
				FROM "SELECT COUNT(*) FROM " || this.table_name || " WHERE " || this.where_clause
		DECLARE count_cur CURSOR FOR count_pre
		OPEN count_cur
		FETCH count_cur INTO this.rows_count
		CLOSE count_cur
		LET this.current_row = 1
	ELSE
		LET this.rows_count = 0
		LET this.current_row = 0
	END IF
--	MESSAGE "Rows "||this.current_row||" of "||this.rows_count
END FUNCTION
----------------------------------------------------------------------------------------------------
-- Close the cursor if it's open
FUNCTION (this sql) g2_SQLclose()
	IF this.handle IS NOT NULL THEN
		CALL this.handle.close()
	END IF
END FUNCTION
----------------------------------------------------------------------------------------------------
-- Set the properties for the specified column number
--
-- @param l_colNo Column in the array
FUNCTION (this sql) g2_SQLsetColumnProps(l_colNo SMALLINT)
	DEFINE x, y SMALLINT
	DEFINE l_typ, l_lenStr STRING
	LET l_typ = this.fields[l_colNo].colType
	LET x = l_typ.getIndexOf("(", 1)
	IF x > 0 THEN
		LET l_lenStr = l_typ.subString(x + 1, l_typ.getLength() - 1)
		LET y = l_lenStr.getIndexOf(",", 1)
		IF y > 0 THEN
			LET this.fields[l_colNo].colLength = l_lenStr.subString(1, y - 1)
		ELSE
			LET this.fields[l_colNo].colLength = l_lenStr
		END IF
		LET l_typ = l_typ.subString(1, x - 1)
	END IF
	LET this.fields[l_colNo].isNumeric = FALSE
	CASE l_typ
		WHEN "INTEGER"
			LET this.fields[l_colNo].colLength = 8
			LET this.fields[l_colNo].isNumeric = TRUE
		WHEN "SERIAL"
			LET this.fields[l_colNo].colLength = 8
			LET this.fields[l_colNo].isNumeric = TRUE
		WHEN "SMALLINT"
			LET this.fields[l_colNo].colLength = 4
			LET this.fields[l_colNo].isNumeric = TRUE
		WHEN "DECIMAL"
			LET this.fields[l_colNo].isNumeric = TRUE
		WHEN "MONEY"
			LET this.fields[l_colNo].isNumeric = TRUE
		WHEN "DATE"
			LET this.fields[l_colNo].colLength = 10
		WHEN "TIME"
			LET this.fields[l_colNo].colLength = 10
	END CASE
END FUNCTION
----------------------------------------------------------------------------------------------------
-- Fetch the row from database for the current cursor
--
-- @param l_row The row num or 0=First, -1=Prev -2=Next -3=Last
-- @param l_msg Boolean - Show message in the status bar.
FUNCTION (this sql) g2_SQLgetRow(l_row INTEGER, l_msg BOOLEAN)
	DEFINE x SMALLINT
	IF l_row > this.rows_count THEN
		LET l_row = this.rows_count
	END IF
	CASE l_row
		WHEN SQL_FIRST
			CALL this.handle.fetchFirst()
			LET this.current_row = 1
		WHEN SQL_PREV
			IF this.current_row > 1 THEN
				CALL this.handle.fetchPrevious()
				LET this.current_row = this.current_row - 1
			END IF
		WHEN SQL_NEXT
			IF this.current_row < this.rows_count THEN
				CALL this.handle.fetch()
				LET this.current_row = this.current_row + 1
			END IF
		WHEN SQL_LAST
			CALL this.handle.fetchLast()
			LET this.current_row = this.rows_count
		OTHERWISE
			CALL this.handle.fetchAbsolute(l_row)
			LET this.current_row = l_row
	END CASE
	IF status = 0 THEN
		FOR x = 1 TO this.fields.getLength()
			LET this.fields[x].value = this.handle.getResultValue(x)
		END FOR
		IF l_msg THEN
			MESSAGE SFMT(% "Rows %1 of %2", this.current_row, this.rows_count)
		END IF
	END IF
END FUNCTION
----------------------------------------------------------------------------------------------------
-- Update a row using the current data values
FUNCTION (this sql) g2_SQLupdate() RETURNS BOOLEAN
	DEFINE l_sql, l_val, l_key STRING
	DEFINE l_valNumeric DECIMAL(20, 5)
	DEFINE l_updsql base.SqlHandle
	DEFINE x SMALLINT
	DEFINE l_para_no SMALLINT = 1
	LET l_updsql = base.SqlHandle.create()

-- Build the SQL
	LET l_sql = "update " || this.table_name || " SET ("
	FOR x = 1 TO this.fields.getLength()
		IF x != this.key_field_num THEN
			LET l_sql = l_sql.append(this.fields[x].colName)
			IF x != this.fields.getLength() THEN
				LET l_sql = l_sql.append(",")
			END IF
		END IF
	END FOR
	LET l_sql = l_sql.append(") = (")
	FOR x = 1 TO this.fields.getLength()
		IF NOT this.fields[x].isKey AND NOT this.fields[x].formOnly THEN
			LET this.fields[x].para_no = l_para_no
			LET l_para_no = l_para_no + 1
			IF x != this.fields.getLength() THEN
				LET l_sql = l_sql.append("?,")
			ELSE
				LET l_sql = l_sql.append("?")
			END IF
		END IF
	END FOR
	LET l_sql = l_sql.append(") where " || this.key_field || " = ?")
	DISPLAY "SQL:", l_sql, " Key:", l_key
	CALL l_updsql.prepare(l_sql)

-- Update the Parameters.
	FOR x = 1 TO this.fields.getLength()
		IF NOT this.fields[x].formOnly THEN
			LET l_val = this.fields[x].value
			LET l_valNumeric = this.fields[x].value.trim()
			IF this.fields[x].isKey THEN
				LET l_key = this.fields[x].value.trimRight()
			ELSE
				IF this.fields[x].isNumeric THEN
					CALL l_updsql.setParameter(this.fields[x].para_no, l_valNumeric)
				ELSE
					CALL l_updsql.setParameter(this.fields[x].para_no, l_val)
				END IF
			END IF
		END IF
	END FOR
	CALL l_updsql.setParameter(l_para_no, l_key)

-- Excute the SQL
	TRY
		CALL l_updsql.execute()
		MESSAGE "Record Updated"
		DISPLAY "Record Updated, status:", status
	CATCH
		ERROR "Update Failed!"
	END TRY
	IF sqlca.sqlcode = 0 THEN -- refresh the cursor so it shows the updated row.
		CALL this.g2_SQLcursor()
		CALL this.g2_SQLgetRow(this.current_row, FALSE)
	ELSE
		CALL g2_core.g2_errPopup(SFMT(% "Failed to update record!\n%1!", SQLERRMESSAGE))
		RETURN FALSE
	END IF
	RETURN TRUE
END FUNCTION
----------------------------------------------------------------------------------------------------
-- Insert a new row using the current data values
FUNCTION (this sql) g2_SQLinsert() RETURNS BOOLEAN
	DEFINE l_sql, l_val STRING
	DEFINE l_valNumeric DECIMAL(20, 5)
	DEFINE l_inssql base.SqlHandle
	DEFINE x SMALLINT
	LET l_inssql = base.SqlHandle.create()

-- Build the SQL
	LET l_sql = "insert into " || this.table_name || " ("
	FOR x = 1 TO this.fields.getLength()
		LET l_sql = l_sql.append(this.fields[x].colName)
		IF x != this.fields.getLength() THEN
			LET l_sql = l_sql.append(",")
		END IF
	END FOR
	LET l_sql = l_sql.append(") values (")
	FOR x = 1 TO this.fields.getLength()
		IF NOT this.fields[x].formOnly THEN
			IF x != this.fields.getLength() THEN
				LET l_sql = l_sql.append("?,")
			ELSE
				LET l_sql = l_sql.append("?")
			END IF
		END IF
	END FOR
	LET l_sql = l_sql.append(")")
	DISPLAY "SQL:", l_sql
	CALL l_inssql.prepare(l_sql)

-- Update the Parameters.
	FOR x = 1 TO this.fields.getLength()
		IF NOT this.fields[x].formOnly THEN
			LET l_val = this.fields[x].value
			LET l_valNumeric = this.fields[x].value.trim()
			IF this.fields[x].isNumeric THEN
				CALL l_inssql.setParameter(x, l_valNumeric)
			ELSE
				CALL l_inssql.setParameter(x, l_val)
			END IF
		END IF
	END FOR
-- Excute the SQL
	TRY
		CALL l_inssql.execute()
		MESSAGE "Record Inserted."
	CATCH
		ERROR "Insert Failed!"
	END TRY
	IF sqlca.sqlcode = 0 THEN
		CALL this.g2_SQLcursor()
		CALL this.g2_SQLgetRow(SQL_LAST, FALSE)
	ELSE
		CALL g2_core.g2_errPopup(SFMT(% "Failed to insert record!\n%1!", SQLERRMESSAGE))
		RETURN FALSE
	END IF
	RETURN TRUE
END FUNCTION
----------------------------------------------------------------------------------------------------
-- Delete a row for the current key field value
FUNCTION (this sql) g2_SQLdelete() RETURNS BOOLEAN
	DEFINE l_sql, l_val STRING
	LET l_val = this.handle.getResultValue(this.key_field_num)
	LET l_sql = "DELETE FROM " || this.table_name || " WHERE " || this.key_field || " = ?"
	IF g2_core.g2_winQuestion(
							% "Confirm",
							SFMT(% "Are you sure you want to delete this record?\n\n%1\nKey = %2", l_sql, l_val),
							% "No",
							% "Yes|No",
							"question")
					= % "Yes"
			THEN
		TRY
			PREPARE del_stmt FROM l_sql
			EXECUTE del_stmt USING l_val
		CATCH
		END TRY
		IF sqlca.sqlcode = 0 THEN
			CALL this.g2_SQLcursor()
			LET this.rows_count = this.rows_count - 1
			CALL this.g2_SQLgetRow(this.current_row, FALSE)
		ELSE
			CALL g2_core.g2_errPopup(SFMT(% "Failed to delete record!\n%1!", SQLERRMESSAGE))
			RETURN FALSE
		END IF
	ELSE
		MESSAGE % "Delete aborted."
		RETURN FALSE
	END IF
	RETURN TRUE
END FUNCTION
----------------------------------------------------------------------------------------------------
-- Produce a simple json record for the fields
FUNCTION (this sql) g2_SQLrec2Json()
	DEFINE x SMALLINT
	LET this.json_rec = util.JSONObject.create()
	FOR x = 1 TO this.fields.getLength()
		CALL this.json_rec.put(this.fields[x].colName, this.fields[x].value.trimRight())
	END FOR
--  DISPLAY this.json_rec.toString()
END FUNCTION
