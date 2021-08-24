--------------------------------------------------------------------------------
#+ Genero Genero Library Functions - by Neil J Martin ( neilm@4js.com )
#+ This library is intended as an example of useful library code for use with
#+ Genero 4.00 and above
#+  
#+ No warrantee of any kind, express or implied, is included with this software;
#+ use at your own risk, responsibility for damages (if any) to anyone resulting
#+ from the use of this software rests entirely with the user.
#+  
#+ No includes required.

PACKAGE g2_lib

IMPORT os
&define G2_DEBUG
&include "g2_debug.inc"

--------------------------------------------------------------------------------
#+ Display debug messages to console.
#+
#+ @param fil __FILE__ - File name
#+ @param lno __LINE__ - Line Number
#+ @param lev Level of debug
#+ @param msg Message
#+ @return Nothing.
FUNCTION g2_dbgMsg(l_fil STRING, l_lno INT, l_lev STRING, l_msg STRING)
	DEFINE l_lin CHAR(22)
	DEFINE x SMALLINT

	IF gl_dbgLev = 0 AND l_lev = 0 THEN
		DISPLAY base.Application.getProgramName(), ":", l_msg.trim()
	ELSE
		IF gl_dbgLev >= l_lev THEN
			LET l_fil = os.Path.baseName(l_fil)
			LET x = l_fil.getIndexOf(".", 1)
			LET l_fil = l_fil.subString(1, x - 1)
			LET l_lin = "...............:", l_lno USING "##,###"
			LET x = l_fil.getLength()
			IF x > 22 THEN
				LET x = 22
			END IF
			LET l_lin[1, x] = l_fil.trim()
			IF gl_dbgLev > 2 THEN
				DISPLAY CURRENT, " ", l_lin, ":", l_lev USING "<<&", ": ", l_msg.trim()
				CALL errorlog(CURRENT || " " || l_lin || ":" || (l_lev USING "<<&") || ": " || l_msg.trim())
			ELSE
				DISPLAY l_lin, ":", l_lev USING "<<&", ": ", l_msg.trim()
				CALL errorlog(l_lin || ":" || (l_lev USING "<<&") || ": " || l_msg.trim())
			END IF
		END IF
	END IF

END FUNCTION
