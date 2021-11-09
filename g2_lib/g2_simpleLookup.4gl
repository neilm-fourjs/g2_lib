--------------------------------------------------------------------------------
#+ Genero Genero Library Functions - by Neil J Martin ( neilm@4js.com )
#+
#+ A Simple dynamic lookup function
#+
#+ This library is intended as an example of useful library code for use with
#+ Genero 4.00 and above
#+  
#+ No warrantee of any kind, express or implied, is included with this software;
#+ use at your own risk, responsibility for damages (if any) to anyone resulting
#+ from the use of this software rests entirely with the user.
#+  
#+ No includes required.

PACKAGE g2_lib

--IMPORT FGL g2_lib.* -- fails in GST
IMPORT FGL g2_lib.g2_debug
IMPORT FGL g2_lib.g2_aui

&include "g2_debug.inc"
PUBLIC TYPE simpleLookup RECORD
		name STRING,
		title STRING,
		keyTitle STRING,
		descTitle STRING,
		arr DYNAMIC ARRAY OF RECORD
			key STRING,
			desc STRING
		END RECORD
	END RECORD

PUBLIC FUNCTION (this simpleLookup) g2_simpleLookup() RETURNS STRING
	DEFINE l_frm, l_grid, l_tabl, l_tabc, l_edit om.DomNode
	DEFINE l_hbx om.DomNode
	DEFINE l_ret STRING

	GL_DBGMSG(2, "g2_lookup: Opening Window.")
	OPEN WINDOW simplelookup AT 1, 1 WITH 20 ROWS, 80 COLUMNS ATTRIBUTE(STYLE = "naked")
	CALL fgl_settitle(this.title)
	LET l_frm =
			g2_aui.g2_genForm("g2_" || this.name.trim()) -- ensures form name is specific for this lookup
	CALL l_frm.setAttribute("style","naked")
	LET l_grid = l_frm.createChild('Grid')
-- Create a centered window l_title.
	LET l_hbx = l_grid.createChild('HBox')
	CALL l_hbx.setAttribute("posY", "0")

	GL_DBGMSG(2, "g2_simpleLookup: Generating Table...")
-- Create the table
	LET l_tabl = l_grid.createChild('Table')
	CALL l_tabl.setAttribute("tabName", "slookup")
	CALL l_tabl.setAttribute("height", "20")
	CALL l_tabl.setAttribute("pageSize", "20")
	CALL l_tabl.setAttribute("posY", "1")
	CALL l_tabl.setAttribute("doubleClick", "accept")

-- Create Columns & Headings for the table.
	LET l_tabc = l_tabl.createChild('TableColumn')
	CALL l_tabc.setAttribute("colName", "key")
	LET l_edit = l_tabc.createChild('Edit')
	CALL l_tabc.setAttribute("text", this.keyTitle)
	CALL l_edit.setAttribute("width", 6)
	IF this.keyTitle.getCharAt(1) = "_" THEN -- if l_title starts with _ then it's a hidden column
		CALL l_tabc.setAttribute("hidden", "1")
	END IF
	LET l_tabc = l_tabl.createChild('TableColumn')
	CALL l_tabc.setAttribute("colName", "desc")
	LET l_edit = l_tabc.createChild('Edit')
	CALL l_tabc.setAttribute("text", this.descTitle)
	CALL l_edit.setAttribute("width", 40)
	IF this.descTitle.getCharAt(1) = "_" THEN -- if l_title starts with _ then it's a hidden column
		CALL l_tabc.setAttribute("hidden", "1")
	END IF

	LET int_flag = FALSE
	DISPLAY ARRAY this.arr TO slookup.*

	CLOSE WINDOW simplelookup
	IF int_flag THEN
		LET int_flag = FALSE
	ELSE
		IF this.keyTitle.getCharAt(1) = "_" THEN
			LET l_ret = this.arr[ arr_curr() ].desc
		ELSE
			LET l_ret = this.arr[ arr_curr() ].key
		END IF
	END IF
	RETURN l_ret

END FUNCTION
