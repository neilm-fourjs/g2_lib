--------------------------------------------------------------------------------
#+ Genero Genero Library Functions - by Neil J Martin ( neilm@4js.com )
#+ This library is intended as an example of useful library code for use with
#+ Genero 4.00 and above
#+
#+ No warrantee of any kind, express or implied, is included with this software;
#+ use at your own risk, responsibility for damages (if any) to anyone resulting
#+ from the use of this software rests entirely with the user.
#+

&ifdef gen320
IMPORT FGL g2_appInfo
IMPORT FGL g2_debug
IMPORT FGL g2_logging
&else
PACKAGE g2_lib
IMPORT FGL g2_lib.g2_appInfo
IMPORT FGL g2_lib.g2_debug
IMPORT FGL g2_lib.g2_logging
&endif

IMPORT os

&include "g2_debug.inc"

PUBLIC DEFINE m_mdi CHAR(1)
PUBLIC DEFINE m_isUniversal BOOLEAN = TRUE
PUBLIC DEFINE m_isGDC BOOLEAN = FALSE
PUBLIC DEFINE m_isWS BOOLEAN = FALSE
PUBLIC DEFINE m_appInfo appInfo
PUBLIC DEFINE m_log g2_logging.logger

--------------------------------------------------------------------------------
#+ Set MDI or not
#+ C = child
#+ M = MDI Container
#+ S = Not MDI
#+ @param l_mdi_sdi S/C/M = default is 'S'
FUNCTION g2_mdisdi(l_mdi_sdi CHAR(1)) RETURNS ()
	DEFINE l_container, l_desc STRING
	IF l_mdi_sdi IS NULL OR l_mdi_sdi = " " THEN
		LET l_mdi_sdi = "S"
	END IF
	LET m_mdi = l_mdi_sdi

	LET l_container = fgl_getenv("FJS_MDICONT")
	IF l_container IS NULL OR l_container = " " THEN
		LET l_container = "container"
	END IF
	LET l_desc = fgl_getenv("FJS_MDITITLE")
	IF l_desc IS NULL OR l_desc = " " THEN
		LET l_desc = "MDI Container:" || l_container
	END IF
	CASE m_mdi
		WHEN "C" -- Child
			GL_DBGMSG(2, "g2_mdisdi: Child")
			CALL ui.Interface.setType("child")
			CALL ui.Interface.setContainer(l_container)
		WHEN "M" -- MDI Container
			GL_DBGMSG(2, "g2_mdisdi: Container:" || l_container)
			CALL ui.Interface.setText(l_desc)
			CALL ui.Interface.setType("container")
			CALL ui.Interface.setName(l_container)
		OTHERWISE
			GL_DBGMSG(2, "g2_mdisdi: Not MDI")
	END CASE
END FUNCTION
--------------------------------------------------------------------------------
#+ Load the style file depending on the client
FUNCTION g2_loadStyles(l_stName STRING) RETURNS()
	DEFINE l_fe, l_name STRING
	DEFINE l_ok BOOLEAN = TRUE
	IF l_stName IS NULL THEN LET l_stName = "default" END IF
	LET l_fe = "GBC"
	IF m_isGDC AND NOT m_isUniversal THEN LET l_fe = "GDC" END IF
	LET l_name = l_stName || "_" || l_fe
	TRY
		CALL ui.Interface.loadStyles(l_name)
	CATCH
		LET l_name = l_stName
		LET l_ok = FALSE
	END TRY
	IF NOT l_ok THEN
		TRY
			CALL ui.Interface.loadStyles(l_name)
			LET l_ok = TRUE
		CATCH
			LET l_name = l_name.append(" FAILED using 'default'")
		END TRY
	END IF
	IF NOT l_ok THEN
		TRY
			CALL ui.Interface.loadStyles("default")
		CATCH
			LET l_name = l_name.append(" & default FAILED!")
		END TRY
	END IF
	GL_DBGMSG(0, SFMT("g2_loadStyles: file=%1 ", l_name))
