--------------------------------------------------------------------------------
#+ Dynamic Lookup - by Neil J Martin ( neilm@4js.com )
#+ This library is intended as an example of useful library code for use with
#+ Genero 3.20 >
#+
#+ No warrantee of any kind, express or implied, is included with this software;
#+ use at your own risk, responsibility for damages (if any) to anyone resulting
#+ from the use of this software rests entirely with the user.
--------------------------------------------------------------------------------
-- There a few different ways this library can be used:
-- 	DEFINE l_lookup g2_lookup2.lookup
--	CALL l_lookup.init( "countries", "*", "Code,Country", "1=1", "country_name")
--	DISPLAY "Selected value:",  l_lookup.g2_lookup2()
--
-- or
--
-- 	DEFINE l_lookup g2_lookup2.lookup
--	LET l_lookup.tableName = "colours"
--	LET l_lookup.columnList =  "*"
--	LET l_lookup.columnTitles = "Key,Name,Hex"
--	LET l_lookup.orderBy = "colour_name"
--	DISPLAY "Selected value:", l_lookup.g2_lookup2()
--
-- or
--
--	DEFINE l_lookup g2_lookup2.lookup
--	LET l_lookup.sql_count = "SELECT COUNT(*) FROM customer"
--	LET l_lookup.columnTitles = "Code,Name,Address"
--	LET l_lookup.sql_getData = "SELECT customer.customer_code, customer.customer_name, addresses.line1 FROM customer, addresses WHERE customer.del_addr = addresses.rec_key ORDER BY customer_name"
--	LET l_lookup.windowTitle = "Customers"
--	DISPLAY "Selected value:", l_lookup.g2_lookup2()
--

IMPORT FGL g2_lib
IMPORT FGL g2_aui
IMPORT FGL g2_db
&include "g2_debug.inc"

PUBLIC TYPE lookup RECORD
		tableName STRING, 			-- Table name
		columnList STRING, 			-- List of Columns, comma separated
		columnTitles STRING, 		-- Headings ( defaults to column names ), comma separated
		whereClause STRING, 		-- where clause ( defaults to 1=1 )
		orderBy STRING,					-- Order by ( optional )
		maxColWidth SMALLINT,		-- Largest column width ( default is coded as 40 )
		allowUpdate BOOLEAN,		-- Allow update of a row ( WIP )
		allowInsert BOOLEAN,		-- Allow insert of a row ( WIP )
		allowDelete BOOLEAN,		-- Allow Delete of a row ( WIP )
		sql_count STRING,				-- SQL for select count of rows
		sql_getData STRING,			-- Main select for fetching the data
		totalRecords INTEGER,		-- Total row count from select count
		sqlQueryHandle base.SqlHandle,	-- The SQL Handle for the main select SQL
		fields DYNAMIC ARRAY OF RECORD	-- The array of fields selected
			name STRING,
			type STRING
		END RECORD,
		columnTitlesArr DYNAMIC ARRAY OF STRING,	-- Column headiing array based on 'columnTitles'
		formName STRING,				-- Form name in AUI tree, used by client stored settings
		windowTitle STRING,			-- Window title, defaults to "Listing from 'tablename'"
		selectedKey STRING			-- the selected first column
	END RECORD

PUBLIC FUNCTION (this lookup) g2_lookup2() RETURNS STRING
	DEFINE l_key STRING
	DEFINE x, i SMALLINT
  DEFINE l_frm, l_grid, l_tabl, l_tabc, l_edit, l_curr om.DomNode
  DEFINE l_hbx, l_sp, l_titl om.DomNode
  DEFINE l_dlg ui.Dialog
  DEFINE l_event STRING

	IF NOT this.checkLookupParams() THEN RETURN NULL END IF

  GL_DBGMSG(2, SFMT("g2_lookup2: table = ",this.tableName))
  GL_DBGMSG(2, SFMT("g2_lookup2: column	= ",this.columnList))
  GL_DBGMSG(2, SFMT("g2_lookup2: titles	= ",this.columnTitles))
  GL_DBGMSG(2, SFMT("g2_lookup2: where = ",this.whereClause))
  GL_DBGMSG(2, SFMT("g2_lookup2: orderby = ",this.orderBy))
  GL_DBGMSG(2, SFMT("g2_lookup2: maxColWidth = ",this.maxColWidth))
  GL_DBGMSG(2, "g2_lookup2: Declaring Count Cursor...")

