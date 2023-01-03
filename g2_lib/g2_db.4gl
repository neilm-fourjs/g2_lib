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
IMPORT FGL g2_encrypt
&else
PACKAGE g2_lib
--IMPORT FGL g2_lib.*
IMPORT FGL g2_lib.g2_core
IMPORT FGL g2_lib.g2_debug
IMPORT FGL g2_lib.g2_encrypt
IMPORT reflect
&endif

IMPORT os
IMPORT util

&include "g2_debug.inc"

&ifdef gen320
CONSTANT  C_CUSTOM_DB_FILE = "custom_db_enc.json"
&else
CONSTANT C_CUSTOM_DB_FILE = "custom_db_enc4.json"
&endif
# Informix
CONSTANT DEF_DBDRIVER = "dbmifx9x"
CONSTANT DEF_DBSPACE  = "dbs1"

# SQLServer
#CONSTANT DEF_DBDRIVER="dbmsnc90"

# MySQL
#CONSTANT DEF_DBDRIVER="dbmmys51x"

# SQLite
#CONSTANT DEF_DBDRIVER="dbmsqt3xx"
CONSTANT DEF_DBDIR = "../db"

PUBLIC TYPE dbInfo RECORD
	name        STRING,
	type        STRING,
	desc        STRING,
	source      STRING,
	driver      STRING,
	dir         STRING,
	dbspace     STRING,
	connection  STRING,
	db_user     STRING,
	db_passwd   STRING,
	create_db   BOOLEAN,
	serial_emu  STRING,
	serial_errd BOOLEAN,
	use_custom  BOOLEAN,
	db_cfg      STRING
END RECORD

PUBLIC DEFINE m_db dbInfo --should be used instead of defining this in the call module.

FUNCTION (this dbInfo) g2_connect(l_dbName STRING) RETURNS()
	DEFINE l_msg                              STRING
	DEFINE l_lockMode, l_fglprofile, l_failed BOOLEAN

	LET this.use_custom = FALSE
	LET this.db_cfg     = "local"

-- setup stuff from environment or defaults
	IF l_dbName IS NULL OR l_dbName = " " THEN
		LET l_dbName = fgl_getenv("DBNAME") -- also see getCustomDBUser() !!
	END IF
	LET this.name   = l_dbName
	LET this.source = NULL
	IF this.dir IS NULL OR this.dir = " " THEN
		LET this.dir = DEF_DBDIR
	END IF

	IF this.dbspace IS NULL THEN
		LET this.dbspace = fgl_getenv("DBSPACE")
	END IF
	IF this.dbspace IS NULL OR this.dbspace = " " THEN
		LET this.dbspace = DEF_DBSPACE
	END IF

	IF this.driver IS NULL THEN
		IF this.type IS NOT NULL THEN
			LET this.driver = "dbm" || this.type
		END IF
	END IF
	IF this.driver IS NULL THEN
		LET this.driver = fgl_getenv("DBDRIVER")
	END IF
	IF this.driver IS NULL OR this.driver = " " THEN
		LET this.driver = DEF_DBDRIVER
	END IF