END FUNCTION
--------------------------------------------------------------------------------
#+ Load the Action Defaults file depending on the client
FUNCTION g2_loadActions(l_adName STRING) RETURNS()
	DEFINE l_ok BOOLEAN = TRUE
	IF l_adName IS NULL THEN LET l_adName = "default" END IF
	TRY
		CALL ui.Interface.loadActionDefaults(l_adName)
	CATCH
		LET l_adName = "default"
		LET l_ok = FALSE
	END TRY
	IF NOT l_ok THEN
		TRY
			CALL ui.Interface.loadActionDefaults(l_adName)
		CATCH
			LET l_adName = l_adName.append(" FAILED!")
		END TRY
	END IF
	GL_DBGMSG(0, SFMT("g2_loadActions: file=%1 ", l_adName))
END FUNCTION
--------------------------------------------------------------------------------
#+ Load the ToolBar file depending on the client
FUNCTION g2_loadToolBar(l_tbName STRING) RETURNS()
	DEFINE l_f ui.Form
	IF l_tbName IS NULL THEN LET l_tbName = "default" END IF
	TRY
		LET l_f = ui.Window.getCurrent().getForm()
	CATCH
		GL_DBGMSG(1, "g2_loadToolBar: Failed to get form object!")
	END TRY
	IF l_f IS NOT NULL THEN
		TRY
			CALL l_f.loadToolBar(l_tbName)
		CATCH
			LET l_tbName = l_tbName.append(" FAILED!")
		END TRY
	ELSE
		TRY
			CALL ui.Interface.loadToolBar(l_tbName)
		CATCH
			LET l_tbName = l_tbName.append(" FAILED!")
		END TRY
	END IF
	GL_DBGMSG(0, SFMT("g2_loadToolBar: file=%1 ", l_tbName))
END FUNCTION
--------------------------------------------------------------------------------
#+ Load the TopMenu file depending on the client
FUNCTION g2_loadTopMenu(l_tmName STRING) RETURNS()
	DEFINE l_w ui.Window
	DEFINE l_f ui.Form
	LET l_w = ui.Window.getCurrent()
	IF l_w IS NOT NULL THEN
		LET l_f = l_w.getForm()
	END IF
	IF l_tmName IS NULL THEN
		LET l_tmName = "default"
	END IF
	TRY
		IF l_f IS NOT NULL THEN
			CALL l_f.loadTopMenu(l_tmName)
		ELSE
			CALL ui.Interface.loadTopMenu(l_tmName)
		END IF
	CATCH
		LET l_tmName = l_tmName.append(" FAILED!")
	END TRY
	GL_DBGMSG(0, SFMT("g2_loadTopMenu: file=%1 ", l_tmName))
END FUNCTION
--------------------------------------------------------------------------------
#+ Generic Windows message Dialog.	NOTE: This handles messages when there is
#+ no window!
#+
#+ @param l_title		 = Window Title
#+ @param l_message	 = Message text
#+ @param l_icon			= Icon name, "exclamation"
#+ @return none
FUNCTION g2_winMessage(l_title STRING, l_message STRING, l_icon STRING) RETURNS()
	DEFINE l_win ui.Window
	IF l_title IS NULL THEN
		LET l_title = "No Title!"
	END IF
	IF l_message IS NULL THEN
		LET l_message = "Message was NULL!!\n" || base.Application.getStackTrace()
	END IF

	IF m_isWS THEN
		DISPLAY l_message
		RETURN
	END IF

	LET l_win = ui.Window.getCurrent()
	IF l_win IS NULL THEN -- Needs a current window or dialog doesn't work!!
		OPEN WINDOW dummy AT 1, 1 WITH 1 ROWS, 1 COLUMNS
		-- clear default window title to avoid 'dummy' showing in gbc.
		CALL ui.Window.getCurrent().setText(" ")
	END IF
	IF l_icon = "exclamation" THEN
		ERROR ""
	END IF -- Beep

	GL_DBGMSG(2, "g2_winMessage: " || NVL(l_message, "gl_winMessage passed NULL!"))
	MENU l_title ATTRIBUTES(STYLE = "dialog", COMMENT = l_message, IMAGE = l_icon)
		COMMAND "Okay"
			EXIT MENU
	END MENU

	IF l_win IS NULL THEN
		CLOSE WINDOW dummy
	END IF