-- Check to make sure there are records.
	IF this.sql_count IS NULL THEN
    LET this.sql_count = "SELECT COUNT(*) FROM " || this.tableName || " WHERE " || this.whereClause
	END IF
  TRY
    PREPARE listcntpre FROM this.sql_count
  CATCH
    CALL g2_lib.g2_errPopup(SFMT(% "Failed to prepare:\n%1\n%2", this.sql_count, SQLERRMESSAGE))
    RETURN NULL --, NULL
  END TRY
  DECLARE listcntcur CURSOR FOR listcntpre
  OPEN listcntcur
  FETCH listcntcur INTO this.totalRecords
  CLOSE listcntcur
  IF this.totalRecords < 1 THEN
    CALL g2_lib.g2_errPopup(% "No Records Found")
    RETURN NULL
  END IF
  GL_DBGMSG(2, "g2_lookup2: Counted:" || this.totalRecords)

-- build the main sql if it's not already defined
	IF this.sql_getData IS NULL THEN
		LET this.sql_getData = "SELECT " || this.columnList || " FROM " || this.tableName, " WHERE " || this.whereClause
		IF this.orderBy IS NOT NULL THEN
			LET this.sql_getData = this.sql_getData CLIPPED, " ORDER BY " || this.orderBy
		END IF
	END IF

-- Perpare the main cursor
  LET this.sqlQueryHandle = base.SqlHandle.create()
  TRY
    CALL this.sqlQueryHandle.prepare(this.sql_getData)
    CALL this.sqlQueryHandle.openScrollCursor()
  CATCH
    CALL g2_lib.g2_errPopup(SFMT(% "Failed to prepare:\n%1\n%2", this.sql_getData, SQLERRMESSAGE))
    RETURN NULL
  END TRY
  CALL this.fields.clear()
  FOR x = 1 TO this.sqlQueryHandle.getResultCount()
    LET this.fields[x].name = this.sqlQueryHandle.getResultName(x)
    LET this.fields[x].type = this.sqlQueryHandle.getResultType(x)
    GL_DBGMSG(2, "g2_lookup2:" || x || " Name:" || this.fields[x].name || " Type:" || this.fields[x].type)
  END FOR
  GL_DBGMSG(2, "g2_lookup2: Cursor Okay.")

-- Open the window and define a table.
  GL_DBGMSG(2, "g2_lookup2: Opening Window.")
  OPEN WINDOW listv AT 1, 1 WITH 20 ROWS, 80 COLUMNS ATTRIBUTE(STYLE = "naked")
  CALL fgl_setTitle(this.windowTitle)
  LET l_frm = g2_aui.g2_genForm(this.formName) -- ensures form name is specific for this lookup

  LET l_grid = l_frm.createChild('Grid')
-- Create a centered window l_title.
  LET l_hbx = l_grid.createChild('HBox')
  CALL l_hbx.setAttribute("posY", "0")
  LET l_sp = l_hbx.createChild('SpacerItem')
  LET l_titl = l_hbx.createChild('Label')
  CALL l_titl.setAttribute("text", this.windowTitle)
  CALL l_titl.setAttribute("style", "tabtitl")
  LET l_sp = l_hbx.createChild('SpacerItem')

  GL_DBGMSG(2, "g2_lookup2: Generating Table...")
-- Create the table
  LET l_tabl = l_grid.createChild('Table')
  CALL l_tabl.setAttribute("tabName", "tablistv")
  CALL l_tabl.setAttribute("height", "20")
  CALL l_tabl.setAttribute("pageSize", "20")
  CALL l_tabl.setAttribute("posY", "1")

