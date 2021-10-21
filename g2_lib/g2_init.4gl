#+ Genero 4.00 and above
#+
#+ No warrantee of any kind, express or implied, is included with this software;
#+ use at your own risk, responsibility for damages (if any) to anyone resulting
#+ from the use of this software rests entirely with the user.
#+
#+ No includes required.

PACKAGE g2_lib

IMPORT os

IMPORT FGL g2_lib.g2_logging
IMPORT FGL g2_lib.g2_debug
IMPORT FGL g2_lib.g2_core
&include "g2_debug.inc"

PUBLIC DEFINE g2_log g2_logging.logger
PUBLIC DEFINE g2_err g2_logging.logger

FUNCTION g2_init(l_mdi CHAR(1), l_cfgname STRING) RETURNS ()
	DEFINE l_gbc, l_fe STRING
	CALL g2_log.init(NULL, NULL, "log", "TRUE")
	CALL g2_err.init(NULL, NULL, "err", "TRUE")
	CALL startlog(g2_err.fullLogPath)
	LET gl_dbgLev = fgl_getenv("FJS_GL_DBGLEV") -- 0=None, 1=General, 2=All
	GL_DBGMSG(0, SFMT("g2_core: Program: %1 pwd: %2", base.Application.getProgramName(), os.Path.pwd() ))
	GL_DBGMSG(1, SFMT("g2_core: debug level = %1", gl_dbgLev))
	GL_DBGMSG(1, SFMT("g2_core: FGLDIR=%1", fgl_getenv("FGLDIR")))
	GL_DBGMSG(1, SFMT("g2_core: FGLIMAGEPATH=%1", fgl_getenv("FGLIMAGEPATH")))
	GL_DBGMSG(1, SFMT("g2_core: FGLGBCDIR=%1", fgl_getenv("FGLGBCDIR")))
	GL_DBGMSG(1, SFMT("g2_core: FGLRESOURCEPATH=%1", fgl_getenv("FGLRESOURCEPATH")))

	WHENEVER ANY ERROR CALL g2_error

-- Try and figure out what the client is capable of GDC(Native/UR) / GBC
	LET l_gbc = ui.Interface.getUniversalClientName()
	LET l_fe = ui.Interface.getFrontEndName()
	GL_DBGMSG(1, SFMT("g2_core: getUniversalClientName = %1 FrontEnd = %2", l_gbc, l_fe))
	IF l_gbc.getLength() < 3 THEN
		LET l_gbc = "?"
	END IF
	IF l_fe = "GBC" THEN
		LET l_gbc = "GBC"
	END IF
	IF l_fe = "GDC" THEN
		LET m_isGDC = TRUE
	END IF
	IF l_gbc != "GBC" THEN
		LET m_isUniversal = FALSE
	END IF
	IF m_appInfo.progDesc IS NOT NULL THEN
		CALL ui.Interface.setText(m_appInfo.progDesc)
	END IF
	CALL g2_loadStyles(l_cfgname)
	CALL g2_loadToolBar(l_cfgname)
	CALL g2_loadActions(l_cfgname)
	CALL g2_mdisdi(l_mdi)
END FUNCTION