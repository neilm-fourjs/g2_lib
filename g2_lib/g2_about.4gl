--------------------------------------------------------------------------------
#+ Genero About Window - by Neil J Martin ( neilm@4js.com )
#+ This library is intended as an example of useful library code for use with
#+ Genero 4.00 and above
#+
#+ No warrantee of any kind, express or implied, is included with this software;
#+ use at your own risk, responsibility for damages (if any) to anyone resulting
#+ from the use of this software rests entirely with the user.
#+
#+ No includes required.

&ifdef gen320
IMPORT FGL g2_appInfo
IMPORT FGL g2_core
IMPORT FGL g2_aui
IMPORT FGL g2_util
IMPORT FGL g2_db
&else
PACKAGE g2_lib
-- IMPORT FGL g2_lib.* -- failed in GST?
IMPORT FGL g2_lib.g2_appInfo
IMPORT FGL g2_lib.g2_core
IMPORT FGL g2_lib.g2_aui
IMPORT FGL g2_lib.g2_util
IMPORT FGL g2_lib.g2_db
&endif

IMPORT util

--------------------------------------------------------------------------------
#+ Dynamic About Window
#+
#+ @param l_ver a version string
#+ @return Nothing.
FUNCTION g2_about()
	DEFINE f, n, g, w            om.DomNode
	DEFINE nl                    om.NodeList
	DEFINE l_info, l_txt STRING
	DEFINE l_save STRING
	DEFINE y, l_width SMALLINT
	DEFINE l_labWidth SMALLINT = 10
	DEFINE l_json TEXT

	IF g2_core.m_appInfo.gver IS NULL THEN
		LET g2_core.m_appInfo.gver = "build ", fgl_getversion()
	END IF
	IF g2_core.m_appInfo.fe_typ IS NULL THEN
		CALL g2_core.m_appInfo.getClientInfo()
	END IF
	IF g2_core.m_appInfo.userName IS NULL THEN
		CALL g2_core.m_appInfo.setUserName(NULL)
	END IF
	IF g2_core.m_appInfo.hostname IS NULL THEN
		LET g2_core.m_appInfo.hostname = g2_util.g2_getHostname()
	END IF
	IF g2_core.m_appInfo.progDir IS NULL THEN
		LET g2_core.m_appInfo.progDir = base.Application.getProgramDir()
	END IF
	LET l_width =  l_labWidth + g2_core.m_appInfo.progDir.getLength()
	LET g2_core.m_appInfo.db_date     = fgl_getenv("DBDATE")
	LET g2_core.m_appInfo.db_name     = SFMT("%1 (from: %2)", g2_db.m_db.name, g2_db.m_db.db_cfg)
	LET g2_core.m_appInfo.db_driver   = SFMT("%1 (source: %2)", g2_db.m_db.driver, g2_db.m_db.source)
	LET g2_core.m_appInfo.server_time = TODAY || " " || TIME

	OPEN WINDOW about AT 1, 1 WITH 1 ROWS, 1 COLUMNS ATTRIBUTE(STYLE = "naked")
	LET n = g2_aui.g2_getWinNode(NULL)
	CALL n.setAttribute("text", g2_core.m_appInfo.progDesc)
	LET f = g2_aui.g2_genForm("about")
	LET n = f.createChild("VBox")
	CALL n.setAttribute("posY", "0")
	CALL n.setAttribute("posX", "0")
	LET y = 1
	IF g2_core.m_appInfo.splashImage IS NOT NULL AND g2_core.m_appInfo.splashImage != " " THEN
		LET g = n.createChild("HBox")
		CALL g.setAttribute("posY", y)
		CALL g.setAttribute("gridWidth", l_width)
		CALL g.setAttribute("width", l_width)
		CALL g.setAttribute("gridHeight", 4)
		CALL g.setAttribute("height", 4)

		LET w = g.createChild("SpacerItem")
		LET w = g.createChild("Image")
		CALL w.setAttribute("posY", y)
		CALL w.setAttribute("posX", "0")
		CALL w.setAttribute("name", "logo")
		CALL w.setAttribute("style", "noborder center")
		--CALL w.setAttribute("stretch", "x")
		CALL w.setAttribute("autoScale", "1")
		CALL w.setAttribute("gridWidth", "12")
		CALL w.setAttribute("image", g2_core.m_appInfo.splashImage)
		CALL w.setAttribute("height", "100px")
		CALL w.setAttribute("width", "290px")
		LET w = g.createChild("SpacerItem")
		LET y = 5
	ELSE
		LET y = 2
	END IF

	LET g = n.createChild("Group")
	CALL g.setAttribute("text", "About")
	CALL g.setAttribute("posY", y)
	CALL g.setAttribute("posX", "0")
	CALL g.setAttribute("style", "about")
	CALL g.setAttribute("gridWidth", l_width)

	IF g2_core.m_appInfo.appBuild IS NOT NULL THEN
		CALL g2_aui.g2_addLabel(g, 0, y, l_labWidth, LSTR("Application"), "right", "black")
		CALL g2_aui.g2_addLabel(g, l_labWidth+1, y, 0, g2_core.m_appInfo.appName || " - " || g2_core.m_appInfo.appBuild, NULL, NULL)
		LET y = y + 1
	END IF

	CALL g2_aui.g2_addLabel(g, 0, y, l_labWidth, LSTR("Program") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, l_labWidth+1, y, 0, g2_core.m_appInfo.progName || " - " || g2_core.m_appInfo.progVersion, NULL, "black")
	LET y = y + 1

	CALL g2_aui.g2_addLabel(g, 0, y, l_labWidth, LSTR("Description") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, l_labWidth+1, y, 0, g2_core.m_appInfo.progDesc, NULL, "black")
	LET y = y + 1

	CALL g2_aui.g2_addLabel(g, 0, y, l_labWidth, LSTR("Author") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, l_labWidth+1, y, 0, g2_core.m_appInfo.progAuth, NULL, "black")
	LET y = y + 1

	LET w = g.createChild("HLine")
	CALL w.setAttribute("posY", y)
	LET y = y + 1
	CALL w.setAttribute("posX", 0)
	CALL w.setAttribute("gridWidth", l_width)

	CALL g2_aui.g2_addLabel(g, 0, y, l_labWidth, LSTR("Run Location") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, l_labWidth+1, y, 0, g2_core.m_appInfo.progDir, NULL, "black")
	LET y = y + 1

	CALL g2_aui.g2_addLabel(g, 0, y, l_labWidth, LSTR("Genero Runtime") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, l_labWidth+1, y, 0, g2_core.m_appInfo.gver, NULL, "black")
	LET y = y + 1

	CALL g2_aui.g2_addLabel(g, 0, y, l_labWidth, LSTR("Server OS") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, l_labWidth+1, y, 0, g2_core.m_appInfo.os, NULL, "black")
	LET y = y + 1

	CALL g2_aui.g2_addLabel(g, 0, y, l_labWidth, LSTR("Server Name") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, l_labWidth+1, y, 0, g2_core.m_appInfo.hostname, NULL, "black")
	LET y = y + 1

	CALL g2_aui.g2_addLabel(g, 0, y, l_labWidth, LSTR("Application User") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, l_labWidth+1, y, 0, g2_core.m_appInfo.userName, NULL, "black")
	LET y = y + 1

	CALL g2_aui.g2_addLabel(g, 0, y, l_labWidth, LSTR("Server Time:") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, l_labWidth+1, y, 0, g2_core.m_appInfo.server_time, NULL, "black")
	LET y = y + 1

	IF g2_db.m_db.name IS NULL THEN
		CALL g2_aui.g2_addLabel(g, 0, y, l_labWidth, LSTR("Database Name") || ":", "right", "black")
		CALL g2_aui.g2_addLabel(g, l_labWidth+1, y, 0, "No Database", NULL, NULL)
		LET y = y + 1
	ELSE
		CALL g2_aui.g2_addLabel(g, 0, y, l_labWidth, LSTR("Database Name") || ":", "right", "black")
		CALL g2_aui.g2_addLabel(g, l_labWidth+1, y, 0, g2_core.m_appInfo.db_name, NULL, "black")
		LET y = y + 1

		CALL g2_aui.g2_addLabel(g, 0, y, l_labWidth, LSTR("Database Driver") || ":", "right", "black")
		CALL g2_aui.g2_addLabel(g, l_labWidth+1, y, 0, g2_core.m_appInfo.db_driver, NULL, "black")
		LET y = y + 1
	END IF
	CALL g2_aui.g2_addLabel(g, 0, y, l_labWidth, LSTR("DBDATE") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, l_labWidth+1, y, 0, g2_core.m_appInfo.db_date, NULL, "black")
	LET y = y + 1

	LET w = g.createChild("HLine")
	CALL w.setAttribute("posY", y)
	LET y = y + 1
	CALL w.setAttribute("posX", 0)
	CALL w.setAttribute("gridWidth", l_width)

	CALL g2_aui.g2_addLabel(g, 0, y, l_labWidth, LSTR("Client OS") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, l_labWidth+1, y, 0, g2_core.m_appInfo.cli_os || " / " || g2_core.m_appInfo.cli_osver, NULL, "black")
	LET y = y + 1

	CALL g2_aui.g2_addLabel(g, 0, y, l_labWidth, LSTR("Clint OS User") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, l_labWidth+1, y, 0, NVL(g2_core.m_appInfo.cli_un, "Unknown"), NULL, "black")
	LET y = y + 1

	{IF m_user_agent.getLength() > 1 THEN
			CALL g2_aui.g2_addLabel(g, 0,y, 9, LSTR("User Agent")||":","right","black")
			CALL g2_aui.g2_addLabel(g,10,y,m_u<builtin>.fgl_getenvNULL,"black") LET y = y + 1
		END IF}

	CALL g2_aui.g2_addLabel(g, 0, y, l_labWidth, LSTR("FrontEnd Version") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, l_labWidth+1, y, 0, g2_core.m_appInfo.fe_typ || " " || g2_core.m_appInfo.fe_ver, NULL, "black")
	LET y = y + 1

	CALL g2_aui.g2_addLabel(g, 0, y, l_labWidth, LSTR("Universal Renderer") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, l_labWidth+1, y, 0, g2_core.m_appInfo.uni_typ || " " || g2_core.m_appInfo.uni_ver, NULL, "black")
	LET y = y + 1
	CALL g2_aui.g2_addLabel(g, 0, y, l_labWidth, LSTR("FrontEnd Version-FEinfo") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, l_labWidth+1, y, 0, g2_core.m_appInfo.fe_typ || " " || g2_core.m_appInfo.fe_ver, NULL, "black")
	LET y = y + 1

	IF g2_core.m_appInfo.cli_dir.getLength() > 1 THEN
		CALL g2_aui.g2_addLabel(g, 0, y, l_labWidth, LSTR("Client Directory") || ":", "right", "black")
		CALL g2_aui.g2_addLabel(g, l_labWidth+1, y, 0, g2_core.m_appInfo.cli_dir, NULL, "black")
		LET y = y + 1
	END IF

	CALL g2_aui.g2_addLabel(g, 0, y, l_labWidth, LSTR("Screen Resolution") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, l_labWidth+1, y, 0, g2_core.m_appInfo.cli_res, NULL, "black")
	LET y = y + 1

	LET g = g.createChild("HBox")
	CALL g.setAttribute("posY", y)
	CALL g.setAttribute("gridWidth", l_width)
	LET w = g.createChild("SpacerItem")
	LET w = g.createChild("Button")
	CALL w.setAttribute("posY", y)
	CALL w.setAttribute("text", "Copy to Clipboard")
	CALL w.setAttribute("name", "copyabout")
	LET w = g.createChild("Button")
	CALL w.setAttribute("posY", y)
	CALL w.setAttribute("text", "Save as JSON")
	CALL w.setAttribute("name", "jsonabout")
	LET w = g.createChild("Button")
	CALL w.setAttribute("posY", y)
	CALL w.setAttribute("text", "Show Env")
	CALL w.setAttribute("name", "showenv")
	LET w = g.createChild("Button")
	CALL w.setAttribute("posY", y)
	CALL w.setAttribute("text", "Show License")
	CALL w.setAttribute("name", "showlicence")
	LET w = g.createChild("Button")
	CALL w.setAttribute("posY", y)
	CALL w.setAttribute("text", "ReadMe")
	CALL w.setAttribute("name", "showreadme")
	LET w = g.createChild("Button")
	CALL w.setAttribute("posY", y)
	CALL w.setAttribute("text", "Close")
	CALL w.setAttribute("name", "closeabout")
	LET w = g.createChild("SpacerItem")

	LET nl = f.selectByTagName("Label")
	FOR y = 1 TO nl.getLength()
		LET w     = nl.item(y)
		LET l_txt = w.getAttribute("text")
		IF l_txt IS NULL THEN
			LET l_txt = "(null)"
		END IF
		LET l_info = l_info.append(l_txt)
		IF NOT y MOD 2 THEN
			LET l_info = l_info.append("\n")
		END IF
	END FOR

	MENU "Options"
		ON ACTION close
			EXIT MENU
		ON ACTION closeabout
			EXIT MENU
		ON ACTION showenv
			CALL g2_aui.g2_showEnv()
		ON ACTION showreadme
			CALL g2_aui.g2_showReadMe()
		ON ACTION showlicence
			CALL g2_aui.g2_showLicence()
		ON ACTION copyabout
			CALL ui.Interface.frontCall("standard", "cbset", l_info, y)
		ON ACTION jsonabout
			LOCATE l_json IN FILE "about.json"
			LET l_json = util.JSON.stringify(g2_core.m_appInfo)
			IF g2_core.m_appInfo.fe_typ = "GDC" THEN
				CALL ui.Interface.frontCall("standard", "savefile", [NULL, "about.json", "*.json", "Save About JSON"], l_save)
			ELSE
				LET l_save = "about.json"
			END IF
			IF l_save IS NOT NULL THEN
				CALL fgl_putFile("about.json", l_save)
			END IF
	END MENU
	CLOSE WINDOW about

END FUNCTION