-- setup stuff from fglprofile
	LET l_msg = fgl_getresource("dbi.database." || this.name || ".source")
	IF l_msg IS NOT NULL AND l_msg != " " THEN
		LET this.source  = l_msg
		LET l_fglprofile = TRUE
		LET this.db_cfg  = SFMT("FglProfile: %1", fgl_getEnv("FGLPROFILE"))
	END IF
	LET l_msg = fgl_getresource("dbi.database." || this.name || ".driver")
	IF l_msg IS NULL OR l_msg = " " THEN
		LET l_msg = fgl_getresource("dbi.default.driver")
	END IF
	IF l_msg IS NOT NULL AND l_msg != " " THEN
		LET this.driver = l_msg
	END IF
	LET this.type = this.driver.subString(4, 6)

	LET this.serial_emu  = fgl_getresource("dbi.database." || this.name || ".ifxemul.datatype.serial.emulation")
	LET this.serial_errd = fgl_getresource("dbi.database." || this.name || ".ifxemul.datatype.serial.sqlerrd2")

	LET this.connection = this.name

	CALL this.g2_getCustomDBInfo()
	GL_DBGMSG(0, SFMT("Database: %1 Driver: %2 Type: %3 Source: %4 CFG: %5 Serial Emu: %6 Errd: %7", this.name, this.driver, this.type, this.source, this.db_cfg, this.serial_emu, this.serial_errd))

	IF NOT this.use_custom THEN
		CASE this.type
			WHEN "pgs"
				IF this.source IS NOT NULL THEN
					LET this.connection = SFMT("%1+driver='%2',source='%3'", this.name, this.driver, this.source)
				END IF
			WHEN "ifx"
				LET this.source     = fgl_getenv("INFORMIXSERVER")
				LET this.connection = this.name
				DISPLAY "INFORMIXDIR:", fgl_getenv("INFORMIXDIR")
				DISPLAY "INFORMIXSERVER:", fgl_getenv("INFORMIXSERVER")
				DISPLAY "INFORMIXSQLHOSTS:", fgl_getenv("INFORMIXSQLHOSTS")
			WHEN "sqt"
				IF NOT os.Path.exists(this.dir) THEN
					IF NOT os.Path.mkdir(this.dir) THEN
						CALL g2_core.g2_winMessage(
								"Error", SFMT("Failed to create dbdir '%1' !\n%2", this.dir, err_get(status)), "exclamation")
					END IF
				END IF
				LET this.source = fgl_getenv("SQLITEDB")
				IF this.source IS NULL OR this.source = " " THEN
					LET this.source = this.dir || "/" || this.name || ".db"
				END IF
				IF NOT os.Path.exists(this.source) THEN
					CALL g2_core.g2_winMessage("Error", SFMT("Database file is missing? '%1' !\n", this.source), "exclamation")
				ELSE
					DISPLAY "Database file exists:", this.source
				END IF
				LET this.connection = SFMT("%1+driver='%2',source='%3'", this.name, this.driver, this.source)
		END CASE
	END IF

	LET l_lockMode = FALSE
	LET this.desc  = SFMT("%1 %2", this.type, this.driver)
	CASE this.type
		WHEN "ifx"
			LET l_lockMode = TRUE
			LET this.desc  = SFMT("Informix %1", this.driver)
		WHEN "msc"
			LET l_lockMode = TRUE
		WHEN "sqt"
			LET this.desc = SFMT("SQLite %1", this.driver)
		WHEN "pgs"
			LET this.desc = SFMT("PostgreSQL %1", this.driver)
		WHEN "mys"
			LET this.desc = SFMT("MySQL %1", this.driver)
		WHEN "mdb"
			LET this.desc = SFMT("MariaDB %1", this.driver)
		WHEN "snc"
			LET this.desc = SFMT("SQL Server %1", this.driver)
		WHEN "odb"
			LET this.desc = SFMT("ODBC %1", this.driver)
	END CASE

	LET l_failed = FALSE
	TRY
		IF this.db_user IS NULL THEN
			GL_DBGMSG(0, SFMT("Connection: %1 Using: %2 Source: %3 ...", this.connection, this.driver, this.source))
			DATABASE this.connection
		ELSE
			GL_DBGMSG(0, SFMT("Connection: %1 As: %2 ...", this.connection, this.db_user))
			CONNECT TO this.connection USER this.db_user USING this.db_passwd
		END IF
		GL_DBGMSG(0, "Connected.")
	CATCH
		LET l_failed = TRUE
	END TRY
	IF l_failed THEN
		LET l_msg =
				"Connection to database failed\nDB:", this.name, "\nSource:", this.source, "\nDriver:", this.driver, "\n",
				"Status:", sqlca.sqlcode, "\n", SQLERRMESSAGE
		DISPLAY l_msg
		IF this.create_db AND sqlca.sqlcode = -329 AND this.type = "ifx" THEN
			CALL this.g2_ifx_createdb()
			LET l_msg = NULL
		END IF
		IF this.create_db AND sqlca.sqlcode = -6372 AND (this.type = "mdb" OR this.type = "mys") THEN
			CALL this.g2_mdb_createdb()
			LET l_msg = NULL
		END IF
		IF this.create_db AND sqlca.sqlcode = -6372 AND this.type = "sqt" THEN
			CALL this.g2_sqt_createdb(this.dir, this.source)
			LET l_msg = NULL
		END IF
		IF sqlca.sqlcode = -6366 THEN
			RUN "echo $LD_LIBRARY_PATH;ldd $FGLDIR/dbdrivers/" || this.driver || ".so"
		END IF
		IF l_msg IS NOT NULL THEN
			CALL g2_core.g2_errPopup(SFMT(%"Fatal Error %1", l_msg))
			CALL g2_core.g2_exitProgram(1, l_msg)
		END IF
	END IF

	IF l_lockMode THEN
		SET LOCK MODE TO WAIT 3
	END IF

	CALL fgl_setenv("DBCON", this.name)

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION (this dbInfo) g2_getType() RETURNS STRING
	DEFINE drv STRING
	IF this.type IS NULL THEN
		LET drv = fgl_getenv("DBDRIVER")
		IF drv IS NULL OR drv = " " THEN
			LET drv = DEF_DBDRIVER
		END IF
		LET this.type = drv.subString(4, 6)
	END IF
	RETURN this.type
END FUNCTION
--------------------------------------------------------------------------------
-- create file and folder for the empty sqlite db and then call the db_connect again
FUNCTION (this dbInfo) g2_sqt_createdb(l_dir STRING, l_file STRING) RETURNS()
	DEFINE c base.Channel
	LET c = base.Channel.create()
	IF NOT os.Path.exists(l_dir) THEN
		IF NOT os.Path.mkdir(l_dir) THEN
			CALL g2_core.g2_exitProgram(status, SFMT("DB Folder Creation Failed for: %1", l_dir))
		END IF
	END IF
	CALL c.openFile(l_file, "w")
	CALL c.close()
	LET this.create_db = FALSE -- avoid infintate loop!
	CALL this.g2_connect(this.name)
END FUNCTION
--------------------------------------------------------------------------------
-- create file and folder for the empty sqlite db and then call the db_connect again
FUNCTION (this dbInfo) g2_mdb_createdb() RETURNS()
	DEFINE l_sql_stmt STRING
	LET l_sql_stmt = "CREATE DATABASE " || this.name || " default character set utf8mb4 collate utf8mb4_unicode_ci"
	TRY
		EXECUTE IMMEDIATE l_sql_stmt
	CATCH
		IF NOT g2_sqlStatus(__LINE__, "gl_db", l_sql_stmt) THEN
			CALL g2_core.g2_exitProgram(status, "DB Creation Failed!")
		END IF
	END TRY
	LET this.create_db = FALSE -- avoid in
