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

&ifdef gen320
IMPORT FGL g2_core
IMPORT FGL g2_debug
&else
PACKAGE g2_lib
IMPORT FGL g2_lib.g2_core
IMPORT FGL g2_lib.g2_debug
&endif

IMPORT os
-- From $GREDIR/lib
IMPORT FGL libgreprops
IMPORT FGL libgre

PUBLIC TYPE greRpt RECORD
	reportsDir STRING,
	rptName STRING,
	fileName STRING,
	device STRING,
	preview BOOLEAN,
	pageWidth SMALLINT,
	rptTitle STRING,
	handle om.SaxDocumentHandler,
	greDistributed BOOLEAN,
	greServer STRING,
	greServerPort INTEGER,
	greOutputDir STRING,
	started DATETIME HOUR TO FRACTION(5),
	finished DATETIME HOUR TO FRACTION(5),
	status INTEGER,
	error STRING
END RECORD

FUNCTION (this greRpt)
		init(
		l_rptName STRING, l_preview BOOLEAN, l_device STRING, l_start BOOLEAN)
		RETURNS BOOLEAN
	LET this.rptName = l_rptName
	LET this.preview = l_preview

	IF l_device IS NULL OR l_device = "ASK" THEN
		IF NOT this.getOutput() THEN
			DISPLAY "g2_grw: getOutput returned false"
			RETURN FALSE
		END IF
	ELSE
		LET this.device = l_device
	END IF

	LET this.greDistributed = FALSE
	LET this.greServer = fgl_getenv("GRESERVER")
	LET this.greServerPort = fgl_getenv("GRESRVPORT")
	LET this.greOutputDir = fgl_getenv("GREOUTPUTDIR")
	IF this.greServerPort IS NULL THEN
		LET this.greServerPort = 6490
	END IF
	IF this.greServer.getLength() > 1 THEN
		LET this.greDistributed = TRUE
	END IF
	IF l_start THEN
		RETURN this.start()
	ELSE
		DISPLAY "g2_grw: l_start NOT true!"
		RETURN TRUE
	END IF
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION (this greRpt) start() RETURNS BOOLEAN
	DISPLAY SFMT("g2_grw: GREOUTPUTDIR: %1 GRESERVER: %2 GRESRVPORT: %3",
			this.greOutputDir, this.greServer, this.greServerPort)

	IF this.preview IS NULL THEN
		LET this.preview = FALSE
	END IF
	IF this.reportsDir IS NULL THEN
		LET this.reportsDir = fgl_getenv("REPORTDIR")
	END IF
	IF this.reportsDir IS NULL THEN
		LET this.reportsDir = "../etc"
	END IF
	IF this.rptName IS NOT NULL THEN
		IF this.rptTitle IS NULL THEN
			LET this.rptTitle = this.rptName
		END IF
		LET this.rptName = os.Path.join(this.reportsDir, this.rptName.append(".4rp"))
	END IF
	IF NOT os.Path.exists(this.rptName) THEN
		CALL g2_core.g2_winMessage(
				"Error", SFMT("Report Design '%1' not found!", this.rptName), "exclamation")
		RETURN FALSE
	END IF
	IF NOT libgre.fgl_report_loadCurrentSettings(this.rptName) THEN
		CALL g2_core.g2_winMessage("Error", "Report initialize failed!", "exclamation")
		RETURN FALSE
	END IF
	IF NOT this.allOkay("load") THEN
		ERROR SFMT("%1:%2", this.status, this.error)
		RETURN FALSE
	END IF
	DISPLAY SFMT("g2_grw: Rpt: %1 Preview: %2 Device: %3 RptDir: %4 Width: %5",
			this.rptName,
			IIF(this.preview, "True", "FALSE"),
			this.device,
			this.reportsDir,
			this.pageWidth)
	IF this.pageWidth IS NOT NULL AND this.pageWidth > 0 THEN
		IF this.pageWidth > 80 THEN
			CALL libgreprops.fgl_report_configurePageSize("a4length", "a4width") -- Landscape
		ELSE
			CALL libgreprops.fgl_report_configurePageSize("a4width", "a4length") -- Portrait
		END IF
	END IF

	IF this.device = "PDF" AND this.rptName IS NULL THEN
		CALL libgreprops.fgl_report_configureCompatibilityOutput(
				this.pageWidth, "Courier", TRUE, base.Application.getProgramName(), "", "")
	END IF

	IF this.device != "XML" THEN
		CALL libgreprops.fgl_report_selectDevice(this.device)
		CALL libgreprops.fgl_report_selectPreview(this.preview)
	END IF

	IF this.device = "Printer" THEN
		CALL libgreprops.fgl_report_setPrinterName(this.fileName)
	ELSE
		IF this.fileName IS NOT NULL THEN
			DISPLAY SFMT("g2_grw: fgl_report_setOutputFileName = %1",this.fileName)
			CALL libgreprops.fgl_report_setOutputFileName(this.fileName)
		END IF
	END IF

	IF this.greDistributed THEN
		DISPLAY SFMT("g2_grw: Using distributed mode: %1 %2", this.greServer, this.greServerPort)
		CALL fgl_report_configureDistributedProcessing(this.greServer, this.greServerPort)
		CALL fgl_report_configureDistributedEnvironment(NULL, NULL, NULL, NULL)
	ELSE
		DISPLAY "g2_grw: Not using distributed mode."
	END IF

	-- Set the SAX handler
	IF this.device = "XML" THEN -- Just produce XML output
		LET this.handle = libgre.fgl_report_createProcessLevelDataFile(this.fileName)
	ELSE -- Produce a report using GRE
		LET this.handle = libgre.fgl_report_commitCurrentSettings()
	END IF
	IF NOT this.allOkay("commit") THEN
		ERROR SFMT("%1:%2", this.status, this.error)
		RETURN FALSE
	END IF
	LET this.started = CURRENT

	MESSAGE SFMT("Printing Report %1, please wait ...", NVL(this.rptName, "ASCII"))
	CALL ui.Interface.refresh()
	RETURN TRUE
