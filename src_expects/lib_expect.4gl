
DEFINE m_fails SMALLINT = 0
DEFINE m_success SMALLINT = 0

FUNCTION failed( l_reason STRING )
	DISPLAY SFMT("FAIL: %1", l_reason)
	LET m_fails = m_fails + 1
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION okay( l_reason STRING )
	DISPLAY SFMT("OAKY: %1", l_reason)
	LET m_success = m_success + 1
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION results()
	DISPLAY "Failed:  ", m_fails
	DISPLAY "Success: ", m_success
	IF m_fails > 0 THEN
		EXIT PROGRAM 1
	END IF
END FUNCTION