END FUNCTION
--------------------------------------------------------------------------------
-- create a new informix database and then call the db_connect again
FUNCTION (this dbInfo) g2_ifx_createdb() RETURNS()
	DEFINE l_sql_stmt STRING
	LET l_sql_stmt = "CREATE DATABASE " || this.name || " IN " || this.dbspace
	TRY
		EXECUTE IMMEDIATE l_sql_stmt
	CATCH
		IF NOT g2_sqlStatus(__LINE__, "gl_db", l_sql_stmt) THEN
			CALL g2_core.g2_exitProgram(status, "DB Creation Failed!")
		END IF
	END TRY
	LET this.create_db = FALSE -- avoid infintate loop!
	CALL this.g2_connect(this.name)
END FUNCTION
--------------------------------------------------------------------------------
-- Attempt to create a table based on a record
FUNCTION (this dbInfo) g2_createTable(l_rec reflect.Value, l_nam STRING, l_priKey STRING, l_extra STRING)
		RETURNS BOOLEAN
	DEFINE l_typ        reflect.Type
	DEFINE l_fld        reflect.Type
	DEFINE l_fldType    STRING
	DEFINE i            SMALLINT
	DEFINE l_at1, l_at2 STRING
	DEFINE l_sql        STRING
	LET l_typ = l_rec.getType()
	LET l_sql = SFMT("CREATE TABLE %1 (", l_nam)
	FOR i = 1 TO l_typ.getFieldCount()
		LET l_fld     = l_typ.getFieldType(i)
		LET l_fldType = l_fld.toString()
		IF l_fld.hasAttribute("xmltype") THEN
			LET l_fldType = l_fld.getAttribute("xmltype")
			IF l_fldType = "SERIAL" THEN
				LET l_priKey = l_typ.getFieldName(i)
			END IF
		END IF
		LET l_at1 = NULL
		LET l_at2 = NULL
		IF NOT l_fld.hasAttribute("xmlnillable") THEN
			LET l_at1 = " NOT NULL"
		END IF
		LET l_sql = l_sql.append(SFMT(" %1 %2 %3 %4", l_typ.getFieldName(i), l_fldType, l_at1, l_at2))
		IF i < l_typ.getFieldCount() THEN
			LET l_sql = l_sql.trim().append(",")
		ELSE
		END IF
	END FOR
	IF l_priKey IS NOT NULL THEN
		LET l_sql = l_sql.trim().append(SFMT(", PRIMARY KEY( %1 )", l_priKey))
	END IF
	IF l_extra IS NOT NULL THEN
		LET l_sql = l_sql.trim().append(SFMT(", %1", l_extra))
	END IF
	LET l_sql = l_sql.trim().append(" );")
	TRY
		EXECUTE IMMEDIATE l_sql
	CATCH
		IF NOT g2_sqlStatus(__LINE__, "gl_db", l_sql) THEN
		END IF
		RETURN FALSE
	END TRY
	GL_DBGMSG(0, SFMT("g2_createTable: %1 - Using: %2", l_nam, l_sql))
	{IF l_priKey IS NOT NULL THEN
		CALL this.g2_addPrimaryKey(l_nam, l_priKey, TRUE)
	END IF}
	RETURN TRUE
END FUNCTION
--------------------------------------------------------------------------------
#+ Add a primary key to a table
#+
#+ @param l_tab Table name
#+ @param l_col Column(s)
#+ @param l_isSerial Serials are primary key by default in MySQL
FUNCTION (this dbInfo) g2_addPrimaryKey(l_tab STRING, l_col STRING, l_isSerial BOOLEAN) RETURNS()
	DEFINE l_sql_stmt STRING
	DEFINE l_cmd      STRING
	IF this.type = "sqt" THEN
		RETURN
	END IF -- can't add pk to sqlite!!
	IF l_isSerial AND (this.type = "mys" OR this.type = "mdb") THEN
		RETURN
	END IF -- can't add pk for serial column in MySQL or MariaDB
	LET l_cmd = "PRIMARY KEY"
	IF this.type = "ifx" THEN
		LET l_cmd = "CONSTRAINT UNIQUE"
	END IF
	LET l_sql_stmt = SFMT("ALTER TABLE %1 ADD %2 (%3)", l_tab, l_cmd, l_col)
	GL_DBGMSG(0, SFMT("g2_addPrimaryKey: %1 - %2: %3", l_tab, l_col, l_sql_stmt))
	TRY
		EXECUTE IMMEDIATE l_sql_stmt
	CATCH
		IF NOT g2_sqlStatus(__LINE__, "gl_db", l_sql_stmt) THEN
		END IF
	END TRY