END FUNCTION
-------------------------------------------------------------------------------
FUNCTION (this greRpt) allOkay(l_where STRING) RETURNS BOOLEAN
	DEFINE x SMALLINT
	LET this.status = fgl_report_getErrorStatus()
	IF this.status != 0 THEN
		LET this.error = l_where, ":", fgl_report_getErrorString()
		LET x = this.error.getIndexOf("	", 1)
		IF x > 0 THEN
			LET this.error = this.error.subString(1, x - 1)
		END IF
		RETURN FALSE
	END IF
	RETURN TRUE
END FUNCTION
-------------------------------------------------------------------------------
-- @param l_row 0 = open / > 0 update = l_max close
-- @param l_max max rows expected
-- @param l_mod update count on mod
FUNCTION (this greRpt) progress(l_row INTEGER, l_max INTEGER, l_mod SMALLINT) RETURNS()
	DEFINE l_win, l_frm, l_grid, l_frmf, l_pbar om.DomNode
	IF l_row < 1 THEN
		OPEN WINDOW progbar WITH 1 ROWS, 50 COLUMNS
		LET l_win = ui.Window.getCurrent().getNode()
		CALL l_win.setAttribute("style", "naked")
		CALL l_win.setAttribute("width", 45)
		CALL l_win.setAttribute("height", 2)
		LET l_frm = ui.Window.getCurrent().createForm("ProgBar").getNode()
		CALL l_win.setAttribute("text", SFMT("Printing '%1' ...", this.rptTitle))

		LET l_grid = l_frm.createChild('Grid')

		LET l_frmf = l_grid.createChild('FormField')
		CALL l_frmf.setAttribute("colName", "progress")
		CALL l_frmf.setAttribute("value", 0)
		LET l_pbar = l_frmf.createChild('ProgressBar')
		CALL l_pbar.setAttribute("width", 40)
		CALL l_pbar.setAttribute("posY", 1)
		CALL l_pbar.setAttribute("valueMax", l_max)
		CALL l_pbar.setAttribute("valueMin", 1)

		IF l_row = -1 THEN
			LET l_grid = l_grid.createChild('HBox')
			CALL l_grid.setAttribute("posY", 3)
			LET l_frmf = l_grid.createChild('SpacerItem')
			LET l_frmf = l_grid.createChild('Button')
			CALL l_frmf.setAttribute("name", "cancel")
			LET l_frmf = l_grid.createChild('SpacerItem')
		END IF
	END IF

