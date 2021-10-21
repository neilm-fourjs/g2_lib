#+ Genero 4.00 and above
#+
#+ No warrantee of any kind, express or implied, is included with this software;
#+ use at your own risk, responsibility for damages (if any) to anyone resulting
#+ from the use of this software rests entirely with the user.
#+
#+ No includes required.

PACKAGE g2_lib

IMPORT util
IMPORT os

--------------------------------------------------------------------------------
#+ Get the product version from the $FGLDIR/etc/fpi-fgl
#+ @param l_prod String of product name, eg: fglrun
#+ @return String or NULL
FUNCTION g2_getProductVer(l_prod STRING) RETURNS STRING
	DEFINE l_file base.Channel
	DEFINE l_line STRING
	LET l_file = base.Channel.create()
	CALL l_file.openPipe("fpi -l", "r")
	WHILE NOT l_file.isEof()
		LET l_line = l_file.readLine()
		IF l_line.getIndexOf(l_prod, 1) > 0 THEN
			LET l_line = l_line.subString(8, l_line.getLength() - 1)
			EXIT WHILE
		END IF
	END WHILE
	CALL l_file.close()
	RETURN l_line
END FUNCTION
--------------------------------------------------------------------------------
#+ Attempt to convert a String to a date
#+
#+ @param l_str A string containing a date
#+ @returns DATE or NULL
FUNCTION g2_strToDate(l_str STRING) RETURNS DATE
	DEFINE l_date DATE
	TRY
		LET l_date = l_str
	CATCH
	END TRY
	IF l_date IS NOT NULL THEN
		RETURN l_date
	END IF
	LET l_date = util.Date.parse(l_str, "dd/mm/yyyy")
	RETURN l_date
END FUNCTION
--------------------------------------------------------------------------------
#+ Return the result from the hostname commend on Unix / Linux / Mac.
#+
#+ @return uname of the OS
FUNCTION g2_getHostname() RETURNS STRING
	DEFINE l_hostname STRING
	DEFINE c base.Channel
	IF os.Path.pathSeparator() = ";" THEN -- Windows
		LET l_hostname = fgl_getenv("COMPUTERNAME")
	ELSE -- Unix / Linux<builtin>.fgl_getenvndroid
		LET l_hostname = fgl_getenv("HOSTNAME")
	END IF
	IF l_hostname.getLength() < 2 THEN
		LET c = base.Channel.create()
		CALL c.openPipe("hostname -f", "r")
		LET l_hostname = c.readLine()
		CALL c.close()
	END IF
	RETURN l_hostname
END FUNCTION
--------------------------------------------------------------------------------
#+ Return the result from the uname commend on Unix / Linux / Mac.
#+
#+ @return uname of the OS
FUNCTION g2_getUname() RETURNS STRING
	DEFINE l_uname STRING
	DEFINE c base.Channel
	LET c = base.Channel.create()
	CALL c.openPipe("uname", "r")
	LET l_uname = c.readLine()
	CALL c.close()
	RETURN l_uname
END FUNCTION
--------------------------------------------------------------------------------
#+ Return the Linux Version
#+
#+ @return OS Version
FUNCTION g2_getLinuxVer() RETURNS STRING
	DEFINE l_ver STRING
	DEFINE c base.Channel
	DEFINE l_file DYNAMIC ARRAY OF STRING
	DEFINE x SMALLINT

-- possible files containing version info
	LET l_file[l_file.getLength() + 1] = "/etc/redhat-release"
	LET l_file[l_file.getLength() + 1] = "/etc/issue.net"
	LET l_file[l_file.getLength() + 1] = "/etc/issue"
	LET l_file[l_file.getLength() + 1] = "/etc/debian_version"
	LET l_file[l_file.getLength() + 1] = "/etc/SuSE-release"

-- loop thru and see which ones exist
	FOR x = 1 TO l_file.getLength() + 1
		IF l_file[x] IS NULL THEN
			RETURN "Unknown"
		END IF
		IF os.Path.exists(l_file[x]) THEN
			EXIT FOR
		END IF
	END FOR

-- read the first line of existing file
	LET c = base.Channel.create()
	CALL c.openFile(l_file[x], "r")
	LET l_ver = c.readLine()
	CALL c.close()
	RETURN l_ver
END FUNCTION