END FUNCTION
--------------------------------------------------------------------------------
#+ Show Information for a Failed Connections. Debug.
#+
#+ @param stat Status
#+ @param dbname Database Name
FUNCTION (this dbInfo) g2_showInfo(stat INTEGER) RETURNS()

	OPEN WINDOW info WITH FORM "g2_dbinfo"

	DISPLAY "FGLDIR" TO lab1
	DISPLAY fgl_getenv("FGLDIR") TO fld1
	DISPLAY "FGLASDIR" TO lab2
	DISPLAY fgl_getenv("FGLASDIR") TO fld2
	DISPLAY "FGLPROFILE" TO lab3
	DISPLAY fgl_getenv("FGLPROFILE") TO fld3
	DISPLAY "DBNAME" TO lab4
	DISPLAY this.name TO fld4
	DISPLAY "dbi.database." || this.name || ".source" TO lab5
	DISPLAY this.source TO fld5

	DISPLAY "dbi.database." || this.name || ".driver" TO lab6
	DISPLAY this.driver TO fld6

	IF this.type IS NULL THEN
		DISPLAY "No driver in FGLPROFILE!!!" TO lab7
	ELSE
		DISPLAY "dbi.database." || this.name || "." || this.type || ".schema" TO lab7
	END IF
	DISPLAY fgl_getresource("dbi.database." || this.name || "." || this.type || ".schema") TO fld7

	DISPLAY "dbsrc" TO lab8
	DISPLAY this.source TO fld8

	DISPLAY "dbconn" TO lab9
	DISPLAY this.connection TO fld9

	DISPLAY "DBPATH" TO lab10
	DISPLAY fgl_getenv("DBPATH") TO fld10

	DISPLAY "LD_LIBRARY_PATH" TO lab11
	DISPLAY fgl_getenv("LD_LIBRARY_PATH") TO fld11

	DISPLAY "status" TO lab13
	DISPLAY stat TO fld13
	DISPLAY "SQLSTATE" TO lab14
	DISPLAY SQLSTATE TO fld14
	DISPLAY "SQLERRMESSAGE" TO lab15
	DISPLAY SQLERRMESSAGE TO fld15

	MENU "Info"
		ON ACTION exit
			EXIT MENU
		ON ACTION close
			EXIT MENU
	END MENU

	CLOSE WINDOW info
END FUNCTION
--------------------------------------------------------------------------------
-- Get custom dbname and user from a json file outside of the deployment
-- eg:
{
  "name": "pitestdb",
  "type": "pgs",
  "driver": "dbmpgs",
  "source": "pitestdb@pi3",
  "username": "testuser",
  "password": "12testuser",
  "connection": "pitestdb+driver='dbmpgs',source='pitestdb@pi3'"
}

FUNCTION (this dbInfo) g2_getCustomDBInfo()
	DEFINE l_path     STRING = ".."
	DEFINE l_fileName STRING
	DEFINE l_file     STRING
	DEFINE l_info     STRING
	DEFINE l_tmp      STRING
	DEFINE l_jsonText TEXT
	DEFINE l_jsonStr  STRING
	DEFINE db RECORD
		name       STRING,
		type       STRING,
		driver     STRING,
		source     STRING,
		username   STRING,
		password   STRING,
		connection STRING
	END RECORD
	DEFINE l_enc encrypt
	DEFINE l_rds_cert STRING
	DEFINE l_test_con STRING
	DEFINE l_test_pw  STRING

	LET db.name   = this.name
	LET db.driver = this.driver
	LET db.type   = db.driver.subString(4, 6)
	LET db.source = this.source

	LET l_fileName = fgl_getenv("CUSTOM_DB_FILE")
	IF l_fileName.getLength() < 1 THEN
		LET l_fileName = C_CUSTOM_DB_FILE
	END IF

	LET l_file = fgl_getenv("CUSTOM_DB")
	IF l_file.getLength() < 1 THEN
		LET l_file = os.Path.join(l_path, l_fileName)
		IF NOT os.Path.exists(l_file) THEN
			LET l_path = os.Path.join("..", "..")
			LET l_file = os.Path.join(l_path, l_fileName)
		END IF
	END IF

	IF NOT os.Path.exists(l_file) THEN
		GL_DBGMSG(0, SFMT("getCustomDBUser: Not using %1", l_file))
		LET l_info = SFMT("'%1' - No custom database configuration found.", l_file)
	ELSE
		LET this.use_custom = TRUE
		TRY
			LOCATE l_jsonText IN FILE l_file                           -- save db connection info
			LET l_jsonStr = l_enc.g2_decStringPasswd(l_jsonText, NULL) -- decrypt it.
			IF l_jsonStr IS NULL THEN
				LET this.use_custom = FALSE
				LET l_info          = l_enc.errorMessage
			ELSE
				CALL util.JSON.parse(l_jsonStr, db)
				LET l_info = SFMT("Custom database configuration found in '%1'", l_file)
			END IF
		CATCH
			GL_DBGMSG(0, SFMT("getCustomDBUser: Failed to use '%1' error: %2:%3 ", l_file, status, err_get(status)))
			DISPLAY l_jsonStr
			LET db.connection   = NULL
			LET this.use_custom = FALSE
			LET l_info          = SFMT("Custom database configuration found in '%1' but was invalid JSON!", l_file)
		END TRY
		LET this.db_cfg     = SFMT("From %1", l_file)
		LET this.driver     = db.driver
		LET this.type       = db.type
		LET this.name       = db.name
		LET this.source     = db.source
		LET this.connection = db.connection
		LET this.db_user    = db.username
		LET this.db_passwd  = db.password
-- handle aws token for password
		IF this.db_passwd = "TOKEN" THEN
			LET this.db_passwd = g2_get_aws_token(db.source, db.username)
			IF this.db_passwd IS NULL THEN
				CALL g2_winMessage("Error", "Failed to get a token for the DB connection!", "exclamation")
			END IF
		END IF
