IMPORT FGL g2_merge4st

MAIN
	DISPLAY "FGLRESOURCEPATH: ", fgl_getenv("FGLRESOURCEPATH")
	CALL g2_merge4st.g2_merge4st("test.4st")

	MENU "Test"
		COMMAND "Quit"
			EXIT MENU
		ON ACTION close
			EXIT MENU
	END MENU

END MAIN
