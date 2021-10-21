--------------------------------------------------------------------------------
#+ Genero Genero Library Functions - by Neil J Martin ( neilm@4js.com )
#+ This library is intended as an example of useful library code for use with
#+ Genero 4.00 and above
#+  
#+ No warrantee of any kind, express or implied, is included with this software;
#+ use at your own risk, responsibility for damages (if any) to anyone resulting
#+ from the use of this software rests entirely with the user.
#+  
<<<<<<< HEAD:g2_lib/g2_getFileName.4gl
#+ No includes required.

PACKAGE g2_lib

IMPORT os
IMPORT FGL g2_lib.*
=======
#+ No includes required

IMPORT os
IMPORT FGL g2_core
IMPORT FGL g2_simpleLookup
>>>>>>> origin/master:src/g2_getFileName.4gl
--------------------------------------------------------------------------------------------------------------
-- Do a simple list of files and return selected name
--
-- @param l_folder Folder to get files from
-- @param l_ext file Extension matches
-- @param l_titl window title
-- @param l_head table column heading
-- @returns filename ( without extension ) or null
FUNCTION g2_getFileName(l_folder STRING, l_ext STRING, l_titl STRING, l_head STRING) RETURNS STRING
	DEFINE l_fname, l_path STRING
	DEFINE d INT
	DEFINE sl g2_simpleLookup.simpleLookup
	CALL os.Path.dirSort("name", 1)
	LET d = os.Path.dirOpen(l_folder)
	IF d > 0 THEN
		WHILE TRUE
			LET l_path = os.Path.dirNext(d)
			IF l_path IS NULL THEN EXIT WHILE END IF
			IF os.Path.isDirectory(l_path) THEN CONTINUE WHILE END IF
			IF NOT os.Path.extension(l_path) MATCHES l_ext THEN CONTINUE WHILE END IF
			LET sl.arr[ sl.arr.getLength() + 1 ].desc = os.Path.rootName( l_path )
		END WHILE
	END IF
	IF sl.arr.getLength() = 0 THEN
		CALL g2_core.g2_winMessage("Error",SFMT("No '%1' files found in %2",l_ext,l_folder),"exclamation")
		RETURN NULL
	END IF
	LET sl.title = l_titl
	LET sl.keyTitle = "_"
	LET sl.descTitle = l_head
	LET l_fname = sl.g2_simpleLookup()
	RETURN l_fname
END FUNCTION
