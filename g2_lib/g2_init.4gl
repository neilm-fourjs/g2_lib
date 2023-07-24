#+ Genero 4.00 and above
#+
#+ No warrantee of any kind, express or implied, is included with this software;
#+ use at your own risk, responsibility for damages (if any) to anyone resulting
#+ from the use of this software rests entirely with the user.
#+
#+ No includes required.

&ifdef gen320
IMPORT FGL g2_core
IMPORT FGL g2_logging
IMPORT FGL g2_debug
&else
PACKAGE g2_lib
IMPORT FGL g2_lib.g2_core
IMPORT FGL g2_lib.g2_logging
IMPORT FGL g2_lib.g2_debug
&endif

IMPORT os
&include "g2_debug.inc"

PUBLIC DEFINE g2_isParent BOOLEAN = FALSE
PUBLIC DEFINE g2_log g2_logging.logger
PUBLIC DEFINE g2_err g2_logging.logger
FUNCTION g2_init(l_mdi CHAR(1), l_cfgname STRING) RETURNS ()
	DEFINE l_gbc, l_fe STRING
	CALL g2_log.init(NULL, NULL, "log", "TRUE")
	CALL g2_err.init(NULL, NULL, "err", "TRUE")
	CALL startlog(g2_err.logFullPath)

	OPTIONS ON CLOSE APPLICATION CALL g2_appClose
	OPTIONS ON TERMINATE SIGNAL CALL g2_appTerm

	LET gl_dbgLev = fgl_getenv("FJS_GL_DBGLEV") -- 0=None, 1=General, 2=All
	GL_DBGMSG(0, SFMT("g2_init: Program: %1 pwd: %2 Sess: %3", base.Application.getProgramName(), os.Path.pwd(), fgl_getenv("FGL_VMPROXY_SESSION_ID") ))
	GL_DBGMSG(1, SFMT("g2_init: debug level = %1", gl_dbgLev))
	GL_DBGMSG(1, SFMT("g2_init: FGLDIR=%1", fgl_getenv("FGLDIR")))
	GL_DBGMSG(1, SFMT("g2_init: FGLSERVER=%1", fgl_getenv("FGLSERVER")))
	GL_DBGMSG(1, SFMT("g2_init: FGLIMAGEPATH=%1", fgl_getenv("FGLIMAGEPATH")))
	GL_DBGMSG(1, SFMT("g2_init: FGLGBCDIR=%1", fgl_getenv("FGLGBCDIR")))
	GL_DBGMSG(1, SFMT("g2_init: FGLRESOURCEPATH=%1", fgl_getenv("FGLRESOURCEPATH")))

	WHENEVER ANY ERROR CALL g2_error

	LET l_gbc =ui.Interface.getUniversalClientVersion()
	LET l_fe = ui.Interface.getFrontEndName()
	IF l_fe = "GDC" THEN
		LET g2_core.m_isGDC = TRUE
	ELSE
		LET l_gbc = ui.Interface.getFrontEndVersion()
	END IF
	IF l_gbc IS NULL THEN
		LET g2_core.m_isUniversal = FALSE
	END IF
	GL_DBGMSG(1, SFMT("g2_init: FE: %1 GBCVer: %2 Renderer: %3", l_fe, l_gbc, IIF(g2_core.m_isUniversal,"GBC","Native")))
	IF g2_core.m_appInfo.progDesc IS NOT NULL THEN
		CALL ui.Interface.setText(m_appInfo.progDesc)
	END IF
	IF g2_isParent THEN
		CALL fgl_setenv("G2_PARENTPID", fgl_getpid())
	ELSE
		CALL g2_log.logProgramRun(g2_isParent, NULL, NULL)
	END IF
	LET g2_core.m_log = g2_log
	CALL g2_core.g2_loadStyles(l_cfgname)
	CALL g2_core.g2_loadToolBar(l_cfgname)
	CALL g2_core.g2_loadActions(l_cfgname)
	CALL g2_core.g2_mdisdi(l_mdi)
END FUNCTION
--------------------------------------------------------------------------------
#+ On Application Close
FUNCTION g2_appClose() RETURNS ()
	CALL g2_core.g2_exitProgram(0, "Closed by FE.")
END FUNCTION
--------------------------------------------------------------------------------
#+ On Application Terminalate ( kill -15 )
FUNCTION g2_appTerm() RETURNS ()
	GL_DBGMSG(1, "g2_appTerm: attempt rollback")
	TRY
		ROLLBACK WORK
	CATCH
	END TRY
	CALL g2_core.g2_exitProgram(0, "Terminated by backend.")
END FUNCTION