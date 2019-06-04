IMPORT util
IMPORT FGL g2_ws
IMPORT FGL lib_expect
MAIN
	DEFINE l_res STRING
	DEFINE l_rec RECORD
		fld1 SMALLINT,
		fld2 STRING,
		fld3 DATE
	END RECORD = ( fld1: 1, fld2: "Test String" )
	DEFINE l_exp1 STRING = '{"status":1,"description":"Test","timestamp":"'
	DEFINE l_exp2 STRING = '{"status":1,"description":"JSON","data":{"fld1":1,"fld2":"Test String","fld3":'
	DEFINE l_j util.JSONObject

	LET l_rec.fld3 = TODAY
	LET l_res = g2_ws.service_reply( 1, "Test" )
	DISPLAY l_res
	IF l_res.subString(1,l_exp1.getLength()) != l_exp1 THEN
		CALL lib_expect.failed( SFMT("simple result wrong: %1",l_res) )
	ELSE
		CALL lib_expect.okay( "l_stk.description correct" )
	END IF

	LET l_j = util.JSONObject.fromFGL( l_rec )
	LET l_res = g2_ws.service_reply( 1, l_j.toString() )
	DISPLAY l_res

	IF l_res.subString(1,l_exp2.getLength()) != l_exp2 THEN
		CALL lib_expect.failed( SFMT("simple result wrong: %1",l_res) )
	ELSE
		CALL lib_expect.okay( "l_stk.description correct" )
	END IF

	CALL lib_expect.results()
END MAIN