-- update the progressbar
	IF l_row > 0 THEN
		DISPLAY l_row TO progress
	END IF

	IF l_row = l_max THEN
		CLOSE WINDOW progbar
	END IF
	IF NOT l_row MOD l_mod THEN
--		DISPLAY l_row,":Refresh"
		CALL ui.Interface.refresh()
	ELSE
--		DISPLAY l_row
	END IF
END FUNCTION
-------------------------------------------------------------------------------
FUNCTION (this greRpt) finish() RETURNS()
	IF NOT this.allOkay("finish") THEN
		ERROR SFMT("%1:%2", this.status, this.error)
		RETURN
	END IF
	IF this.device = "Browser" AND this.preview THEN
		CALL ui.Interface.frontCall("standard", "launchurl", [fgl_report_getBrowserURL()], [])
	END IF
	LET this.finished = CURRENT
	MESSAGE SFMT("Report %1 Finished.", NVL(this.rptName, "ASCII"))
	CALL ui.Interface.refresh()
  IF NOT this.preview THEN
    DISPLAY SFMT("Trying to open %1", os.Path.join(this.greOutputDir, this.fileName) )
--TODO: need to detect OS version and change this !!
    RUN "xdg-open "||os.Path.join(this.greOutputDir, this.fileName)
	END IF
END FUNCTION
-------------------------------------------------------------------------------
FUNCTION (this greRpt) getOutput() RETURNS BOOLEAN
	DEFINE l_dest CHAR(1)
	DEFINE l_fileName STRING
	LET int_flag = FALSE
	MENU "Report Destination"
			ATTRIBUTES(STYLE = "dialog", COMMENT = "Output report to ...", IMAGE = "question")
		COMMAND "File XML"
			LET l_dest = "F"
			LET this.device = "XML"
			LET this.preview = FALSE
		COMMAND "File PDF"
			LET l_dest = "F"
			LET this.device = "PDF"
			LET this.preview = FALSE
		COMMAND "File XLSX"
			LET l_dest = "F"
			LET this.device = "XLSX"
			LET this.preview = FALSE
		COMMAND "Screen"
			LET l_dest = "S"
			IF ui.Interface.getFrontEndName() = "GDC" THEN
				LET this.device = "SVG"
			ELSE
				LET this.device = "Browser"
			END IF
			LET this.preview = TRUE
			LET this.fileName = ""
		COMMAND "PDF"
			LET l_dest = "D"
			LET this.device = "PDF"
			LET this.preview = TRUE
			LET this.fileName = ""
		COMMAND "XLS"
			LET l_dest = "D"
			LET this.device = "XLS"
			LET this.preview = TRUE
			LET this.fileName = ""
		COMMAND "XLSX"
			LET l_dest = "D"
			LET this.device = "XLSX"
			LET this.preview = TRUE
			LET this.fileName = ""
		COMMAND "Printer"
			LET l_dest = "P"
			LET this.device = "Printer"
		ON ACTION close LET int_flag = TRUE
	END MENU
	IF int_flag THEN
		CALL g2_core.g2_winMessage("Cancelled", "Report cancelled", "information")
		RETURN FALSE
	END IF
	IF l_dest = "F" THEN
		IF this.fileName IS NULL THEN
			PROMPT "Enter filename:" FOR l_fileName
			IF l_fileName IS NULL THEN
				LET this.fileName = base.Application.getProgramName()
			END IF
		ELSE
			PROMPT SFMT("Enter filename ( %1 ):",this.fileName) FOR l_fileName
			IF l_fileName IS NOT NULL THEN LET this.fileName = l_fileName END IF
		END IF
		IF this.fileName.getIndexOf(".", 1) < 1 THEN
			LET this.fileName = this.fileName.append("." || this.device.toLowerCase())
		END IF
	END IF
	IF int_flag THEN
		CALL g2_core.g2_winMessage("Cancelled", "Report cancelled", "information")
		RETURN FALSE
	END IF
	DISPLAY SFMT("g2_grw: Filename: %1", this.fileName)
	RETURN TRUE
END FUNCTION