-- if HC_DBCERT is set then check it and add it to the connection string.
		IF this.driver MATCHES ("*pgs*") THEN
			LET this.connection = SFMT("%1+driver='%2',source='%3", db.name, db.driver, db.source)
			LET l_rds_cert = fgl_getenv("HC_DBCERTS")
			IF l_rds_cert IS NOT NULL THEN -- check the cert exists.
				IF NOT os.Path.exists(l_rds_cert) THEN
					CALL g2_winMessage("Error", SFMT("DB Certificate not found!\nFile: %1", l_rds_cert), "exclamation")
					LET l_rds_cert = NULL
				END IF
				IF l_rds_cert IS NOT NULL THEN
					LET this.connection = this.connection.append(SFMT("?sslmode=verify-full&sslrootcert=%1", l_rds_cert))
				END IF
			END IF
			LET this.connection = this.connection.append("'") -- close the source quote
		END IF
	END IF
	GL_DBGMSG(0, SFMT("getCustomDBUser: %1", l_info))
	IF this.create_db THEN -- do UI for database connection info
		LET int_flag = FALSE
		OPEN WINDOW db_connection WITH FORM "g2_db_connection"
		DISPLAY l_info TO info
		LET db.connection = SFMT("%1+driver='%2',source='%3'", db.name, db.driver, db.source)
		OPTIONS INPUT WRAP
		INPUT BY NAME db.* ATTRIBUTES(UNBUFFERED, WITHOUT DEFAULTS)
			AFTER FIELD name
				LET db.connection = SFMT("%1+driver='%2',source='%3'", db.name, db.driver, db.source)
				IF db.source IS NULL THEN
					LET db.source = db.name
				END IF

			AFTER FIELD driver
				IF db.driver.subString(1, 3) != "dbm" THEN
					ERROR "Invalid driver name!"
					NEXT FIELD driver
				END IF
				LET l_tmp = os.Path.join(os.Path.join(fgl_getEnv("FGLDIR"), "dbdrivers"), db.driver || ".so")
				IF NOT os.Path.exists(l_tmp) THEN
					ERROR SFMT("Driver '%1' not found on server!", l_tmp)
					NEXT FIELD driver
				END IF
				LET db.connection = SFMT("%1+driver='%2',source='%3'", db.name, db.driver, db.source)
				LET db.type       = db.driver.subString(4, 6)

			AFTER FIELD source
				IF db.source IS NULL THEN
					LET db.source = db.name
				END IF
				LET db.connection = SFMT("%1+driver='%2',source='%3'", db.name, db.driver, db.source)

			ON ACTION test ATTRIBUTES(TEXT = "Test", IMAGE = "fa-magic")
				IF db.source IS NULL THEN
					LET db.source = db.name
				END IF
				LET l_test_pw = db.password
        LET l_info = ""
				IF l_test_pw = "TOKEN" THEN -- extra code for AWS Tokens
					LET l_test_pw = g2_get_aws_token(db.source, db.username)
					IF l_test_pw IS NULL THEN
						CALL g2_winMessage("Error",
                            SFMT("Failed to get a token for the DB connection!\nSource: %1\nUser:\%2", db.source, db.username)
                            , "exclamation")
						CONTINUE INPUT
					END IF
					LET l_info = l_info.append(SFMT("AWS Token: %1", l_test_pw))
				END IF
				LET l_test_con = SFMT("%1+driver='%2',source='%3", db.name, db.driver, db.source)
				IF this.driver MATCHES ("*pgs*") THEN -- extra code for PGS certificate
					LET l_rds_cert = fgl_getenv("HC_DBCERTS")
					IF l_rds_cert IS NULL THEN -- check the cert exists.
							LET l_info = l_info.append("Certificate: HC_DBCERTS is not set\n")
					ELSE
						IF NOT os.Path.exists(l_rds_cert) THEN
							CALL g2_winMessage("Error", SFMT("DB Certificate not found!\nFile: %1", l_rds_cert), "exclamation")
							LET l_rds_cert = NULL
						END IF
						IF l_rds_cert IS NOT NULL THEN
							LET l_test_con = l_test_con.append(SFMT("?sslmode=verify-full&sslrootcert=%1", l_rds_cert))
							LET l_info = l_info.append(SFMT("Certificate: %1\n", l_rds_cert))
						END IF
					END IF
				END IF
				LET l_test_con = l_test_con.append("'") -- close the source quote
				TRY
					IF db.username IS NOT NULL THEN
						LET l_info = l_info.append(SFMT("Connect as: %1", db.username))
						CONNECT TO l_test_con USER db.username USING l_test_pw
					ELSE
						LET l_info = l_info.append("Connect as local user")
						CONNECT TO l_test_con
					END IF
					LET l_info = l_info.append(" Okay")
					DISCONNECT CURRENT
				CATCH
					LET l_info = l_info.append(SFMT(" Failed!\n%1 - %2", STATUS, SQLERRMESSAGE))
				END TRY
				DISPLAY l_info TO info
			ON ACTION quit
				CALL g2_core.g2_exitProgram(1, "DB Connection Dialog Quit")
		END INPUT
		CLOSE WINDOW db_connection
		IF int_flag THEN
			LET int_flag = FALSE
			GL_DBGMSG(0, "getCustomDBUser: connection ui cancelled, using defaults.")
			RETURN
		END IF
		LOCATE l_jsonText IN FILE l_file
		LET l_jsonText = l_enc.g2_encStringPasswd(util.JSON.stringify(db), NULL) -- save encrypted db connection info
		IF db.source IS NULL THEN
			LET db.source = db.name
		END IF
		GL_DBGMSG(0, SFMT("getCustomDBUser: Using '%1'", l_file))
		LET this.db_cfg     = SFMT("From %1", l_file)
		LET this.driver     = db.driver
		LET this.type       = db.type
		LET this.name       = db.name
		LET this.source     = db.source
		LET this.connection = db.connection
		LET this.db_user    = db.username
		LET this.db_passwd  = db.password
		LET this.use_custom = TRUE
	END IF
END FUNCTION