-- Create Columns & Headings for the table.
  FOR x = 1 TO this.fields.getLength()
    LET l_tabc = l_tabl.createChild('TableColumn')
    CALL l_tabc.setAttribute("colName", this.fields[x].name)
    LET l_edit = l_tabc.createChild('Edit')
		IF this.columnTitlesArr[x] IS NULL THEN LET this.columnTitlesArr[x] = this.fields[x].name END IF
    CALL l_tabc.setAttribute("text", this.columnTitlesArr[x])
    CALL l_edit.setAttribute("width", g2_db.g2_getColumnLength(this.fields[x].type, this.maxColWidth))
    IF this.columnTitlesArr[x].getCharAt(1) = "_" THEN -- if l_title starts with _ then it's a hidden column
      CALL l_tabc.setAttribute("hidden", "1")
    END IF
  END FOR

  GL_DBGMSG(2, "g2_lookup2: Adding buttons...")
-- Create centered buttons.
  LET l_hbx = l_grid.createChild('HBox')
  CALL l_hbx.setAttribute("posY", "3")
  LET l_curr = l_hbx.createChild('Label')
  CALL l_curr.setAttribute("text", "Row:")
  LET l_curr = l_hbx.createChild('Label')
  CALL l_curr.setAttribute("name", "cur_row")
  CALL l_curr.setAttribute("sizePolicy", "dynamic")
  LET l_sp = l_hbx.createChild('SpacerItem')
  LET l_titl = l_hbx.createChild('Button')
  CALL l_titl.setAttribute("name", "firstrow")
  CALL l_titl.setAttribute("image", "gobegin")
  LET l_titl = l_hbx.createChild('Button')
  CALL l_titl.setAttribute("name", "prevpage")
  CALL l_titl.setAttribute("image", "gorev")
  LET l_titl = l_hbx.createChild('Button')
  CALL l_titl.setAttribute("text", "Okay")
  CALL l_titl.setAttribute("name", "accept")
  CALL l_titl.setAttribute("width", "8")
	IF this.allowInsert THEN
		LET l_titl = l_hbx.createChild('Button')
		CALL l_titl.setAttribute("text", "New Record")
		CALL l_titl.setAttribute("name", "append")
		CALL l_titl.setAttribute("width", "8")
	END IF
  LET l_titl = l_hbx.createChild('Button')
  CALL l_titl.setAttribute("name", "cancel")
  CALL l_titl.setAttribute("text", "Cancel")
  CALL l_titl.setAttribute("width", "8")
  LET l_titl = l_hbx.createChild('Button')
  CALL l_titl.setAttribute("name", "nextpage")
  CALL l_titl.setAttribute("image", "goforw")
  LET l_titl = l_hbx.createChild('Button')
  CALL l_titl.setAttribute("name", "lastrow")
  CALL l_titl.setAttribute("image", "goend")
  LET l_sp = l_hbx.createChild('SpacerItem')
  LET l_titl = l_hbx.createChild('Label')
  CALL l_titl.setAttribute("text", this.totalRecords USING "###,###,##&" || " Rows")
  CALL l_titl.setAttribute("sizePolicy", "dynamic")

-- Setup the dialog
  LET int_flag = FALSE
  LET l_dlg = ui.Dialog.createDisplayArrayTo(this.fields, "tablistv")
  CALL l_dlg.addTrigger("ON ACTION close")
  CALL l_dlg.addTrigger("ON ACTION accept")
  CALL l_dlg.addTrigger("ON ACTION cancel")
	IF this.allowInsert THEN CALL l_dlg.addTrigger("ON ACTION append") END IF
	IF this.allowUpdate THEN CALL l_dlg.addTrigger("ON ACTION update") END IF
	IF this.allowDelete THEN CALL l_dlg.addTrigger("ON ACTION delete") END IF

-- Fetch the data
  CALL this.sqlQueryHandle.fetchFirst()
  LET x = 0
  WHILE SQLCA.sqlcode = 0
    LET x = x + 1
    CALL l_dlg.setCurrentRow("tablistv", x) -- must set the current row before setting values
    FOR i = 1 TO this.sqlQueryHandle.getResultCount()
      CALL l_dlg.setFieldValue( this.sqlQueryHandle.getResultName(i),  this.sqlQueryHandle.getResultValue(i))
    END FOR
    CALL this.sqlQueryHandle.fetch()
  END WHILE
  CALL this.sqlQueryHandle.close()
  CALL l_dlg.setCurrentRow("tablistv", 1) -- TODO: should be done by the runtime
