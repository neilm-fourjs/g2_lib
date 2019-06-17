IMPORT FGL g2_lib
IMPORT FGL g2_aui
IMPORT FGL g2_db
&include "g2_debug.inc"

CONSTANT MAXCOLWIDTH = 40

PUBLIC TYPE lookup RECORD
		tableName STRING, 
		columnList STRING, 
		columnTitles STRING, 
		whereClause STRING, 
		orderBy STRING,
		maxColWidth SMALLINT,
		allowUpdate BOOLEAN,
		sql_count STRING,
		sql_getData STRING,
		totalRecords INTEGER,
		sqlQueryHandle base.SqlHandle,
		fields DYNAMIC ARRAY OF RECORD
			name STRING,
			type STRING
  	END RECORD,
		columnTitlesArr DYNAMIC ARRAY OF STRING,
		formName STRING,
		windowTitle STRING,
		selectedKey STRING
	END RECORD

PUBLIC FUNCTION (this lookup) g2_lookup2() RETURNS STRING
	DEFINE l_key STRING
	DEFINE x, i SMALLINT
  DEFINE l_frm, l_grid, l_tabl, l_tabc, l_edit, l_curr om.DomNode
  DEFINE l_hbx, l_sp, l_titl om.DomNode
  DEFINE l_dlg ui.Dialog
  DEFINE l_event STRING

	IF NOT this.checkLookParams() THEN RETURN NULL END IF

  GL_DBGMSG(2, "g2_lookup2: table(s)=" || this.tableName)
  GL_DBGMSG(2, "g2_lookup2: cols		=" || this.columnList)
  GL_DBGMSG(2, "g2_lookup2: l_titles	=" || this.columnTitles)
  GL_DBGMSG(2, "g2_lookup2: where	 =" || this.whereClause)
  GL_DBGMSG(2, "g2_lookup2: orderby =" || this.orderBy)
  GL_DBGMSG(2, "g2_lookup2: Declaring Count Cursor...")

-- Check to make sure there are records.
	IF this.sql_count IS NULL THEN
    LET this.sql_count = "SELECT COUNT(*) FROM " || this.tableName || " WHERE " || this.whereClause
	END IF
  TRY
    PREPARE listcntpre FROM this.sql_count
  CATCH
    CALL g2_lib.g2_errPopup(SFMT(% "Failed to prepare:\n%1\n%2", this.sql_count, SQLERRMESSAGE))
    RETURN NULL --, NULL
  END TRY
  DECLARE listcntcur CURSOR FOR listcntpre
  OPEN listcntcur
  FETCH listcntcur INTO this.totalRecords
  CLOSE listcntcur
  IF this.totalRecords < 1 THEN
    CALL g2_lib.g2_errPopup(% "No Records Found")
    RETURN NULL
  END IF
  GL_DBGMSG(2, "g2_lookup2: Counted:" || this.totalRecords)

-- build the main sql if it's not already defined
	IF this.sql_getData IS NULL THEN
		LET this.sql_getData = "SELECT " || this.columnList || " FROM " || this.tableName, " WHERE " || this.whereClause
		IF this.orderBy IS NOT NULL THEN
			LET this.sql_getData = this.sql_getData CLIPPED, " ORDER BY " || this.orderBy
		END IF
	END IF

-- Perpare the main cursor
  LET this.sqlQueryHandle = base.SqlHandle.create()
  TRY
    CALL this.sqlQueryHandle.prepare(this.sql_getData)
    CALL this.sqlQueryHandle.openScrollCursor()
  CATCH
    CALL g2_lib.g2_errPopup(SFMT(% "Failed to prepare:\n%1\n%2", this.sql_getData, SQLERRMESSAGE))
    RETURN NULL
  END TRY
  CALL this.fields.clear()
  FOR x = 1 TO this.sqlQueryHandle.getResultCount()
    LET this.fields[x].name = this.sqlQueryHandle.getResultName(x)
    LET this.fields[x].type = this.sqlQueryHandle.getResultType(x)
    GL_DBGMSG(2, "g2_lookup2:" || x || " Name:" || this.fields[x].name || " Type:" || this.fields[x].type)
  END FOR
  GL_DBGMSG(2, "g2_lookup2: Cursor Okay.")