--------------------------------------------------------------------------------
#+ Process the status after an SQL Statement.
#+
#+ @code CALL g2_db_sqlStatus( __LINE__, "gl_db", l_sql_stmt )
#+
#+ @param l_tab Table name
#+ @param l_defcol Default column
#+ @param l_search Search string
#+ @return a String containing a where clause
FUNCTION g2_chkSearch(l_tab STRING, l_defcol STRING, l_search STRING) RETURNS STRING
	DEFINE l_where, l_stmt, l_cond STRING
	DEFINE l_cnt                   INTEGER
	IF l_search IS NULL OR l_tab IS NULL THEN
		RETURN "1=1"
	END IF
	LET l_search = l_search.trim()
	IF l_search.getIndexOf(";", 1) > 0 THEN
		LET l_search = l_search.subString(1, l_cnt)
	END IF
	LET l_cond  = "MATCHES"
	LET l_where = SFMT("lower(%1) %2 '*%3*'", l_defcol, l_cond, l_search.toLowerCase())
	DISPLAY "Search:", l_search
	DISPLAY "       12345678901234567890"
	CALL g2_findCondition(l_search) RETURNING l_cnt, l_cond
	IF l_cnt = 1 THEN
		LET l_search = l_search.subString(l_cond.getLength() + 1, l_search.getLength())
		LET l_where  = SFMT("lower(%1) %2 '%3'", l_defcol.trim(), l_cond, l_search.toLowerCase())
	END IF
	IF l_cnt > 1 THEN
		LET l_defcol = l_search.subString(1, l_cnt - 1)
		LET l_search = l_search.subString(l_cnt + l_cond.getLength(), l_search.getLength())
		LET l_where  = SFMT("%1 %2 '%3'", l_defcol.trim(), l_cond, l_search.trim())
	END IF
	DISPLAY "X:", l_cnt, " Col:", l_defcol, " Condition:", l_cond, " Search:", l_search
	LET l_stmt = "SELECT COUNT(*) FROM " || l_tab || " WHERE " || l_where
	DISPLAY l_stmt
	TRY
		PREPARE pre_chk FROM l_stmt
		EXECUTE pre_chk INTO l_cnt
	CATCH
		CALL g2_core.g2_winMessage("SQL Error", SFMT("%1 %2", status, SQLERRMESSAGE), "exclamation")
		LET l_where = NULL
	END TRY
	IF l_cnt = 0 THEN
		ERROR SFMT("No rows found for search '%1'", l_search)
		LET l_where = NULL
	END IF
	RETURN l_where
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION g2_findCondition(l_search STRING) RETURNS(INT, STRING)
	DEFINE x INTEGER
	LET x = l_search.getIndexOf(">", 1)
	IF x > 0 THEN
		RETURN x, ">"
	END IF
	LET x = l_search.getIndexOf("<", 1)
	IF x > 0 THEN
		RETURN x, "<"
	END IF
	LET x = l_search.getIndexOf("!=", 1)
	IF x > 0 THEN
		RETURN x, "!="
	END IF
	LET x = l_search.getIndexOf("<>", 1)
	IF x > 0 THEN
		RETURN x, "<>"
	END IF
	LET x = l_search.getIndexOf("=", 1)
	IF x > 0 THEN
		RETURN x, "="
	END IF
	RETURN 0, NULL
END FUNCTION
--------------------------------------------------------------------------------
#+ Process the status after an SQL Statement.
#+
#+ @code CALL g2_db_sqlStatus( __LINE__, "gl_db", l_sql_stmt )
#+
#+ @param l_line Line number - should be __LINE__
#+ @param l_mod Module name - should be __FILE__
#+ @param l_stmt = String: The SQL Statement / Message, Can be NULL.
#+ @return TRUE/FALSE.  Success / Failed
FUNCTION g2_sqlStatus(l_line INT, l_mod STRING, l_stmt STRING) RETURNS BOOLEAN
	DEFINE l_stat INTEGER

	LET l_stat = status
	LET l_mod  = l_mod || " Line:", (l_line USING "<<<<<<<")
	IF l_stat = 0 THEN
		RETURN TRUE
	END IF
	IF l_stmt IS NULL THEN
		CALL g2_core.g2_errPopup(
				%"Status:" || l_stat || "\nSqlState:" || SQLSTATE || "\n" || SQLERRMESSAGE || "\n" || l_mod)
	ELSE
		CALL g2_core.g2_errPopup(
				l_stmt || "\nStatus:" || l_stat || "\nSqlState:" || SQLSTATE || "\n" || SQLERRMESSAGE || "\n" || l_mod)
		GL_DBGMSG(0, "gl_sqlStatus: Stmt         ='" || l_stmt || "'")
	END IF
	GL_DBGMSG(0, "gl_sqlStatus: WHERE        :" || l_mod)
	GL_DBGMSG(0, "gl_sqlStatus: status       :" || l_stat)
	GL_DBGMSG(0, "gl_sqlStatus: SQLSTATE     :" || SQLSTATE)
	GL_DBGMSG(0, "gl_sqlStatus: SQLERRMESSAGE:" || SQLERRMESSAGE)

	RETURN FALSE

END FUNCTION
--------------------------------------------------------------------------------
#+ Generate an insert statement.
#+
#+ @param tab String: Table name
#+ @param rec_n TypeInfo Node for record to udpate
#+ @param fixQuote Mask single quote with another single quote for GeneroDB!
#+ @return SQL Statement
FUNCTION g2_genInsert(tab STRING, rec_n om.DomNode, fixQuote BOOLEAN) RETURNS STRING
	DEFINE n           om.DomNode
	DEFINE nl          om.NodeList
	DEFINE l_stmt, val STRING
	DEFINE x, len      SMALLINT
	DEFINE typ, comma  CHAR(1)
