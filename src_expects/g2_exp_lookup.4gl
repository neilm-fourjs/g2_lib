
IMPORT FGL g2_lib
IMPORT FGL g2_db
IMPORT FGL g2_lookup
IMPORT FGL g2_lookup2
IMPORT FGL lib_expect

MAIN
	DEFINE l_db g2_db.dbInfo = ( type: "pgs" )

	CALL g2_lib.g2_init("S",NULL)

  CALL l_db.g2_connect("njm_demo310")
	
	OPEN FORM f FROM "form"
	DISPLAY FORM f

	MENU
		COMMAND "Lookup 1 - Colours" CALL colours1()
		COMMAND "Lookup 1 - Countries" CALL countries1()
		COMMAND "Lookup 2 - Colours" CALL colours2()
		COMMAND "Lookup 2 - Countries" CALL countries2()
		COMMAND "Lookup 2 - Customers" CALL customers2()
		COMMAND "Quit" EXIT MENU
		ON ACTION CLOSE EXIT MENU
	END MENU

END MAIN
----------------------------------------------------------------------------------------------------
FUNCTION colours1()
	DEFINE l_colr STRING
	LET l_colr = 
	  g2_lookup.g2_lookup( "colours", "colour_key,colour_name,colour_hex", "Key,Name,HEX", "1=1", "colour_name")
	CALL lib_expect.showResult( "Colour:"||NVL(l_colr,NULL))
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION countries1()
	DEFINE l_cntry STRING
	LET l_cntry = 
	  g2_lookup.g2_lookup( "countries", "country_Code,country_name", "Code,Country", "1=1", "country_name")
	CALL lib_expect.showResult( "Country:"||NVL(l_cntry,NULL))
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION colours2()
	DEFINE l_lookup g2_lookup2.lookup
	DEFINE l_colr STRING
	LET l_lookup.tableName = "colours"
	LET l_lookup.columnList =  "*"
	LET l_lookup.columnTitles = "Key,Name,HEX"
	LET l_lookup.orderBy = "colour_name"
	LET l_lookup.allowInsert = TRUE
	LET l_lookup.allowUpdate = TRUE
	LET l_lookup.allowDelete = TRUE
	LET l_colr = l_lookup.g2_lookup2()
	CALL lib_expect.showResult( "Colour:"||NVL(l_colr,NULL))
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION countries2()
	DEFINE l_lookup g2_lookup2.lookup
	DEFINE l_cntry STRING
	CALL l_lookup.init( "countries", "*", "Code,Country", "1=1", "country_name")
	LET l_lookup.allowInsert = TRUE
	LET l_lookup.allowUpdate = TRUE
	LET l_lookup.allowDelete = TRUE
	LET l_cntry =  l_lookup.g2_lookup2()
	CALL lib_expect.showResult( "Country:"||NVL(l_cntry,NULL))
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION customers2()
	DEFINE l_lookup g2_lookup2.lookup
	DEFINE l_cust STRING
	LET l_lookup.sql_count = "SELECT COUNT(*) FROM customer"
	LET l_lookup.columnTitles = "Code,Name,Address"
	LET l_lookup.sql_getData = "SELECT customer.customer_code, customer.customer_name, addresses.line1 FROM customer, addresses WHERE customer.del_addr = addresses.rec_key ORDER BY customer_name"
	LET l_lookup.windowTitle = "Customers"
	LET l_cust = l_lookup.g2_lookup2()
	CALL lib_expect.showResult( "Customer:"||NVL(l_cust,NULL)||" Selected from "||l_lookup.totalRecords)
END FUNCTION