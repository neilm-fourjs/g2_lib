IMPORT util

&ifdef gen320
IMPORT FGL g2_init
IMPORT FGL g2_ws
&else
IMPORT FGL g2_lib.*
&endif

IMPORT FGL lib_expect

TYPE t_rec  RECORD
		fld1 SMALLINT,
		fld2 STRING,
		fld3 DATE
	END RECORD
MAIN
	DEFINE l_res STRING
	DEFINE l_rec t_rec = ( fld1: 1, fld2: "Test String" )
	DEFINE l_rec2 t_rec
	DEFINE l_exp1 STRING = '{"status":1,"timestamp":"'
	DEFINE l_j_response g2_ws.t_response

	DEFINE l_j util.JSONObject

	LET l_rec.fld3 = TODAY
	LET l_res = g2_ws.service_reply( 1, "Test" )
	DISPLAY l_res
	IF l_res.subString(1,l_exp1.getLength()) != l_exp1 THEN
		CALL lib_expect.failed( SFMT("simple result wrong: %1",l_res) )
	ELSE
		CALL lib_expect.okay( "simple result correct" )
	END IF

	IF g2_ws.ws_response.description != "Test" THEN
		CALL lib_expect.failed( SFMT("description wrong: %1",l_res) )
	ELSE
		CALL lib_expect.okay( "description result correct" )
	END IF

	LET l_j = util.JSONObject.fromFGL( l_rec )
	LET l_res = g2_ws.service_reply( 1, l_j.toString() )
	DISPLAY l_res

	IF l_res.subString(1,l_exp1.getLength()) != l_exp1 THEN
		CALL lib_expect.failed( SFMT("JSON result wrong: %1",l_res) )
	ELSE
		CALL lib_expect.okay( "JSON result correct" )
	END IF

	IF g2_ws.ws_response.description != "JSON" THEN
		CALL lib_expect.failed( SFMT("description wrong: %1",l_res) )
	ELSE
		CALL lib_expect.okay( "description result correct" )
	END IF

	TRY
		CALL util.JSON.parse(l_res, l_j_response)
		CALL lib_expect.okay( "JSON response to record" )
	CATCH
		CALL lib_expect.failed( "JSON response to record" )
	END TRY

	TRY
		CALL l_j_response.data.toFGL(l_rec2)
		CALL lib_expect.okay( "JSON response data to record" )
	CATCH
		CALL lib_expect.failed( "JSON response data to record" )
	END TRY

	CALL lib_expect.test("fld2", "Test String", l_rec2.fld2)
	CALL lib_expect.test("fld3", TODAY, l_rec2.fld3)

	CALL lib_expect.results()
END MAIN