END FUNCTION
--------------------------------------------------------------------------------
#+ Generic Windows Question Dialog
#+
#+ @param l_title Window Title
#+ @param l_message Message text
#+ @param l_ans	 Default Answer
#+ @param l_items List of Answers ie "Yes|No|Cancel"
#+ @param l_icon	Icon name, "exclamation"
#+ @return string: Entered value.
FUNCTION g2_winQuestion(
		l_title STRING, l_message STRING, l_ans STRING, l_items STRING, l_icon STRING)
		RETURNS STRING
	DEFINE l_result STRING
	DEFINE l_toks base.StringTokenizer
	DEFINE l_dum BOOLEAN
	DEFINE l_opt DYNAMIC ARRAY OF STRING
	DEFINE x SMALLINT

	LET l_icon = l_icon.trim()
	LET l_title = l_title.trim()
	LET l_message = l_message.trim()
	LET l_icon = l_icon.trim()
	IF l_icon = "info" THEN
		LET l_icon = "information"
	END IF

	LET l_toks = base.StringTokenizer.create(l_items, "|")
	IF NOT l_toks.hasMoreTokens() THEN
		RETURN NULL
	END IF
	WHILE l_toks.hasMoreTokens()
		LET l_opt[l_opt.getLength() + 1] = l_toks.nextToken()
	END WHILE
	FOR x = l_opt.getLength() + 1 TO 10
		LET l_opt[x] = "__" || x
	END FOR

	-- Handle the case when there is no current window
	LET l_dum = FALSE
	IF ui.Window.getCurrent() IS NULL THEN
		OPEN WINDOW dummy AT 1, 1 WITH 1 ROWS, 2 COLUMNS ATTRIBUTE(STYLE = "naked")
		CALL ui.Window.getCurrent().setText(l_title)
		LET l_dum = TRUE
	END IF

	MENU l_title ATTRIBUTE(STYLE = "dialog", COMMENT = l_message, IMAGE = l_icon)
		BEFORE MENU
			FOR x = 1 TO 10
				CALL DIALOG.setActionHidden(
						l_opt[x].toLowerCase(), IIF(l_opt[x].subString(1, 2) = "__", TRUE, FALSE))
				IF l_opt[x] IS NOT NULL THEN
					IF l_ans.equalsIgnoreCase(l_opt[x]) THEN
						NEXT OPTION l_opt[x]
					END IF
				END IF
			END FOR
		COMMAND l_opt[1]
			LET l_result = l_opt[1]
		COMMAND l_opt[2]
			LET l_result = l_opt[2]
		COMMAND l_opt[3]
			LET l_result = l_opt[3]
		COMMAND l_opt[4]
			LET l_result = l_opt[4]
		COMMAND l_opt[5]
			LET l_result = l_opt[5]
		COMMAND l_opt[6]
			LET l_result = l_opt[6]
		COMMAND l_opt[7]
			LET l_result = l_opt[7]
		COMMAND l_opt[8]
			LET l_result = l_opt[8]
		COMMAND l_opt[9]
			LET l_result = l_opt[9]
		COMMAND l_opt[10]
			LET l_result = l_opt[10]
	END MENU
	IF l_dum THEN
		CLOSE WINDOW dummy
	END IF
	RETURN l_result
END FUNCTION
--------------------------------------------------------------------------------
#+ Simple message with ui refresh
#+
#+ @return Nothing
FUNCTION g2_message(l_msg STRING) RETURNS ()
	MESSAGE NVL(l_msg, "NULL")
	CALL ui.Interface.refresh()
END FUNCTION
--------------------------------------------------------------------------------
#+ Simple error message
#+
#+ @return Nothing.
FUNCTION g2_errPopup(l_msg STRING) RETURNS ()
	CALL g2_winMessage(% "Error!", l_msg, "exclamation")