-- Open the window and define a table.
  GL_DBGMSG(2, "g2_lookup2: Opening Window.")
  OPEN WINDOW listv AT 1, 1 WITH 20 ROWS, 80 COLUMNS ATTRIBUTE(STYLE = "naked")
  CALL fgl_setTitle(this.windowTitle)
  LET l_frm = g2_aui.g2_genForm(this.formName) -- ensures form name is specific for this lookup

  LET l_grid = l_frm.createChild('Grid')
-- Create a centered window l_title.
  LET l_hbx = l_grid.createChild('HBox')
  CALL l_hbx.setAttribute("posY", "0")
  LET l_sp = l_hbx.createChild('SpacerItem')
  LET l_titl = l_hbx.createChild('Label')
  CALL l_titl.setAttribute("text", this.windowTitle)
  CALL l_titl.setAttribute("style", "tabtitl")
  LET l_sp = l_hbx.createChild('SpacerItem')

  GL_DBGMSG(2, "g2_lookup2: Generating Table...")
-- Create the table
  LET l_tabl = l_grid.createChild('Table')
  CALL l_tabl.setAttribute("tabName", "tablistv")
  CALL l_tabl.setAttribute("height", "20")
  CALL l_tabl.setAttribute("pageSize", "20")
  CALL l_tabl.setAttribute("posY", "1")

-- Create Columns & Headings for the table.
  FOR x = 1 TO this.fields.getLength()
    LET l_tabc = l_tabl.createChild('TableColumn')
    CALL l_tabc.setAttribute("colName", this.fields[x].name)
    LET l_edit = l_tabc.createChild('Edit')
    CALL l_tabc.setAttribute("text", this.columnTitlesArr[x])
    CALL l_edit.setAttribute("width", g2_db.g2_getColumnLength(this.fields[x].type, MAXCOLWIDTH))
    IF this.columnTitlesArr[x].getCharAt(1) = "_" THEN -- if l_title starts with _ then it's a hidden column
      CALL l_tabc.setAttribute("hidden", "1")
    END IF
  END FOR

  GL_DBGMSG(2, "g2_lookup: Adding buttons...")
-- Create centered buttons.
  LET l_hbx = l_grid.createChild('HBox')
  CALL l_hbx.setAttribute("posY", "3")
  LET l_curr = l_hbx.createChild('Label')
  CALL l_curr.setAttribute("text", "Row:")
  LET l_curr = l_hbx.createChild('Label')
  CALL l_curr.setAttribute("name", "cur_row")
  CALL l_curr.setAttribute("sizePolicy", "dynamic")
  LET l_sp = l_hbx.createChild('SpacerItem')
  LET l_titl = l_hbx.createChild('Button')
  CALL l_titl.setAttribute("name", "firstrow")
  CALL l_titl.setAttribute("image", "gobegin")
  LET l_titl = l_hbx.createChild('Button')
  CALL l_titl.setAttribute("name", "prevpage")
  CALL l_titl.setAttribute("image", "gorev")
  LET l_titl = l_hbx.createChild('Button')
  CALL l_titl.setAttribute("text", "Okay")
  CALL l_titl.setAttribute("name", "accept")
  CALL l_titl.setAttribute("width", "8")
  LET l_titl = l_hbx.createChild('Button')
  CALL l_titl.setAttribute("name", "cancel")
  CALL l_titl.setAttribute("text", "Cancel")
  CALL l_titl.setAttribute("width", "8")
  LET l_titl = l_hbx.createChild('Button')
  CALL l_titl.setAttribute("name", "nextpage")
  CALL l_titl.setAttribute("image", "goforw")
  LET l_titl = l_hbx.createChild('Button')
  CALL l_titl.setAttribute("name", "lastrow")
  CALL l_titl.setAttribute("image", "goend")
  LET l_sp = l_hbx.createChild('SpacerItem')
  LET l_titl = l_hbx.createChild('Label')
  CALL l_titl.setAttribute("text", this.totalRecords USING "###,###,##&" || " Rows")
  CALL l_titl.setAttribute("sizePolicy", "dynamic")

-- Setup the dialog
  LET int_flag = FALSE
  LET l_dlg = ui.Dialog.createDisplayArrayTo(this.fields, "tablistv")
  CALL l_dlg.addTrigger("ON ACTION close")
  CALL l_dlg.addTrigger("ON ACTION accept")
  CALL l_dlg.addTrigger("ON ACTION cancel")

