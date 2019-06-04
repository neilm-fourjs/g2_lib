
FUNCTION failed( l_reason STRING )
	DISPLAY SFMT("FAIL: %1", l_reason)
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION okay( l_reason STRING )
	DISPLAY SFMT("OAKY: %1", l_reason)
END FUNCTION