-- Loop for events.
  WHILE TRUE
    LET l_event = l_dlg.nextEvent()
    CASE l_event
      WHEN "BEFORE DISPLAY"
        IF this.totalRecords = 1 THEN
          EXIT WHILE
        END IF -- if only 1 row just select it!
      WHEN "ON ACTION close"
        LET int_flag = TRUE
        EXIT WHILE
      WHEN "ON ACTION cancel"
        LET int_flag = TRUE
        EXIT WHILE
      WHEN "ON ACTION accept"
        EXIT WHILE
      WHEN "ON SORT"
        --MESSAGE "Use 'reset sort order' to reset to default."
        EXIT WHILE
      WHEN "ON ACTION tablistv.accept" -- doubleclick
        EXIT WHILE
      WHEN "BEFORE ROW"
        LET x = l_dlg.arrayToVisualIndex("tablistv", arr_curr())
        CALL l_curr.setAttribute(
            "text", SFMT("%1 (%2)", x USING "<<<,##&", arr_curr() USING "<<<,##&"))
      OTHERWISE
        GL_DBGMSG(2, "g2_lookup2: Unhandled Event:" || l_event)
    END CASE
  END WHILE
  LET this.selectedKey = l_dlg.getFieldValue(this.fields[1].name) -- get the selected row first field.
  LET l_dlg = NULL -- FIXME: CALL l_dlg.terminate()

  CLOSE WINDOW listv
  IF int_flag THEN
    GL_DBGMSG(2, "g2_lookup2: Window Closed, Cancelled.")
    RETURN NULL
  ELSE
    GL_DBGMSG(2, SFMT("g2_lookup2: Window Closed, returning row:%1 %2", arr_curr(),this.selectedKey.trim() ))
    RETURN this.selectedKey.trim()
  END IF

	RETURN l_key
END FUNCTION
----------------------------------------------------------------------------------------------------
#+ Initialize helper function:
#+
#+ @param tabnam db table name
#+ @param cols	columns names ( comma seperated )
#+ @param colts columns l_titles ( comma seperated )
#+					can be NULL to use column names
#+					can be _ to have a hidden column - ie 1st col if it's a key
#+ @param wher	The WHERE clause, 1=1 means all, or use result of construct
#+ @param ordby The ORDER BY clause
FUNCTION (this lookup) init( tabnam STRING, cols STRING, colts STRING, wher STRING, ordby STRING)
	LET this.sql_count = NULL
	LET this.sql_getData = NULL
	LET this.tableName = tabnam
	LET this.columnList = cols
	LET this.columnTitles = colts
	LET this.whereClause = wher
	LET this.orderBy = ordby
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION (this lookup) checkLookupParams() RETURNS BOOLEAN
	DEFINE l_err STRING
  DEFINE l_tok base.StringTokenizer

	IF this.maxColWidth = 0 THEN LET this.maxColWidth = 40 END IF
	IF this.tableName IS NULL AND this.sql_getData IS NULL THEN LET l_err = l_err.append("tableName ") END IF
	IF this.columnlist IS NULL AND this.sql_getData IS NULL THEN LET l_err = l_err.append("columnList ") END IF
	IF this.columnTitles IS NULL AND this.columnlist != "*" THEN LET this.columnTitles = this.columnlist END IF
	IF this.whereClause IS NULL THEN LET this.whereClause = "1=1" END IF
	IF this.formName IS NULL THEN LET this.formName = "gl_"||this.tableName END IF
	IF this.windowTitle IS NULL THEN LET this.windowTitle = SFMT(%"Listing from %1",this.tableName) END IF

	LET l_tok = base.StringTokenizer.create(this.columnTitles, ",")
	CALL this.columnTitlesArr.clear() -- clear the defaults if l_title supplied.
	WHILE l_tok.hasMoreTokens()
		LET this.columnTitlesArr[this.columnTitlesArr.getLength() + 1] = l_tok.nextToken()
	END WHILE

	IF l_err IS NOT NULL THEN
		CALL g2_lib.g2_winMessage("Error",SFMT(%"Lookup called by initiated correctly!\nThe following are not set:%1", l_err),"exclamation")
		RETURN FALSE
	END IF
	RETURN TRUE
END FUNCTION