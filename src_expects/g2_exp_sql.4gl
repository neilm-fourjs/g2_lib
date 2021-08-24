
IMPORT util
IMPORT FGL g2_core
IMPORT FGL g2_db
IMPORT FGL g2_sql

IMPORT FGL lib_expect
SCHEMA njm_demo310

MAIN
	DEFINE l_db g2_db.dbInfo = ( type: "pgs" )
	DEFINE l_sql g2_sql.sql
	DEFINE l_table STRING = "stock"
	DEFINE l_keyField STRING = "stock_code"
	DEFINE l_stk RECORD LIKE stock.*

  CALL g2_core.g2_init("S", NULL)
  CALL l_db.g2_connect("njm_demo310")

-- attempt to get an invalid row
	CALL l_sql.g2_SQLinit(l_table,"*",l_keyField, SFMT("%1 = '%2'",l_keyField,"dummy"))
	CALL l_Sql.g2_SQLgetRow(1,TRUE)
	IF l_sql.rows_count != 0 THEN
		CALL lib_expect.failed( SFMT(" row count = ", l_sql.rows_count))
	ELSE
		CALL lib_expect.okay( "row count=0" )
	END IF

-- Fetch a row
	CALL l_sql.g2_SQLinit(l_table,"*",l_keyField, SFMT("%1 = '%2'",l_keyField,"FR01"))
	CALL l_Sql.g2_SQLgetRow(1,TRUE)
	IF l_sql.rows_count != 1 THEN
		CALL lib_expect.failed( SFMT(" row count = ", l_sql.rows_count))
	ELSE
		CALL lib_expect.okay( "row count=1" )
	END IF

-- process the row
	CALL l_sql.g2_SQLrec2Json() -- get selected data into a JSON object
	DISPLAY "JSON:", l_sql.json_rec.toString()
	TRY -- turn JSONobject into 4gl record
		CALL l_sql.json_rec.toFGL( l_stk )
	CATCH
		CALL lib_expect.failed( "JSON rec to l_stk record" )
	END TRY

-- Test that 4gl record is correct
	IF l_stk.stock_code != "FR01" THEN
		CALL lib_expect.failed( SFMT("l_stk.stock_code wrong '%1'",l_stk.stock_code) )
	ELSE
		CALL lib_expect.okay( "l_stk.stock_code correct" )
	END IF
	IF l_stk.description != "An Apple" THEN
		CALL lib_expect.failed( SFMT("l_stk.description wrong '%1'",l_stk.description) )
	ELSE
		CALL lib_expect.okay( "l_stk.description correct" )
	END IF

	CALL lib_expect.results()

END MAIN