--TODO: Check for duplicate
	LET l_stmt = "INSERT INTO " || tab || " VALUES("
	LET nl     = rec_n.selectByTagName("Field")
	LET comma  = " "
	FOR x = 1 TO nl.getLength()
		LET n = nl.item(x)
		CALL g2_getColumnType(n.getAttribute("type")) RETURNING typ, len
		LET val = n.getAttribute("value")
		IF val IS NULL THEN
			LET l_stmt = l_stmt.append(comma || "NULL")
		ELSE
			IF typ = "N" THEN
				LET l_stmt = l_stmt.append(comma || val)
			ELSE
				IF fixQuote THEN
					LET val = g2_fixQuote(val)
				END IF
				LET l_stmt = l_stmt.append(comma || "'" || val || "'")
			END IF
		END IF
		LET comma = ","
	END FOR
	LET l_stmt = l_stmt.append(")")
	RETURN l_stmt
END FUNCTION
--------------------------------------------------------------------------------
#+ Generate an update statement.
#+
#+ @param tab Table name
#+ @param wher 	Where Clause
#+ @param rec_n TypeInfo Node for NEW record to udpate
#+ @param rec_o TypeInfo Node for ORIGINAL record to udpate
#+ @param ser_col Serial Column number or 0 ( colNo of the column that is a serial )
#+ @param fixQuote Mask single quote with another single quote for GeneroDB!
#+ @return SQL Statement
FUNCTION g2_genUpdate(tab, wher, rec_n, rec_o, ser_col, fixQuote)
	DEFINE tab, wher                          STRING
	DEFINE ser_col, fixQuote                  SMALLINT
	DEFINE rec_n, rec_o, n, o                 om.DomNode
	DEFINE l_stmt, val, val_o, d_val, d_val_o STRING
	DEFINE nl_n, nl_o                         om.NodeList
	DEFINE x, len                             SMALLINT
	DEFINE typ, comma                         CHAR(1)

	LET l_stmt = "UPDATE " || tab || " SET "
	LET nl_n   = rec_n.selectByTagName("Field")
	LET nl_o   = rec_o.selectByTagName("Field")
	LET comma  = " "
	FOR x = 1 TO nl_n.getLength()
		IF x = ser_col THEN
			CONTINUE FOR
		END IF -- Skip Serial Column
		LET n = nl_n.item(x)
		LET o = nl_o.item(x)
		CALL g2_getColumnType(n.getAttribute("type")) RETURNING typ, len
		LET val_o = o.getAttribute("value")
		LET val   = n.getAttribute("value")
		IF (val_o IS NULL AND val IS NULL) OR val_o = val THEN
			CONTINUE FOR
		END IF
		LET d_val   = val
		LET d_val_o = val_o
		IF val IS NULL THEN
			LET d_val = "(null)"
		END IF
		IF val_o IS NULL THEN
			LET d_val_o = "(null)"
		END IF
		GL_DBGMSG(3, n.getAttribute("name") || " N:" || d_val || " O:" || d_val_o)
		LET l_stmt = l_stmt.append(comma || n.getAttribute("name") || " = ")
		IF val IS NULL THEN
			LET l_stmt = l_stmt.append("NULL")
		ELSE
			IF typ = "N" THEN
				LET l_stmt = l_stmt.append(val)
			ELSE
				IF fixQuote THEN
					LET val = g2_fixQuote(val)
				END IF
				LET l_stmt = l_stmt.append("'" || val || "'")
			END IF
		END IF
		LET comma = ","
	END FOR
	LET l_stmt = l_stmt.append(" WHERE " || wher)

	RETURN l_stmt
END FUNCTION
--------------------------------------------------------------------------------
#+ Fix single quote
#+
#+ @param l_in String to be fixed
#+ @returns fixed string
FUNCTION g2_fixQuote(l_in STRING) RETURNS STRING
	DEFINE y  SMALLINT
	DEFINE sb base.StringBuffer

	LET y = l_in.getIndexOf("'", 1)
	IF y > 0 THEN
		GL_DBGMSG(0, "Single Quote Found and fixed!")
		LET sb = base.StringBuffer.create()
		CALL sb.append(l_in)
		CALL sb.replace("'", "''", 0)
		LET l_in = sb.toString()
	END IF

	RETURN l_in
END FUNCTION
--------------------------------------------------------------------------------
#+ Get the database column type and return a simple char and len value.
#+ NOTE: SMALLINT INTEGER SERIAL DECIMAL=N, DATE=D, CHAR VARCHAR=C
#+
#+ @param l_typ Type
#+ @return CHAR(1),SMALLINT
FUNCTION g2_getColumnType(l_typ STRING) RETURNS(STRING, STRING)
	DEFINE l_len SMALLINT

--TODO: Use I for smallint, integer, serial, N for numeric, decimal
	LET l_len = g2_getColumnLength(l_typ, 0)
	CASE l_typ.subString(1, 3)
		WHEN "SMA"
			LET l_typ = "N"
		WHEN "INT"
			LET l_typ = "N"
		WHEN "SER"
			LET l_typ = "N"
		WHEN "DEC"
			LET l_typ = "N"
		WHEN "DAT"
			LET l_typ = "D"
		WHEN "CHA"
			LET l_typ = "C"
		WHEN "VAR"
			LET l_typ = "C"
	END CASE

	RETURN l_typ, l_len
