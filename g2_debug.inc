
&define GL_DBGMSG( lev, msg ) \
 CALL g2_debug.g2_dbgMsg( __FILE__, __LINE__, lev, NVL(msg,"NULL!"))

GLOBALS
  DEFINE gl_dbgLev SMALLINT
END GLOBALS
