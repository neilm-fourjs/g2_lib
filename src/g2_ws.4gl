IMPORT com
IMPORT util
IMPORT FGL g2_logging
PUBLIC DEFINE m_server STRING
DEFINE ws_response RECORD
	status INTEGER,
	description STRING,
	server STRING,
	timestamp STRING
END RECORD
----------------------------------------------------------------------------------------------------
-- Start the service loop
PUBLIC FUNCTION start(L_module STRING, l_basePath STRING, g2_log g2_logging.logger INOUT)
  DEFINE l_ret SMALLINT
  DEFINE l_msg STRING

  CALL com.WebServiceEngine.RegisterRestService(l_module, l_basePath)

  LET l_msg = SFMT("Service '%1' started %2.", l_module, CURRENT)
  CALL com.WebServiceEngine.Start()
  WHILE TRUE
    CALL g2_log.logIt(SFMT("Service: %1", l_msg))
    LET l_ret = com.WebServiceEngine.ProcessServices(-1)
    CASE l_ret
      WHEN 0
        LET l_msg = "Request processed."
      WHEN -1
        LET l_msg = "Timeout reached."
      WHEN -2
        LET l_msg = "Disconnected from application server."
        EXIT WHILE # The Application server has closed the connection
      WHEN -3
        LET l_msg = "Client Connection lost."
      WHEN -4
        LET l_msg = "Server interrupted with Ctrl-C."
      WHEN -9
        LET l_msg = "Unsupported operation."
      WHEN -10
        LET l_msg = "Internal server error."
      WHEN -23
        LET l_msg = "Deserialization error."
      WHEN -35
        LET l_msg = "No such REST operation found."
      WHEN -36
        LET l_msg = "Missing REST parameter."
      OTHERWISE
        LET l_msg = SFMT("Unexpected server error %1.", l_ret)
        EXIT WHILE
    END CASE
    IF int_flag != 0 THEN
      LET l_msg = "Service interrupted."
      LET int_flag = 0
      EXIT WHILE
    END IF
  END WHILE
  CALL g2_log.logIt(SFMT("Server stopped: %1", l_msg))
END FUNCTION
----------------------------------------------------------------------------------------------------
-- Format the string reply from the service function
PUBLIC FUNCTION service_reply(l_stat INT, l_reply STRING) RETURNS STRING
	LET ws_response.description = l_reply
	LET ws_response.server = m_server
	LET ws_response.timestamp = CURRENT
	LET ws_response.status = l_stat
  RETURN util.json.stringify( ws_response )
END FUNCTION