END FUNCTION
--------------------------------------------------------------------------------
#+ Get the length from a type definiation ie CHAR(10) returns 10
#+
#+ @param s_typ Type
#+ @return Length from type or defaults to 10
FUNCTION g2_getColumnLength(l_type STRING, l_max SMALLINT) RETURNS SMALLINT
	DEFINE x, y, l_size SMALLINT
	CASE l_type
		WHEN "SMALLINT"
			LET l_size = 5
		WHEN "DATETIME HOUR TO MINUTE"
			LET l_size = 5
		WHEN "DATETIME YEAR TO MINUTE"
			LET l_size = 16 -- 1234/67/90 23:56
		WHEN "DATETIME YEAR TO SECOND"
			LET l_size = 19 -- 1234/67/90 23:56:89
		WHEN "DATETIME YEAR TO FRACTION"
			LET l_size = 23 -- 1234/67/90 23:56:89.123
		WHEN "DATETIME YEAR TO FRACTION(3)"
			LET l_size = 23 -- 1234/67/90 23:56:89.123
		WHEN "DATETIME YEAR TO FRACTION(5)"
			LET l_size = 25 -- 1234/67/90 23:56:89.12345
		WHEN "FLOAT"
			LET l_size = 12
		OTHERWISE
			LET l_size = 10
	END CASE
--TODO: Handle decimal, numeric ie values with , in.
	LET x = l_type.getIndexOf("(", 1)
	IF x > 1 THEN
		LET y = l_type.getIndexOf(",", 1)
		IF y = 0 THEN
			LET y = l_type.getIndexOf(")", 1)
		END IF
		LET l_size = l_type.subString(x + 1, y - 1)
	END IF
	IF l_max > 0 AND l_size > l_max THEN
		LET l_size = l_max
	END IF
	RETURN l_size
END FUNCTION
--------------------------------------------------------------------------------
#+ Check a record for valid update/insert
#+
#+ @param l_ex Exists true/false
#+ @param l_key Key value
#+ @param l_sql SQL to select using
#+ @returns true/false
FUNCTION g2_checkRec(l_ex BOOLEAN, l_key STRING, l_sql STRING) RETURNS BOOLEAN
	DEFINE l_exists BOOLEAN

	LET l_key = l_key.trim()
	DISPLAY "Key='", l_key, "'"

	IF l_key IS NULL OR l_key = " " OR l_key.getLength() < 1 THEN
		CALL g2_core.g2_warnPopup(%"You entered a NULL Key value!")
		RETURN FALSE
	END IF

	PREPARE g2_db_checkrec_pre FROM l_sql
	DECLARE g2_db_checkrec_cur CURSOR FOR g2_db_checkrec_pre
	OPEN g2_db_checkrec_cur
	LET l_exists = TRUE
	FETCH g2_db_checkrec_cur
	IF status = NOTFOUND THEN
		LET l_exists = FALSE
	END IF
	CLOSE g2_db_checkrec_cur
	IF NOT l_exists THEN
		IF l_ex THEN
			CALL g2_core.g2_warnPopup(%"Record '" || l_key || "' doesn't Exist!")
			RETURN FALSE
		END IF
	ELSE
		IF NOT l_ex THEN
			CALL g2_core.g2_warnPopup(%"Record '" || l_key || "' already Exists!")
			RETURN FALSE
		END IF
	END IF
	RETURN TRUE
END FUNCTION
--------------------------------------------------------------------------------
{
aws rds generate-db-auth-token \
    --hostname mydb.123456789012.us-east-1.rds.amazonaws.com \
    --port 3306 \
    --region us-east-1 \
    --username db_user
}
FUNCTION g2_get_aws_token(l_source STRING, l_user STRING) RETURNS(STRING)
	DEFINE c      base.Channel
	DEFINE l_cmd  STRING
	DEFINE l_tok  STRING
	DEFINE l_host STRING
	DEFINE l_port STRING
	DEFINE l_reg  STRING
	DEFINE x      SMALLINT

-- get the region
	LET l_reg = fgl_getenv("AWS_REGION")
	IF l_reg.getLength() < 1 THEN
		LET l_reg = fgl_getenv("AWS_DEFAULT_REGION")
	END IF
	IF l_reg.getLength() < 1 THEN
		GL_DBGMSG(0, "g2_get_aws_token: no region !")
		RETURN NULL
	END IF

-- get the host and port from the source
	LET x = l_source.getIndexOf("@", 1)
	IF x > 0 THEN -- remove the dbname
		LET l_source = l_source.subString(x + 1, l_source.getLength())
	END IF
	LET x = l_source.getIndexOf(":", 1)
	IF x > 0 THEN
		LET l_host = l_source.subString(1, x - 1)
		LET l_port = l_source.subString(x + 1, l_source.getLength())
	ELSE
		LET l_host = l_source
		LET l_port = 3306 -- should this port come from somewhere else? maybe an env var ?
	END IF

-- attempt to get the token
	LET c = base.Channel.create()
	LET l_cmd =
			SFMT("sudo -E /usr/local/bin/aws rds generate-db-auth-token --hostname %1 --port %2 --region %3 --username %4",
					l_host, l_port, l_reg, l_user)
	GL_DBGMSG(0, SFMT("g2_get_aws_token: openpipe: %1", l_cmd))
	CALL c.openPipe(l_cmd, "r")
	WHILE NOT c.isEof()
		LET l_tok = l_tok.append( c.readLine().trim() )
	END WHILE
	CALL c.close()

-- what would the return string look like if it failed for some reason ?

	RETURN l_tok
END FUNCTION
--------------------------------------------------------------------------------

