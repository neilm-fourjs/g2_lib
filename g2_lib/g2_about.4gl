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

IMPORT os
&ifdef gen320
IMPORT FGL g2_util
IMPORT FGL g2_aui
IMPORT FGL g2_appInfo
&else
PACKAGE g2_lib
IMPORT FGL g2_lib.*
&endif

--------------------------------------------------------------------------------
#+ Dynamic About Window
#+
#+ @param l_ver a version string
#+ @return Nothing.
FUNCTION g2_about(l_appInfo appInfo INOUT)
	DEFINE f, n, g, w om.DomNode
	DEFINE nl om.NodeList
	DEFINE gver, info, txt STRING
	DEFINE y SMALLINT

	LET gver = "build ", fgl_getversion()

	IF l_appInfo.fe_typ IS NULL THEN
		CALL l_appInfo.getClientInfo()
	END IF

	IF l_appInfo.userName IS NULL THEN
		CALL l_appInfo.setUserName(NULL)
	END IF
	IF l_appInfo.hostname IS NULL THEN
		LET l_appInfo.hostname = g2_util.g2_getHostname()
	END IF

	OPEN WINDOW about AT 1, 1 WITH 1 ROWS, 1 COLUMNS ATTRIBUTE(STYLE = "naked")
	LET n = g2_aui.g2_getWinNode(NULL)
	CALL n.setAttribute("text", l_appInfo.progDesc)
	LET f = g2_aui.g2_genForm("about")
	LET n = f.createChild("VBox")
	CALL n.setAttribute("posY", "0")
	CALL n.setAttribute("posX", "0")

	IF l_appInfo.splashImage IS NOT NULL AND l_appInfo.splashImage != " " THEN
		LET g = n.createChild("HBox")
		CALL g.setAttribute("posY", y)
		CALL g.setAttribute("gridWidth", 36)

		LET w = g.createChild("SpacerItem")

		LET w = g.createChild("Image")
		CALL w.setAttribute("posY", "0")
		CALL w.setAttribute("posX", "0")
		CALL w.setAttribute("name", "logo")
		CALL w.setAttribute("style", "noborder center")
		CALL w.setAttribute("stretch", "x")
		CALL w.setAttribute("autoScale", "1")
		CALL w.setAttribute("gridWidth", "12")
		CALL w.setAttribute("image", l_appInfo.splashImage)
		CALL w.setAttribute("height", "100px")
		CALL w.setAttribute("width", "290px")

		LET w = g.createChild("SpacerItem")
		LET y = 10
	ELSE
		LET y = 1
	END IF

	LET g = n.createChild("Group")
	CALL g.setAttribute("text", "About")
	CALL g.setAttribute("posY", "10")
	CALL g.setAttribute("posX", "0")
	CALL g.setAttribute("style", "about")
	CALL g.setAttribute("gridWidth", 36)

	IF l_appInfo.appBuild IS NOT NULL THEN
		CALL g2_aui.g2_addLabel(g, 0, y, LSTR("Application"), "right", "black")
		CALL g2_aui.g2_addLabel(g, 10, y, l_appInfo.appName || " - " || l_appInfo.appBuild, NULL, NULL)
		LET y = y + 1
	END IF

	CALL g2_aui.g2_addLabel(g, 0, y, LSTR("Program") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(
			g, 10, y, l_appInfo.progName || " - " || l_appInfo.progVersion, NULL, "black")
	LET y = y + 1

	CALL g2_aui.g2_addLabel(g, 0, y, LSTR("Description") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, 10, y, l_appInfo.progDesc, NULL, "black")
	LET y = y + 1

	CALL g2_aui.g2_addLabel(g, 0, y, LSTR("Author") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, 10, y, l_appInfo.progAuth, NULL, "black")
	LET y = y + 1

	LET w = g.createChild("HLine")
	CALL w.setAttribute("posY", y)
	LET y = y + 1
	CALL w.setAttribute("posX", 0)
	CALL w.setAttribute("gridWidth", 25)

	CALL g2_aui.g2_addLabel(g, 0, y, LSTR("Genero Runtime") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, 10, y, gver, NULL, "black")
	LET y = y + 1

	CALL g2_aui.g2_addLabel(g, 0, y, LSTR("Server OS") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, 10, y, l_appInfo.os, NULL, "black")
	LET y = y + 1

	CALL g2_aui.g2_addLabel(g, 0, y, LSTR("Server Name") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, 10, y, l_appInfo.hostname, NULL, "black")
	LET y = y + 1

	CALL g2_aui.g2_addLabel(g, 0, y, LSTR("Application User") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, 10, y, l_appInfo.userName, NULL, "black")
	LET y = y + 1

	CALL g2_aui.g2_addLabel(g, 0, y, LSTR("Server Time:") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, 10, y, TODAY || " " || TIME, NULL, "black")
	LET y = y + 1

	CALL g2_aui.g2_addLabel(g, 0, y, LSTR("Database Name") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, 10, y, fgl_getenv("DBNAME"), NULL, NULL)
	LET y = y + 1

	CALL g2_aui.g2_addLabel(g, 0, y, LSTR("Database Type") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, 10, y, upshift(fgl_db_driver_type()), NULL, "black")
	LET y = y + 1

	CALL g2_aui.g2_addLabel(g, 0, y, LSTR("DBDATE") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, 10, y, fgl_getenv("DBDATE"), NULL, "black")
	LET y = y + 1

	LET w = g.createChild("HLine")
	CALL w.setAttribute("posY", y)
	LET y = y + 1
	CALL w.setAttribute("posX", 0)
	CALL w.setAttribute("gridWidth", 25)

	CALL g2_aui.g2_addLabel(g, 0, y, LSTR("Client OS") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, 10, y, l_appInfo.cli_os || " / " || l_appInfo.cli_osver, NULL, "black")
	LET y = y + 1

	CALL g2_aui.g2_addLabel(g, 0, y, LSTR("Clint OS User") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, 10, y, NVL(l_appInfo.cli_un, "Unknown"), NULL, "black")
	LET y = y + 1

	{IF m_user_agent.getLength() > 1 THEN
			CALL g2_aui.g2_addLabel(g, 0,y,LSTR("User Agent")||":","right","black")
			CALL g2_aui.g2_addLabel(g,10,y,m_u<builtin>.fgl_getenvNULL,"black") LET y = y + 1
		END IF}

	CALL g2_aui.g2_addLabel(g, 0, y, LSTR("FrontEnd Version") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, 10, y, l_appInfo.fe_typ || " " || l_appInfo.fe_ver, NULL, "black")
	LET y = y + 1

	CALL g2_aui.g2_addLabel(g, 0, y, LSTR("Universal Renderer") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, 10, y, l_appInfo.uni_typ || " " || l_appInfo.uni_ver, NULL, "black")
	LET y = y + 1
	CALL g2_aui.g2_addLabel(g, 0, y, LSTR("FrontEnd Version-FEinfo") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, 10, y, l_appInfo.fe_typ || " " || l_appInfo.fe_ver, NULL, "black")
	LET y = y + 1

	IF l_appInfo.cli_dir.getLength() > 1 THEN
		CALL g2_aui.g2_addLabel(g, 0, y, LSTR("Client Directory") || ":", "right", "black")
		CALL g2_aui.g2_addLabel(g, 10, y, l_appInfo.cli_dir, NULL, "black")
		LET y = y + 1
	END IF

	CALL g2_aui.g2_addLabel(g, 0, y, LSTR("Screen Resolution") || ":", "right", "black")
	CALL g2_aui.g2_addLabel(g, 10, y, l_appInfo.cli_res, NULL, "black")
	LET y = y + 1

	LET g = g.createChild("HBox")
	CALL g.setAttribute("posY", y)
	CALL g.setAttribute("gridWidth", 40)
	LET w = g.createChild("SpacerItem")
	LET w = g.createChild("Button")
	CALL w.setAttribute("posY", y)
	CALL w.setAttribute("text", "Copy to Clipboard")
	CALL w.setAttribute("name", "copyabout")
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
		LET w = nl.item(y)
		LET txt = w.getAttribute("text")
		IF txt IS NULL THEN
			LET txt = "(null)"
		END IF
		LET info = info.append(txt)
		IF NOT y MOD 2 THEN
			LET info = info.append("\n")
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
			CALL ui.Interface.frontCall("standard", "cbset", info, y)
	END MENU
	CLOSE WINDOW about

END FUNCTION
