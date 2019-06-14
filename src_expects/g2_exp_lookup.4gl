
IMPORT FGL g2_db
IMPORT FGL g2_lookup

MAIN
	DEFINE l_db g2_db.dbInfo = ( type: "pgs" )

  CALL l_db.g2_connect("njm_demo310")

	MENU
		COMMAND "Colours" CALL colours()
		COMMAND "Countries" CALL countries()
		COMMAND "Quit" EXIT MENU
	END MENU

END MAIN
----------------------------------------------------------------------------------------------------
FUNCTION colours()
	DEFINE l_colr STRING
	LET l_colr = 
	  g2_lookup.g2_lookup( "colours", "colour_key,colour_name,colour_hex", "Key,Name,HEX", "1=1", "colour_name")
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION countries()
	DEFINE l_cntry STRING
	LET l_cntry = 
	  g2_lookup.g2_lookup( "countries", "country_Code,country_name", "Code,Country", "1=1", "country_name")
END FUNCTION