-- Fetch the data
  CALL this.sqlQueryHandle.fetchFirst()
  LET x = 0
  WHILE SQLCA.sqlcode = 0
    LET x = x + 1
    CALL l_dlg.setCurrentRow("tablistv", x) -- must set the current row before setting values
    FOR i = 1 TO this.sqlQueryHandle.getResultCount()
      CALL l_dlg.setFieldValue( this.sqlQueryHandle.getResultName(i),  this.sqlQueryHandle.getResultValue(i))
    END FOR
    CALL this.sqlQueryHandle.fetch()
  END WHILE
  CALL this.sqlQueryHandle.close()
  CALL l_dlg.setCurrentRow("tablistv", 1) -- TODO: should be done by the runtime
-- Loop for events.
  WHILE TRUE
    LET l_event = l_dlg.nextEvent()
    CASE l_event
      WHEN "BEFORE DISPLAY"
        IF this.totalRecords = 1 THEN
          EXIT WHILE
        END IF -- if only 1 row just select it!
      WHEN "ON ACTION close"
        LET int_flag = TRUE
        EXIT WHILE
      WHEN "ON ACTION cancel"
        LET int_flag = TRUE
        EXIT WHILE
      WHEN "ON ACTION accept"
        EXIT WHILE
      WHEN "ON SORT"
        --MESSAGE "Use 'reset sort order' to reset to default."
        EXIT WHILE
      WHEN "ON ACTION tablistv.accept" -- doubleclick
        EXIT WHILE
      WHEN "BEFORE ROW"
        LET x = l_dlg.arrayToVisualIndex("tablistv", arr_curr())
        CALL l_curr.setAttribute(
            "text", SFMT("%1 (%2)", x USING "<<<,##&", arr_curr() USING "<<<,##&"))
      OTHERWISE
        GL_DBGMSG(2, "g2_lookup: Unhandled Event:" || l_event)
    END CASE
  END WHILE
  LET this.selectedKey = l_dlg.getFieldValue(this.fields[1].name) -- get the selected row first field.
  LET l_dlg = NULL -- FIXME: CALL l_dlg.terminate()

  CLOSE WINDOW listv
  IF int_flag THEN
    GL_DBGMSG(2, "g2_lookup: Window Closed, Cancelled.")
    RETURN NULL
  ELSE
    GL_DBGMSG(2, SFMT("g2_lookup: Window Closed, returning row:%1 %2", arr_curr(),this.selectedKey.trim() ))
    RETURN this.selectedKey.trim()
  END IF

	RETURN l_key
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION (this lookup) init( tabnam STRING, cols STRING, colts STRING, wher STRING, ordby STRING)
	LET this.tableName = tabnam
	LET this.columnList = cols
	LET this.columnTitles = colts
	LET this.whereClause = wher
	LET this.orderBy = ordby
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION (this lookup) checkLookParams() RETURNS BOOLEAN
	DEFINE l_err STRING
  DEFINE l_tok base.StringTokenizer

	IF this.tableName IS NULL THEN LET l_err = l_err.append("tableName ") END IF
	IF this.columnlist IS NULL THEN LET l_err = l_err.append("columnList ") END IF
	IF this.columnTitles IS NULL THEN LET this.columnTitles = this.columnlist END IF
	IF this.whereClause IS NULL THEN LET this.whereClause = "1=1" END IF
	IF this.formName IS NULL THEN LET this.formName = "gl_"||this.tableName END IF
	IF this.windowTitle IS NULL THEN LET this.windowTitle = SFMT(%"Listing from %1",this.tableName) END IF

	LET l_tok = base.StringTokenizer.create(this.columnTitles, ",")
	CALL this.columnTitlesArr.clear() -- clear the defaults if l_title supplied.
	WHILE l_tok.hasMoreTokens()
		LET this.columnTitlesArr[this.columnTitlesArr.getLength() + 1] = l_tok.nextToken()
	END WHILE

	IF l_err IS NOT NULL THEN
		CALL g2_lib.g2_winMessage("Error",SFMT(%"Lookup called by initiated correctly!\nThe following are not set:%1", l_err),"exclamation")
		RETURN FALSE
	END IF
	RETURN TRUE
END FUNCTION