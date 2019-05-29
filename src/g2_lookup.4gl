--------------------------------------------------------------------------------
#+ Genero Library 1 - Dynamic Lookup - by Neil J Martin ( neilm@4js.com )
#+ This library is intended as an example of useful library code for use with
#+ Genero 3.20 >
#+
#+ No warrantee of any kind, express or implied, is included with this software;
#+ use at your own risk, responsibility for damages (if any) to anyone resulting
#+ from the use of this software rests entirely with the user.
--------------------------------------------------------------------------------
IMPORT FGL g2_lib
IMPORT FGL g2_aui
&include "g2_debug.inc"

CONSTANT MAXCOLWIDTH = 30
--------------------------------------------------------------------------------
#+ @code LET key = g2_lookup.g2_lookup( tabnam, cols, colts, wher, ordby )
#+
#+ @param tabnam db table name
#+ @param cols	columns names ( comma seperated )
#+ @param colts columns l_titles ( comma seperated )
#+					can be NULL to use column names
#+					can be _ to have a hidden column - ie 1st col if it's a key
#+ @param wher	The WHERE clause, 1=1 means all, or use result of construct
#+ @param ordby The ORDER BY clause
#+ @returns string with the key for selected row or NULL if cancelled or no data.
FUNCTION g2_lookup(
    tabnam STRING, cols STRING, colts STRING, wher STRING, ordby STRING)
    RETURNS STRING --{{{
  DEFINE l_frm, l_grid, l_tabl, l_tabc, l_edit, l_curr om.DomNode
  DEFINE l_hbx, l_sp, l_titl om.DomNode
  DEFINE l_tot_recs, x, i INTEGER
  DEFINE l_tok base.StringTokenizer
  DEFINE l_col_titles DYNAMIC ARRAY OF STRING
  DEFINE l_fields DYNAMIC ARRAY OF RECORD
    name STRING,
    type STRING
  END RECORD
  DEFINE l_sel_stmt STRING
  DEFINE l_ret_key STRING
  DEFINE l_sql_handle base.SqlHandle
  DEFINE l_dlg ui.Dialog
  DEFINE l_event STRING

-- See "genero_lib.inc" for Macro definitions.

  GL_DBGMSG(2, "g2_lookup: table(s)=" || tabnam)
  GL_DBGMSG(2, "g2_lookup: cols		=" || cols)
  GL_DBGMSG(2, "g2_lookup: l_titles	=" || colts)
  GL_DBGMSG(2, "g2_lookup: where	 =" || wher)
  GL_DBGMSG(2, "g2_lookup: orderby =" || ordby)
  GL_DBGMSG(2, "g2_lookup: Declaring Count Cursor...")

-- Check to make sure there are records.
  TRY
    LET l_sel_stmt = "SELECT COUNT(*) FROM " || tabnam || " WHERE " || wher
    PREPARE listcntpre FROM l_sel_stmt
  CATCH
    CALL g2_lib.g2_errPopup(SFMT(% "Failed to prepare:\n%1\n%2", l_sel_stmt, SQLERRMESSAGE))
    RETURN NULL --, NULL
  END TRY
-- do the count
  DECLARE listcntcur CURSOR FOR listcntpre
  OPEN listcntcur
  FETCH listcntcur INTO l_tot_recs
  CLOSE listcntcur
  IF l_tot_recs < 1 THEN
    CALL g2_lib.g2_errPopup(% "No Records Found")
    RETURN NULL
  END IF
  GL_DBGMSG(2, "g2_lookup: Counted:" || l_tot_recs)

-- Prepare/Declare main cursor
  LET l_sel_stmt = "SELECT " || cols CLIPPED || " FROM " || tabnam CLIPPED, " WHERE " || wher
  IF ordby IS NOT NULL THEN
    LET l_sel_stmt = l_sel_stmt CLIPPED, " ORDER BY " || ordby
  END IF

-- Version 3.00 feature.
  LET l_sql_handle = base.SqlHandle.create()
  TRY
    CALL l_sql_handle.prepare(l_sel_stmt)
    CALL l_sql_handle.openScrollCursor()
  CATCH
    CALL g2_lib.g2_errPopup(SFMT(% "Failed to prepare:\n%1\n%2", l_sel_stmt, SQLERRMESSAGE))
    RETURN NULL
  END TRY
  CALL l_fields.clear()
  FOR x = 1 TO l_sql_handle.getResultCount()
    LET l_fields[x].name = l_sql_handle.getResultName(x)
    LET l_col_titles[x] = l_fields[x].name -- default column l_titles
    LET l_fields[x].type = l_sql_handle.getResultType(x)
    GL_DBGMSG(2, "g2_lookup:" || i || " Name:" || l_fields[x].name || " Type:" || l_fields[x].type)
  END FOR
  GL_DBGMSG(2, "g2_lookup: Cursor Okay.")

-- Open the window and define a table.
  GL_DBGMSG(2, "g2_lookup: Opening Window.")
  OPEN WINDOW listv AT 1, 1 WITH 20 ROWS, 80 COLUMNS ATTRIBUTE(STYLE = "naked")
  CALL fgl_setTitle("Listing from " || tabnam)
  LET l_frm =
      g2_aui.g2_genForm("gl_" || tabnam.trim()) -- ensures form name is specific for this lookup

  LET l_grid = l_frm.createChild('Grid')
-- Create a centered window l_title.
  LET l_hbx = l_grid.createChild('HBox')
  CALL l_hbx.setAttribute("posY", "0")
  LET l_sp = l_hbx.createChild('SpacerItem')
  LET l_titl = l_hbx.createChild('Label')
  CALL l_titl.setAttribute("text", "Listing from " || tabnam CLIPPED)
  CALL l_titl.setAttribute("style", "tabtitl")
  LET l_sp = l_hbx.createChild('SpacerItem')

  GL_DBGMSG(2, "g2_lookup: Generating Table...")
-- Create the table
  LET l_tabl = l_grid.createChild('Table')
  CALL l_tabl.setAttribute("tabName", "tablistv")
  CALL l_tabl.setAttribute("height", "20")
  CALL l_tabl.setAttribute("pageSize", "20")
  CALL l_tabl.setAttribute("posY", "1")

-- Setup column l_titles if supplied.
  IF colts IS NOT NULL THEN
    LET l_tok = base.StringTokenizer.create(colts, ",")
    CALL l_col_titles.clear() -- clear the defaults if l_title supplied.
    WHILE l_tok.hasMoreTokens()
      LET l_col_titles[l_col_titles.getLength() + 1] = l_tok.nextToken()
    END WHILE
  END IF

-- Create Columns & Headings for the table.
  FOR x = 1 TO l_fields.getLength()
    LET l_tabc = l_tabl.createChild('TableColumn')
    CALL l_tabc.setAttribute("colName", l_fields[x].name)
    LET l_edit = l_tabc.createChild('Edit')
    CALL l_tabc.setAttribute("text", l_col_titles[x])
    CALL l_edit.setAttribute("width", gl_lookup_getSize(l_fields[x].type))
    IF l_col_titles[x].getCharAt(1) = "_" THEN -- if l_title starts with _ then it's a hidden column
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
  CALL l_titl.setAttribute("text", l_tot_recs USING "###,###,##&" || " Rows")
  CALL l_titl.setAttribute("sizePolicy", "dynamic")

-- Setup the dialog
  LET int_flag = FALSE
  LET l_dlg = ui.Dialog.createDisplayArrayTo(l_fields, "tablistv")
  CALL l_dlg.addTrigger("ON ACTION close")
  CALL l_dlg.addTrigger("ON ACTION accept")
  CALL l_dlg.addTrigger("ON ACTION cancel")

-- Fetch the data
  CALL l_sql_handle.fetchFirst()
  LET x = 0
  WHILE SQLCA.sqlcode = 0
    LET x = x + 1
    CALL l_dlg.setCurrentRow("tablistv", x) -- must set the current row before setting values
    FOR i = 1 TO l_sql_handle.getResultCount()
      CALL l_dlg.setFieldValue(l_sql_handle.getResultName(i), l_sql_handle.getResultValue(i))
    END FOR
    CALL l_sql_handle.fetch()
  END WHILE
  CALL l_sql_handle.close()
  CALL l_dlg.setCurrentRow("tablistv", 1) -- TODO: should be done by the runtime
-- Loop for events.
  WHILE TRUE
    LET l_event = l_dlg.nextEvent()
    CASE l_event
      WHEN "BEFORE DISPLAY"
        IF l_tot_recs = 1 THEN
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
  LET l_ret_key = l_dlg.getFieldValue(l_fields[1].name) -- get the selected row first field.
  LET l_dlg = NULL -- FIXME: CALL l_dlg.terminate()

  CLOSE WINDOW listv
  IF int_flag THEN
    GL_DBGMSG(2, "g2_lookup: Window Closed, Cancelled.")
    RETURN NULL
  ELSE
    GL_DBGMSG(2, SFMT("g2_lookup: Window Closed, returning row:%1 %2", arr_curr(), l_ret_key))
    RETURN l_ret_key.trim()
  END IF

END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Get the size for the table column from the type passed
#+
#+ @param l_type String type of field
#+ @returns smallint size of field
FUNCTION gl_lookup_getSize(l_type STRING) RETURNS SMALLINT
  DEFINE l_size SMALLINT
  DEFINE x, y SMALLINT

  CASE l_type
    WHEN "SMALLINT"
      LET l_size = 5
    WHEN "SERIAL"
      LET l_size = 10
    WHEN "INTEGER"
      LET l_size = 10
    WHEN "FLOAT"
      LET l_size = 12
    WHEN "DATE"
      LET l_size = 10
    OTHERWISE
      LET l_size = 5
  END CASE

  LET x = l_type.getIndexOf("(", 1)
  IF x > 1 THEN
    LET y = l_type.getIndexOf(",", 1)
    IF y = 0 THEN
      LET y = l_type.getIndexOf(")", 1)
    END IF
    LET l_size = l_type.subString(x + 1, y - 1)
  END IF
  IF l_size > MAXCOLWIDTH THEN
    LET l_size = MAXCOLWIDTH
  END IF -- shrink big fields to MAXCOLWIDTH
  RETURN l_size
END FUNCTION --}}}
--------------------------------------------------------------------------------