END FUNCTION
--------------------------------------------------------------------------------
#+ Simple error message
#+
#+ @return Nothing
FUNCTION g2_warnPopup(l_msg STRING) RETURNS ()
	CALL g2_winMessage(% "Warning!", l_msg, "exclamation")
END FUNCTION
--------------------------------------------------------------------------------
#+ Display an error message in a window, console & logfile.
#+
#+ @param l_fil __FILE__ - File name
#+ @param l_lno __LINE__ - Line Number
#+ @param l_err Error Message.
#+ @return Nothing.
FUNCTION g2_errMsg(l_fil STRING, l_lno INT, l_err STRING) RETURNS ()
	CALL g2_errPopup(l_err)
	ERROR "* ", l_err.trim(), " *"
	IF l_fil IS NOT NULL THEN
		DISPLAY l_fil.trim(), ":", l_lno, ": ", l_err.trim()
		CALL errorlog(l_fil.trim() || ":" || l_lno || ": " || l_err)
	END IF
END FUNCTION
--------------------------------------------------------------------------------
#+ Check the client for it's vesion
#+
FUNCTION g2_chkClientVer(l_cli STRING, l_ver STRING, l_feature STRING) RETURNS BOOLEAN
	DEFINE l_fe_major DECIMAL(4, 2)
	DEFINE l_fe_minor SMALLINT
	DEFINE l_ck_major DECIMAL(4, 2)
	DEFINE l_ck_minor SMALLINT

	-- if client doesn't match just return true
	IF NOT m_isGDC THEN
		RETURN TRUE
	END IF

	CALL g2_getVer(ui.Interface.getFrontEndVersion()) RETURNING l_fe_major, l_fe_minor
	CALL g2_getVer(l_ver) RETURNING l_ck_major, l_ck_minor

	IF l_fe_major < l_ck_major OR (l_fe_major = l_ck_major AND l_fe_minor < l_ck_minor) THEN
		-- client matched by version is too old
		CALL g2_winMessage(
				"Error",
				SFMT("Your Client '%1' version doesn't support feature '%2'!\nNeed min version of %3", 
						l_cli, l_feature, l_ver),
				"exclamation")
		RETURN FALSE
	END IF
	RETURN TRUE
END FUNCTION
--------------------------------------------------------------------------------
-- Break the Version string into major and minor
FUNCTION g2_getVer(l_str STRING) RETURNS(DECIMAL(4, 2), INT)
	DEFINE l_major DECIMAL(4, 2)
	DEFINE l_minor SMALLINT
	DEFINE l_st base.StringTokenizer
	LET l_minor = l_str.getIndexOf("-", 1)
	IF l_minor > 0 THEN
		LET l_str = l_str.subString(1, l_minor - 1)
	END IF
	LET l_st = base.StringTokenizer.create(l_str, ".")
	IF l_st.countTokens() != 3 THEN
		RETURN 0, 0
	END IF
	LET l_minor = l_st.nextToken()
	LET l_major = l_minor
	LET l_minor = l_st.nextToken()
	LET l_major = l_major + (l_minor / 100)
	LET l_minor = l_st.nextToken()
	--DISPLAY "Maj:",l_major," Min:",l_minor
	RETURN l_major, l_minor
END FUNCTION
--------------------------------------------------------------------------------
#+ Default error handler
#+
#+ @return Nothing
FUNCTION g2_error() RETURNS ()
	DEFINE l_err, l_mod STRING
	DEFINE l_st STRING
	DEFINE l_stat INTEGER
	DEFINE x, y SMALLINT

	LET l_stat = status

	LET l_st = base.Application.getStackTrace()
 -- try and get just the module and line that caused the problem
	LET x = l_st.getIndexOf("#", 2) + 3
	LET y = l_st.getIndexOf("#", x + 1) - 1
	LET l_mod = l_st.subString(x, y)
	IF y < 1 THEN
		LET y = l_st.getLength()
		LET l_mod = l_st.subString(x, y)
	END IF
	IF l_mod IS NULL THEN
		GL_DBGMSG(0, SFMT("Failed to get module from stackTrace! x=%1 y%2 \n%3",x ,y, l_st))
		LET l_mod = "(null module)"
	END IF

	LET l_err = SQLERRMESSAGE
	IF l_err IS NULL THEN
		LET l_err = err_get(l_stat)
	END IF
	IF l_err IS NULL THEN
		LET l_err = "Unknown!"
	END IF
	LET l_err = SFMT("%1:%2:%3",l_mod, l_stat, l_err)
