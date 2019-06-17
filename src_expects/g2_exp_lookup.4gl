
IMPORT FGL g2_lib
IMPORT FGL g2_db
IMPORT FGL g2_lookup
IMPORT FGL g2_lookup2

MAIN
	DEFINE l_db g2_db.dbInfo = ( type: "pgs" )

	CALL g2_lib.g2_init("S",NULL)

  CALL l_db.g2_connect("njm_demo310")

	MENU
		COMMAND "Lookup 1 - Colours" CALL colours1()
		COMMAND "Lookup 1 - Countries" CALL countries1()
		COMMAND "Lookup 2 - Colours" CALL colours2()
		COMMAND "Lookup 2 - Countries" CALL countries2()
		COMMAND "Quit" EXIT MENU
		ON ACTION CLOSE EXIT MENU
	END MENU

END MAIN
----------------------------------------------------------------------------------------------------
FUNCTION colours1()
	DEFINE l_colr STRING
	LET l_colr = 
	  g2_lookup.g2_lookup( "colours", "colour_key,colour_name,colour_hex", "Key,Name,HEX", "1=1", "colour_name")
	DISPLAY "Colour:", l_colr
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION countries1()
	DEFINE l_cntry STRING
	LET l_cntry = 
	  g2_lookup.g2_lookup( "countries", "country_Code,country_name", "Code,Country", "1=1", "country_name")
	DISPLAY "Country:", l_cntry
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION colours2()
	DEFINE l_lookup g2_lookup2.lookup
	DEFINE l_colr STRING
	LET l_lookup.tableName = "colours"
	LET l_lookup.columnList =  "colour_key,colour_name,colour_hex"
	LET l_lookup.columnTitles = "Key,Name,HEX"
	LET l_lookup.orderBy = "colour_name"
	LET l_colr = l_lookup.g2_lookup2()
	DISPLAY "Colour:", l_colr
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION countries2()
	DEFINE l_lookup g2_lookup2.lookup
	DEFINE l_cntry STRING
	CALL l_lookup.init( "countries", "country_Code,country_name", "Code,Country", "1=1", "country_name")
	LET l_cntry =  l_lookup.g2_lookup2()
	DISPLAY "Country:", l_cntry
END FUNCTION