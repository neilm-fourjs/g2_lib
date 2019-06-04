
IMPORT FGL g2_lib
IMPORT FGL g2_db
IMPORT FGL g2_sql

IMPORT FGL lib_expect

MAIN
	DEFINE l_db g2_db.dbInfo
	DEFINE l_sql g2_sql.sql
	DEFINE l_key STRING =  "dummy"
	DEFINE l_table STRING = "stock"
	DEFINE l_keyField STRING = "stock_code"

  CALL g2_lib.g2_init("S", NULL)
	LET l_db.type = "pgs"
  CALL l_db.g2_connect("njm_demo310")

	CALL l_sql.g2_SQLinit(l_table,"*",l_keyField, SFMT("%1 = '%2'",l_keyField,l_key))
	CALL l_Sql.g2_SQLgetRow(1,TRUE)
	IF l_sql.rows_count != 0 THEN
		CALL lib_expect.failed( SFMT(" row count = ", l_sql.rows_count))
	ELSE
		CALL lib_expect.okay( "row count=0" )
	END IF

	CALL l_sql.g2_SQLinit(l_table,"*",l_keyField, SFMT("%1 = '%2'",l_keyField,"FR01"))
	CALL l_Sql.g2_SQLgetRow(1,TRUE)
	IF l_sql.rows_count != 1 THEN
		CALL lib_expect.failed( SFMT(" row count = ", l_sql.rows_count))
	ELSE
		CALL lib_expect.okay( "row count=1" )
	END IF


END MAIN