--	CALL gl_logIt("Error:"||l_err)
	IF l_stat != -6300 AND NOT m_isWS THEN
		CALL g2_errPopup(l_err)
	END IF

END FUNCTION
--------------------------------------------------------------------------------
#+ Splash Screen
#+
#+ @param l_dur > 0 for sleep then close, 0=just open window, -1=close window
#+ @param l_splashImage Image file name
#+ @param l_w Image Width
#+ @param l_h Image Height
#+ @return Nothing.
FUNCTION g2_splash(l_dur SMALLINT, l_splashImage STRING, l_w SMALLINT, l_h SMALLINT) RETURNS ()
	DEFINE f, g, n om.DomNode

	IF l_dur = -1 THEN
		CLOSE WINDOW splash
		GL_DBGMSG(3, "Close splash.")
		RETURN
	END IF

	GL_DBGMSG(3, "Open splash.")
	OPEN WINDOW splash
			AT 1, 1
			WITH 1 ROWS, 1 COLUMNS
			ATTRIBUTE(STYLE = "default noborder dialog2 bg_white")
	LET f = ui.Window.getCurrent().createForm("splash").getNode()
	LET g = f.createChild("Grid")
	LET n = g.createChild("Image")
	CALL n.setAttribute("name", "logo")
	CALL n.setAttribute("style", "noborder")
	CALL n.setAttribute("image", l_splashImage)
	CALL n.setAttribute("posY", "0")
	CALL n.setAttribute("posX", "0")
	CALL n.setAttribute("height", l_h || "px")
	CALL n.setAttribute("width", l_w || "px")
	CALL n.setAttribute("stretch", "both")
	CALL n.setAttribute("autoScale", "1")
	CALL ui.Interface.refresh()

	IF l_dur > 0 THEN
		SLEEP l_dur
		CLOSE WINDOW splash
		GL_DBGMSG(3, "Close splash.")
	END IF
END FUNCTION
--------------------------------------------------------------------------------
#+ Sleep that handles SIGINT
#+ @param l_timeout Number of seconds to sleep
FUNCTION g2_sleep(l_timeout SMALLINT) RETURNS()
	DEFINE l_to DATETIME YEAR TO FRACTION(3)
	IF l_timeout <= 0 OR l_timeout IS NULL THEN
		RETURN
	END IF
	LET l_to = CURRENT + (l_timeout UNITS SECOND)
	WHILE CURRENT < l_to
		SLEEP 1
	END WHILE
END FUNCTION
--------------------------------------------------------------------------------
#+ Returns the image from the 1st path found in FGLIMAGEPATH
FUNCTION g2_getImagePath() RETURNS STRING
	DEFINE l_imgPath STRING
	DEFINE x SMALLINT
	LET l_imgPath = fgl_getenv("FGLIMAGEPATH")
	LET x = l_imgPath.getIndexOf(os.Path.pathSeparator(),1)
	IF x > 0 THEN
		LET l_imgPath = l_imgPath.subString(1,x-1)
	END IF
	RETURN l_imgPath
END FUNCTION
--------------------------------------------------------------------------------
#+ Cleanly exit program, setting exit status.
#+
#+ @param stat Exit status 0 or -1 normally.
#+ @param reason For Exit, clean, crash, closed, terminated etc
#+ @return none
FUNCTION g2_exitProgram(l_stat SMALLINT, l_reason STRING) RETURNS ()
	GL_DBGMSG(0, SFMT("g2_exitProgram: stat=%1 reason:%2", l_stat, l_reason))
	CALL m_log.logProgramRun(FALSE, NULL, l_reason)
	EXIT PROGRAM l_stat
END FUNCTION