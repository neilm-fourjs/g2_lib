PACKAGE g2_lib
IMPORT os
FUNCTION g2_merge4st(l_file STRING)
	DEFINE l_sl, l_old_s, l_new_s om.DomNode
	DEFINE l_new                  om.DomDocument
	DEFINE l_old_sl, l_new_sl     om.NodeList
	DEFINE l_new_sal              om.NodeList
	DEFINE l_new_sa               om.DomNode
	DEFINE x, y                   SMALLINT
	DEFINE l_nam, l_val           STRING
	DEFINE l_resource_path        STRING
	LET l_resource_path = fgl_getenv("FGLRESOURCEPATH")
	LET x = l_resource_path.getIndexOf(":",1)
-- hope location of 4st is in the first path in FGLRESOURCEPATH!
	IF x > 0 THEN LET l_resource_path = l_resource_path.subString(1,x-1) END IF
	LET l_file = os.Path.join(l_resource_path, l_file)
	IF NOT os.Path.exists(l_file) THEN
		DISPLAY SFMT("g2_merge4st: can't find '%1'!", l_file)
		RETURN
	END IF
	TRY
		LET l_new = om.DomDocument.createFromXmlFile(l_file)
	CATCH
		DISPLAY SFMT("g2_merge4st: failed to load '%1'!", l_file)
		RETURN
	END TRY
	TRY
		LET l_sl = ui.Interface.getRootNode().selectByTagName("StyleList").item(1)
	CATCH
		-- shouldn't happen!
	END TRY
	IF l_sl IS NULL THEN
		-- shouldn't happen!
		DISPLAY "g2_merge4st: can't find 'StyleList'!"
		RETURN
	END IF

	LET l_new_sl = l_new.getDocumentElement().selectByTagName("Style")
	IF l_new_sl.getLength() = 0 THEN
		DISPLAY SFMT("g2_merge4st: no styles in '%1'!", l_file)
		RETURN
	END IF

	FOR x = 1 TO l_new_sl.getLength()
		LET l_new_s   = l_new_sl.item(x)
		LET l_nam     = l_new_s.getAttribute("name")
		LET l_new_sal = l_new_s.selectByTagName("StyleAttribute")
		IF l_new_sal.getLength() = 0 THEN
			CONTINUE FOR
		END IF

		LET l_old_sl = l_sl.selectByPath(SFMT("//Style[@name='%1']", l_nam))
		IF l_old_sl.getLength() = 0 THEN
			LET l_old_s = l_sl.createChild("Style")
			CALL l_old_s.setAttribute("name", l_nam)
		ELSE
			LET l_old_s = l_old_sl.item(1)
		END IF
		FOR y = 1 TO l_new_sal.getLength()
			LET l_nam = l_new_sal.item(y).getAttribute("name")
			LET l_val = l_new_sal.item(y).getAttribute("value")
			LET l_new_sa = l_old_s.createChild("StyleAttribute")
			CALL l_new_sa.setAttribute("name", l_nam)
			CALL l_new_sa.setAttribute("value", l_val)
		END FOR
	END FOR

END FUNCTION
