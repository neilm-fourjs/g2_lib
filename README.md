# g2_lib — Genero BDL Library

`g2_lib` is a reusable Genero BDL library. It gives an application the
common parts that almost every program needs: initialization, logging,
database connection, dynamic lookups, dynamic forms, reports, security
and REST service helpers.

Author: Neil J Martin (neil.martin@4js.com).

The library is an example of useful library code for Genero 4.01 and
above. Do not use it with an earlier release. No warrantee of any kind,
express or implied, is included with this software. Use it at your own
risk.

---

## 1. Folder layout

| Path | Contents |
|---|---|
| `g2_lib/` | The library modules (`.4gl`), forms (`.per`) and include files (`.inc`) |
| `src_expects/` | Example and test programs, plus the demo schema |
| `etc/` | Runtime configuration: `profile` (FGLPROFILE) and `test.4st` |
| `logs/` | Default log directory (see `g2_logging`) |
| `bin_expects401/`, `bin_expects501/`, `bin_expects600/` | Build output for the test programs, per Genero version |
| `g2_lib*.4pw` | Genero Studio project files, one per target version |
| `makefile` | Top level build |
| `.fgl-format` | Formatter settings for `fglcomp --format` |

---

## 2. Build

The makefile builds the library into a `.42x` archive with `gsmake`.

```bash
make                  # build with GENVER=401 (default)
make GENVER=600       # build for Genero 6.00
make test             # build the programs in src_expects
make clean            # delete .42?, .zip and .4pdb files
```

The output goes to `../njm_app_bin$(GENVER)/`.

To compile one module by hand:

```bash
fglcomp -r --make -M -W all g2_lib/g2_core.4gl
fglform -M -W all g2_lib/g2_db_connection.per
```

After a successful compile, apply the format rules in place:

```bash
fglcomp --format --fo-inplace g2_lib/g2_core.4gl
```

---

## 3. How to use the library

All modules declare `PACKAGE g2_lib`. Import the modules that you need:

```4gl
IMPORT FGL g2_lib.g2_init
IMPORT FGL g2_lib.g2_core
IMPORT FGL g2_lib.g2_db
```

`g2_lib/g2_import_all.inc` holds one `IMPORT` line for each module. Use
it when you want the complete library. `IMPORT FGL g2_lib.*` is not
reliable in all versions, so the explicit list is safer.

Call `g2_init.g2_init()` first in `MAIN`. It sets up the logs, the error
handler, the styles, the toolbar, the action defaults and the window
mode. Then connect to the database:

```4gl
MAIN
  DEFINE l_db g2_db.dbInfo = (type: "pgs")

  CALL g2_init.g2_init("S", NULL)   -- "S" = SDI, "M" = MDI
  CALL l_db.g2_connect("njm_demo400")
  ...
END MAIN
```

### Version conditionals

Genero 4.01 is the minimum release. All modules use the package style
imports, so no conditional is necessary for the imports.

One preprocessor conditional remains:

* `&ifdef gen600` — Genero 6.00 features, for example the `prometheus`
  counters in `g2_init`. Used in 3 places.

### Debug messages

Include `g2_debug.inc` to get the `GL_DBGMSG(level, message)` macro. The
macro calls `g2_debug.g2_dbgMsg()` with `__FILE__` and `__LINE__`. Set
the level with the `FJS_GL_DBGLEV` environment variable: `0` = none,
`1` = general, `2` = all.

---

## 4. Module reference

| Module | Lines | Purpose |
|---|---:|---|
| [`g2_about`](#g2_about) | 281 | Dynamic About window |
| [`g2_appInfo`](#g2_appinfo) | 76 | Application and client information class |
| [`g2_aui`](#g2_aui) | 605 | AUI tree helpers and dynamic form building |
| [`g2_calendar`](#g2_calendar) | 94 | Month and day names, weekend and month length |
| [`g2_core`](#g2_core) | 497 | Core services: styles, actions, messages, errors, exit |
| [`g2_db`](#g2_db) | 1089 | Database connection, table creation and SQL helpers |
| [`g2_debug`](#g2_debug) | 56 | Debug message output |
| [`g2_encrypt`](#g2_encrypt) | 223 | String encryption with a certificate or a password |
| [`g2_gdcUpdate`](#g2_gdcupdate) | 203 | GDC auto update client |
| [`g2_gdcUpdateCommon`](#g2_gdcupdatecommon) | 149 | Shared GDC update logic |
| [`g2_getFileName`](#g2_getfilename) | 54 | Select a file name from a folder |
| [`g2_grw`](#g2_grw) | 323 | Genero Report Writer class |
| [`g2_init`](#g2_init) | 89 | Program initialization and shutdown |
| [`g2_logging`](#g2_logging) | 252 | Logger class |
| [`g2_lookup`](#g2_lookup) | 250 | Dynamic lookup window, function style |
| [`g2_lookup2`](#g2_lookup2) | 596 | Dynamic lookup window, class style |
| [`g2_merge4st`](#g2_merge4st) | 68 | Merge a `.4st` style file into the running AUI tree |
| [`g2_secure`](#g2_secure) | 636 | Passwords, hashes, credential file and sessions |
| [`g2_simpleLookup`](#g2_simplelookup) | 95 | Key and description lookup from an array |
| [`g2_sql`](#g2_sql) | 362 | Single row SQL CRUD class |
| [`g2_ui`](#g2_ui) | 156 | Dynamic INPUT dialog driven by `g2_sql` |
| [`g2_util`](#g2_util) | 118 | Product version, host name, OS and date helpers |
| [`g2_ws`](#g2_ws) | 92 | REST service loop and JSON reply |

Files that are not part of the library build:

* `g2_db.4gl.sav` — an older copy of `g2_db.4gl`, kept for reference.

### Dependencies

```
g2_init ──► g2_core ──► g2_appInfo ──► g2_util
   │           │  └───► g2_logging
   │           └──────► g2_debug
   ├──► g2_logging
   └──► g2_debug

g2_db ──► g2_core, g2_debug, g2_encrypt
g2_secure ──► g2_core, g2_debug, g2_init, g2_encrypt
g2_encrypt ──► g2_init, g2_logging
g2_about ──► g2_appInfo, g2_core, g2_aui, g2_util, g2_db
g2_aui ──► g2_core, g2_debug
g2_lookup, g2_lookup2 ──► g2_core, g2_debug, g2_aui, g2_db
g2_simpleLookup ──► g2_debug, g2_aui
g2_getFileName ──► g2_core, g2_simpleLookup
g2_sql ──► g2_core, g2_db
g2_ui ──► g2_sql
g2_grw ──► g2_core, g2_debug, libgre, libgreprops
g2_gdcUpdate ──► g2_gdcUpdateCommon, g2_core, g2_debug, g2_aui
g2_ws ──► g2_logging
g2_calendar, g2_util, g2_debug, g2_merge4st  — no library dependencies
```

`g2_grw` needs `libgre` and `libgreprops` from `$GREDIR/lib`.

---

## 5. Modules in detail

### g2_init

Start and stop the program.

| Function | Description |
|---|---|
| `g2_init(l_mdi CHAR(1), l_cfgname STRING)` | Initialize the program. `l_mdi` is `"M"` for MDI or `"S"` for SDI. `l_cfgname` is the base name of the `.4st`, `.4tb` and `.4ad` files. |
| `g2_appClose()` | `ON CLOSE APPLICATION` handler. Exits through `g2_core.g2_exitProgram()`. |
| `g2_appTerm()` | `ON TERMINATE SIGNAL` handler. Rolls back the transaction, then exits. |

Public variables: `g2_isParent` (BOOLEAN), `g2_log` and `g2_err`
(`g2_logging.logger`).

`g2_init()` does this work:

1. Starts the `.log` and `.err` loggers, and calls `startlog()`.
2. Installs the close and terminate handlers.
3. Reads `FJS_GL_DBGLEV` and writes the environment to the debug log.
4. Sets `WHENEVER ANY ERROR CALL g2_error`.
5. Detects the front end (GDC or GBC) and sets `g2_core.m_isGDC` and
   `g2_core.m_isUniversal`.
6. Loads the styles, the toolbar and the action defaults.
7. Sets MDI or SDI mode.
8. With Genero 6.00, increments a `prometheus` counter.

---

### g2_core

Core services. Almost all other modules use this module.

| Function | Description |
|---|---|
| `g2_mdisdi(l_mdi CHAR(1))` | Set MDI or SDI mode. Reads `FJS_MDICONT` and `FJS_MDITITLE`. |
| `g2_loadStyles(l_stName STRING)` | Load a `.4st` style file. |
| `g2_loadActions(l_adName STRING)` | Load a `.4ad` action defaults file. |
| `g2_loadToolBar(l_tbName STRING)` | Load a `.4tb` toolbar file. |
| `g2_loadTopMenu(l_tmName STRING)` | Load a `.4tm` top menu file. |
| `g2_winMessage(l_title, l_message, l_icon)` | Message window with one **Okay** button. |
| `g2_winQuestion(l_title, l_message, l_ans, l_items, l_icon) RETURNS STRING` | Question dialog. `l_items` is a pipe separated answer list, for example `"Yes|No|Cancel"`. Returns the selected answer. |
| `g2_message(l_msg STRING)` | Show a message in the status line. |
| `g2_errPopup(l_msg STRING)` | Error popup. |
| `g2_warnPopup(l_msg STRING)` | Warning popup. |
| `g2_errMsg(l_fil STRING, l_lno INT, l_err STRING)` | Error popup with the file name and the line number. |
| `g2_chkClientVer(l_cli, l_ver, l_feature) RETURNS BOOLEAN` | Test that the client is at or above a version. `l_feature` names the feature in the message. |
| `g2_getVer(l_str STRING) RETURNS(DECIMAL(4,2), INT)` | Split a version string into a version number and a build number. |
| `g2_error()` | The `WHENEVER ANY ERROR` handler. |
| `g2_splash(l_dur, l_splashImage, l_w, l_h)` | Show a splash window for `l_dur` seconds. |
| `g2_sleep(l_timeout SMALLINT)` | Wait, without a busy loop. |
| `g2_getImagePath() RETURNS STRING` | Return the first path in `FGLIMAGEPATH`. |
| `g2_exitProgram(l_stat SMALLINT, l_reason STRING)` | Log the reason and exit with a status. |

Public variables: `m_mdi`, `m_isUniversal`, `m_isGDC`, `m_isWS`,
`m_appInfo` (`g2_appInfo.appInfo`), `m_log` (`g2_logging.logger`).

---

### g2_appInfo

Class that holds the application, the program, the client and the
database information. `g2_core.m_appInfo` is the shared instance.
`g2_about` displays it.

`PUBLIC TYPE appInfo RECORD` members include `appName`, `appBuild`,
`progName`, `progDesc`, `progVersion`, `progAuth`, `progDir`,
`splashImage`, `userName`, the front end fields (`fe_typ`, `fe_ver`,
`uni_typ`, `uni_ver`), the client fields (`cli_os`, `cli_osver`,
`cli_res`, `cli_dir`, `cli_un`), `os`, `hostname`, `gver`,
`server_time`, `db_name`, `db_driver`, `db_date`, `scr_h` and `scr_w`.

| Method | Description |
|---|---|
| `progInfo(l_progDesc, l_progAuth, l_progVer, l_progImg)` | Set the program description, the author, the version and the splash image. |
| `appInfo(l_appName, l_appBuild)` | Set the application name and build. |
| `getClientInfo()` | Read the front end type, version, screen size and client OS. |
| `setUserName(l_user STRING)` | Set the user name. With a NULL argument, it reads the environment. |

---

### g2_logging

Logger class. `g2_init` creates two instances: `g2_log` for `.log` files
and `g2_err` for `.err` files.

| Method | Description |
|---|---|
| `init(l_dir, l_name, l_ext, l_useDate)` | Set the directory, the file name, the extension and the date flag in one call. |
| `logIt(l_mess STRING)` | Write one time stamped line to the log. |
| `setLogDir(l_dir STRING)` | Set the log directory. The default is `../logs/`, or `LOGDIR`. |
| `setLogName(l_file STRING)` | Set the log file name. The default is the program name. |
| `setLogExt(l_ext STRING)` | Set the file extension. |
| `setUseDate(l_useDate STRING)` | Add the date to the file name. Also reads `LOGFILEDATE`. |
| `getLogDir()`, `getLogName()`, `getLogExt()` | Return the current settings. |
| `logProgramRun(l_isParent BOOLEAN, l_user STRING, l_msg STRING)` | Write a program run record. |
| `getCallingModuleName() RETURNS STRING` | Return the name of the calling module. Module level function. |

Record members: `dirName`, `fileName`, `fileExt`, `logFullPath`,
`runLogFullPath`, `useDate`.

---

### g2_debug

| Function | Description |
|---|---|
| `g2_dbgMsg(l_fil STRING, l_lno INT, l_lev STRING, l_msg STRING)` | Write a debug message to the console. |

Do not call this function directly. Use the `GL_DBGMSG(lev, msg)` macro
from `g2_debug.inc`. The macro supplies `__FILE__` and `__LINE__`.

---

### g2_util

Small helpers. This module has no library dependencies.

| Function | Description |
|---|---|
| `g2_getProductVer(l_prod STRING) RETURNS STRING` | Return the version of a product, for example `fglrun`. Reads the output of `fpi -l`. |
| `g2_strToDate(l_str STRING) RETURNS DATE` | Convert a string to a DATE. |
| `g2_getHostname() RETURNS STRING` | Return the host name. |
| `g2_getUname() RETURNS STRING` | Return the output of `uname`. |
| `g2_getLinuxVer() RETURNS STRING` | Return the Linux distribution version. |

---

### g2_calendar

Month and day names in more than one language, and date tests.

Public constants: `C_MONTHS_IS`, `C_DAYS3_IS`, `C_DAYS1_IS` (Icelandic),
`C_MONTHS_ES`, `C_DAYS3_ES`, `C_DAYS1_ES` (Spanish), `C_MONTHS_PT`,
`C_DAYS3_PT`, `C_DAYS1_PT` (Portuguese). Each list is pipe separated.

| Function | Description |
|---|---|
| `month_fullName_int(m SMALLINT)` | Full month name for a month number. |
| `month_shortName_int(m SMALLINT)` | Short month name for a month number. |
| `month_fullName(dt DATETIME YEAR TO DAY)` | Full month name for a date. |
| `month_shortName(dt DATETIME YEAR TO DAY)` | Short month name for a date. |
| `day_fullName(dt DATETIME YEAR TO DAY)` | Full day name. |
| `day_shortName(dt DATETIME YEAR TO DAY)` | Short day name. |
| `isWeekEnd(l_date DATE)` | TRUE when the date is a Saturday or a Sunday. |
| `days_in_month(x)` | Number of days in the month. |

---

### g2_aui

Helpers for the AUI tree, and functions that build a form at run time.
The lookup modules use this module.

| Function | Description |
|---|---|
| `g2_getWinNode(l_nam STRING) RETURNS om.DomNode` | Return the node of a named window. With a NULL argument, it returns the current window. |
| `g2_getFormNode(l_nam STRING) RETURNS om.DomNode` | Return the node of a named form. |
| `g2_getForm(l_nam STRING) RETURNS ui.Form` | Return a `ui.Form` object. |
| `g2_genForm(l_nam STRING) RETURNS om.DomNode` | Create an empty form in the AUI tree and return the node. |
| `g2_notify(l_msg STRING)` | Show a notification message. |
| `g2_showLicence()` | Show the licence text in a window. |
| `g2_showReadMe()` | Show the file named by the `README` environment variable. |
| `g2_showEnv()` | Show the environment, the FGLPROFILE settings and the program information. |
| `g2_progBar(l_meth SMALLINT, l_curval INT, l_txt STRING)` | Progress bar. `l_meth`: 1 = open and set the maximum, 2 = move the bar, 3 = close. |
| `g2_winInfo(l_meth SMALLINT, l_txt STRING, l_icon STRING)` | Information window. `l_meth`: 1 = open, 2 = change the message, 3 = close. |
| `g2_addField(f, x, y, wgt, fld, w, com, j, s)` | Add a field to a grid or a group. `wgt` is the widget name, for example `Edit`, `ButtonEdit`, `ComboBox` or `DateEdit`. |
| `g2_addLabel(l, x, y, w, txt, j, s)` | Add a label to a grid or a group. |
| `g2_addItem(l_rad, l_val, l_txt)` | Add an `Item` node to a RadioGroup or a ComboBox. |

Example of the progress bar:

```4gl
CALL g2_aui.g2_progBar(1, 10, "Processing, please wait ...")
FOR x = 1 TO 10
  CALL g2_aui.g2_progBar(2, x, NULL)
END FOR
CALL g2_aui.g2_progBar(3, 0, NULL)
```

---

### g2_about

| Function | Description |
|---|---|
| `g2_about()` | Build and show an About window at run time. |

The window shows the content of `g2_core.m_appInfo`: the program, the
application, the Genero version, the front end, the client, the host and
the database. Missing values are filled in from `g2_appInfo`, `g2_util`
and the environment. The user can save the information as JSON.

---

### g2_db

Database connection and SQL helper functions. This is the largest module.

`PUBLIC TYPE dbInfo RECORD`: `name`, `type`, `desc`, `source`, `driver`,
`dir`, `dbspace`, `connection`, `db_user`, `db_passwd`, `create_db`,
`serial_emu`, `serial_errd`, `use_custom`, `db_cfg`.

`PUBLIC DEFINE m_db dbInfo` is the shared instance. Use it instead of a
new definition in the calling module.

Methods:

| Method | Description |
|---|---|
| `g2_connect(l_dbName STRING)` | Connect to the database. Reads the record, then the environment, then FGLPROFILE, then the custom configuration file. Creates the database when `create_db` is TRUE. |
| `g2_getType() RETURNS STRING` | Return the database type, for example `ifx`, `pgs` or `sqt`. |
| `g2_sqt_createdb(l_dir STRING, l_file STRING)` | Create an SQLite database file. |
| `g2_mdb_createdb()` | Create a MariaDB or MySQL database. |
| `g2_ifx_createdb()` | Create an Informix database. |
| `g2_createTable(l_rec reflect.Value, l_nam, l_priKey, l_extra)` | Create a table from a BDL record, with `reflect`. |
| `g2_addPrimaryKey(l_tab, l_col, l_isSerial)` | Add a primary key to a table. |
| `g2_showInfo(stat INTEGER)` | Show the connection information in the `g2_db_connection` form. |
| `g2_getCustomDBInfo()` | Read the encrypted custom database configuration. |

Module level functions:

| Function | Description |
|---|---|
| `g2_chkSearch(l_tab, l_defcol, l_search) RETURNS STRING` | Turn user search text into a WHERE clause. |
| `g2_findCondition(l_search STRING) RETURNS(INT, STRING)` | Find the comparison operator in search text. |
| `g2_sqlStatus(l_line INT, l_mod STRING, l_stmt STRING) RETURNS BOOLEAN` | Test `sqlca` after a statement, and report the error. |
| `g2_genInsert(tab STRING, rec_n om.DomNode, fixQuote BOOLEAN) RETURNS STRING` | Generate an INSERT statement from an AUI record node. |
| `g2_genUpdate(tab, wher, rec_n, rec_o, ser_col, fixQuote)` | Generate an UPDATE statement for the changed columns only. |
| `g2_fixQuote(l_in STRING) RETURNS STRING` | Double the single quotation marks in a string. |
| `g2_getColumnType(l_typ STRING) RETURNS(STRING, STRING)` | Convert an internal column type to a name and a widget. |
| `g2_getColumnLength(l_type STRING, l_max SMALLINT) RETURNS SMALLINT` | Return the display length for a column type. |
| `g2_checkRec(l_ex BOOLEAN, l_key STRING, l_sql STRING) RETURNS BOOLEAN` | Test that a row exists, or that it does not exist. |
| `g2_get_aws_token(l_source STRING, l_user STRING) RETURNS STRING` | Get an AWS IAM authentication token for RDS. |

The custom configuration file is `custom_db_enc4.json`.
`CUSTOM_DB_FILE` changes the file name, and `CUSTOM_DB` gives the full
path. `g2_encrypt` decrypts the
file. When the file does not exist, `g2_getCustomDBInfo()` uses the
`HC_DB*` variables.

Defaults: driver `dbmifx9x`, dbspace `rootdbs`, directory `../db`.

---

### g2_sql

Class for single row SQL work. It builds the statements from the table
name and the column list, so the calling program does not write SQL.

`PUBLIC TYPE t_fields RECORD`: `colName`, `colType`, `colLength`,
`isNumeric`, `isKey`, `value`, `para_no`, `formOnly`, `noEntry`,
`defValue`.

`PUBLIC TYPE sql RECORD`: `handle`, `table_name`, `key_field`,
`key_field_num`, `where_clause`, `column_list`, `rows_count`,
`current_row`, `fields`, `json_rec`.

Constants for `g2_SQLgetRow()`: `SQL_FIRST` (0), `SQL_PREV` (-1),
`SQL_NEXT` (-2), `SQL_LAST` (-3).

| Method | Description |
|---|---|
| `g2_SQLinit(l_tabName, l_cols, l_keyField, l_where)` | Set the table, the column list (or `"*"`), the key column and the WHERE clause. |
| `g2_SQLcursor()` | Prepare and open the cursor, and count the rows. |
| `g2_SQLclose()` | Close the cursor and free the handle. |
| `g2_SQLsetColumnProps(l_colNo SMALLINT)` | Read the type, the length and the key flag of one column. |
| `g2_SQLgetRow(l_row INTEGER, l_msg BOOLEAN)` | Fetch a row. Use a row number or one of the `SQL_*` constants. |
| `g2_SQLupdate() RETURNS BOOLEAN` | Update the current row from the field values. |
| `g2_SQLinsert() RETURNS BOOLEAN` | Insert a row from the field values. |
| `g2_SQLdelete() RETURNS BOOLEAN` | Delete the current row. |
| `g2_SQLrec2Json()` | Put the current row into `json_rec`. Use `json_rec.toFGL()` to fill a BDL record. |

```4gl
DEFINE l_sql g2_sql.sql
DEFINE l_stk RECORD LIKE stock.*

CALL l_sql.g2_SQLinit("stock", "*", "stock_code", "stock_code = 'FR01'")
CALL l_sql.g2_SQLgetRow(1, TRUE)
CALL l_sql.g2_SQLrec2Json()
CALL l_sql.json_rec.toFGL(l_stk)
```

---

### g2_ui

Dynamic INPUT dialog. It uses the field list of a `g2_sql.sql` record,
so no `.per` form is necessary. Callback function types let the calling
program add its own logic.

Callback types:

| Type | Signature |
|---|---|
| `t_init_inp_func` | `FUNCTION(l_new BOOLEAN, l_d ui.Dialog) RETURNS()` |
| `t_before_inp_func` | `FUNCTION(l_new BOOLEAN, l_d ui.Dialog) RETURNS()` |
| `t_after_inp_func` | `FUNCTION(l_new BOOLEAN, l_d ui.Dialog) RETURNS BOOLEAN` |
| `t_after_fld_func` | `FUNCTION(l_fldName STRING, l_fldValue STRING, l_d ui.Dialog) RETURNS()` |
| `t_onChange_func` | `FUNCTION(l_fldName STRING, l_fldValue STRING, l_d ui.Dialog) RETURNS()` |

`PUBLIC TYPE g2_ui RECORD`: `dia`, `init_inp_func`, `before_inp_func`,
`after_inp_func`, `after_fld_func`, `onChange_func`, `fields`.

| Method | Description |
|---|---|
| `g2_UIinput(l_new BOOLEAN, l_sql g2_sql.sql, l_acceptAction STRING, l_exitOnAccept BOOLEAN)` | Run an unbuffered INPUT on the fields of `l_sql`. `l_new` is TRUE for an insert. The default accept action is `accept`. |
| `g2_addFormOnlyField(l_name, l_type, l_value, l_noEntry)` | Add a form only field to the dialog. |

---

### g2_lookup

Dynamic lookup window, function style. It builds the form and the SQL
from the arguments.

| Function | Description |
|---|---|
| `g2_lookup(tabnam, cols, colts, wher, ordby) RETURNS STRING` | Show a list and return the key of the selected row, or NULL. |

* `tabnam` — the table name, or a table list.
* `cols` — the column names, comma separated.
* `colts` — the column titles, comma separated. NULL uses the column
  names. An underscore hides the column, for example the key column.
* `wher` — the WHERE clause. Use `1=1` for all rows.
* `ordby` — the ORDER BY clause.

The maximum column width is 40 characters (`MAXCOLWIDTH`).

---

### g2_lookup2

Dynamic lookup window, class style. It adds a row count, client stored
settings, and update, insert and delete support (work in progress).

`PUBLIC TYPE lookup RECORD` holds `tableName`, `columnList`,
`columnTitles`, `whereClause`, `orderBy`, `maxColWidth`, `isKeySerial`,
`allowUpdate`, `allowInsert`, `allowDelete`, `sql_count`, `sql_getData`,
`totalRecords`, `totalFields`, `sqlQueryHandle`, `dsp_fields`, `fields`,
`inputVBox`, `columnTitlesArr`, `formName`, `windowTitle`, `theDialog`,
`selectedKey` and `currentRow`.

| Method | Description |
|---|---|
| `g2_lookup2() RETURNS STRING` | Show the lookup and return the selected key. |
| `init(tabnam, cols, colts, wher, ordby)` | Set the table, the columns, the titles, the WHERE clause and the ORDER BY clause. |
| `countRows(l_where STRING) RETURNS INT` | Count the rows. Uses `sql_count` when it is set. |
| `refrestData()` | Fetch the data again into the display array. |

There are three ways to use the class:

```4gl
-- 1: with init()
DEFINE l_lookup g2_lookup2.lookup
CALL l_lookup.init("countries", "*", "Code,Country", "1=1", "country_name")
DISPLAY "Selected value: ", l_lookup.g2_lookup2()

-- 2: with the record members
LET l_lookup.tableName    = "colours"
LET l_lookup.columnList   = "*"
LET l_lookup.columnTitles = "Key,Name,Hex"
LET l_lookup.orderBy      = "colour_name"
DISPLAY "Selected value: ", l_lookup.g2_lookup2()

-- 3: with your own SQL
LET l_lookup.sql_count    = "SELECT COUNT(*) FROM customer"
LET l_lookup.columnTitles = "Code,Name,Address"
LET l_lookup.sql_getData  = "SELECT ... FROM customer, addresses WHERE ..."
LET l_lookup.windowTitle  = "Customers"
DISPLAY "Selected value: ", l_lookup.g2_lookup2()
```

---

### g2_simpleLookup

Lookup from an array in memory. There is no database access.

`PUBLIC TYPE simpleLookup RECORD`: `name`, `title`, `keyTitle`,
`descTitle`, and `arr` — a dynamic array of `key` and `desc`.

| Method | Description |
|---|---|
| `g2_simpleLookup() RETURNS STRING` | Show the list and return the selected key. |

---

### g2_getFileName

| Function | Description |
|---|---|
| `g2_getFileName(l_folder, l_ext, l_titl, l_head) RETURNS STRING` | List the files in a folder that match an extension, and return the selected name without the extension. |

The function uses `g2_simpleLookup` for the list.

---

### g2_encrypt

Encrypt and decrypt a string. There are two methods: a certificate with
a private key, or a password.

`PUBLIC TYPE encrypt RECORD`: `certFile`, `privateKey`, `errorMessage`.

| Method | Description |
|---|---|
| `init(l_cert STRING, l_key STRING)` | Set the certificate file and the private key file. |
| `encrypt(l_str STRING) RETURNS STRING` | Encrypt with the certificate. Returns NULL after an error. |
| `decrypt(l_str STRING) RETURNS STRING` | Decrypt with the private key. |
| `g2_encStringPasswd(l_string STRING, l_pass CHAR(32)) RETURNS STRING` | Encrypt with a password. A NULL password uses the built in default. |
| `g2_decStringPasswd(l_string STRING, l_pass CHAR(32)) RETURNS STRING` | Decrypt with a password. |
| `g2_encryptError(l_msg STRING)` | Record an error in `errorMessage`. |

Read `errorMessage` when a method returns NULL.

---

### g2_secure

Password rules, password hashes, an encrypted credential file, and
client side sessions.

Constants: `C_CERTFILE` = `../etc/publickey.crt`, `C_PRIVATEKEY` =
`../etc/private.key`, `C_DEFPASSLEN` = 8, `C_SYMBOLS` = `!$%^&*,.;@#?<>`,
`C_SHA_ITERATIONS` = 64.

| Function | Description |
|---|---|
| `g2_genPassword() RETURNS STRING` | Generate a password that passes the rules. |
| `g2_getHashType() RETURNS STRING` | Return the hash type. The current value is `BCRYPT`. |
| `g2_genSalt(l_hashtype STRING) RETURNS STRING` | Generate a salt. BCrypt uses a cost of 12. SHA512 uses a 16 character random string. |
| `g2_genPasswordHash(l_pass, l_salt, l_hashtype) RETURNS STRING` | Hash a password. |
| `g2_chkPassword(l_pass, l_passhash, l_salt, l_hashtype) RETURNS BOOLEAN` | Compare a password with a stored hash. BCrypt does not need the salt. |
| `g2_passwordRules(l_max INTEGER) RETURNS STRING` | Return the password rules as text, for a form comment. |
| `g2_isPasswordLegal(l_pass STRING) RETURNS STRING` | Test a password against the rules. Returns `"Okay"`, or the reason. |
| `g2_toBase64(l_str STRING) RETURNS STRING` | Encode to Base64. |
| `g2_fromBase64(l_str STRING) RETURNS STRING` | Decode from Base64. |
| `g2_getCreds(l_typ STRING) RETURNS(STRING, STRING)` | Read a user name and a password from the encrypted XML credential file. `l_typ` selects the entry, for example an email or an SMS provider. |
| `g2_updCreds(l_typ, l_user, l_pass) RETURNS BOOLEAN` | Write an entry to the credential file. |
| `g2_saveSession(l_id STRING, l_user STRING)` | Save an encrypted time stamp and user name in the client `localStorage`. |
| `g2_getSession(l_id STRING, l_age INTEGER) RETURNS STRING` | Read the session. Returns the user name, `"expired"`, or NULL. `l_age` is the maximum age in minutes. |
| `g2_removeSession(l_id STRING)` | Remove the session from `localStorage`. |

The session functions need GDC 3.10.18 or later. They do nothing with
the GGC front end.

**Warning:** SHA512 hashes and BCrypt hashes are not compatible. If you
change the hash type, you must generate all the password hashes again.

---

### g2_grw

Class for Genero Report Writer. It supports a local report and a
distributed report with a GRE server.

`PUBLIC TYPE greRpt RECORD`: `reportsDir`, `rptName`, `fileName`,
`device`, `preview`, `pageWidth`, `rptTitle`, `handle`,
`greDistributed`, `greServer`, `greServerPort`, `greOutputDir`,
`started`, `finished`, `status`, `error`.

| Method | Description |
|---|---|
| `init(l_rptName, l_preview, l_device, l_start) RETURNS BOOLEAN` | Set up the report. A NULL device, or `"ASK"`, opens the output dialog. `l_start` TRUE also calls `start()`. |
| `start() RETURNS BOOLEAN` | Configure the output and start the report. |
| `allOkay(l_where STRING) RETURNS BOOLEAN` | Test the report state, and record the error. |
| `progress(l_row INTEGER, l_max INTEGER, l_mod SMALLINT)` | Update the progress bar every `l_mod` rows. |
| `finish()` | Finish the report and record the time. |
| `getOutput() RETURNS BOOLEAN` | Ask the user for the output device with the `gl_grwCfg` form. |

The class reads `GRESERVER`, `GRESRVPORT` and `GREOUTPUTDIR`. A
`GRESERVER` value turns on distributed mode. The default port is 6490.

---

### g2_ws

Helpers for a REST service program.

`PUBLIC TYPE t_response RECORD`: `server`, `status`, `timestamp`,
`description`, `data` (`util.JSONObject`).

Public variables: `m_server`, `ws_response`.

| Function | Description |
|---|---|
| `start(l_module STRING, l_basePath STRING, g2_log g2_logging.logger INOUT)` | Register the REST service, then run the request loop. The function writes each return code of `ProcessServices()` to the log, and it exits on a lost connection or on an interrupt. |
| `service_reply(l_stat INT, l_reply STRING) RETURNS STRING` | Build the JSON response. A reply that starts with `{` is used as a JSON object. Other replies become the description. |

---

### g2_gdcUpdate and g2_gdcUpdateCommon

Automatic update of the Genero Desktop Client. `g2_gdcUpdate` holds the
client logic. `g2_gdcUpdateCommon` holds the parts that a server program
also needs.

`g2_gdcUpdate`:

| Function | Description |
|---|---|
| `g2_gdcUpate()` | Check the GDC version and install an update. |
| `abortGDCUpdate(l_msg STRING)` | Private. Stop the update and report the reason. |
| `useGDCUpdateWS(l_url STRING)` | Private. Ask a web service for the update information. |
| `getGDCUpdateZipFile(l_localFile, l_url, l_file) RETURNS BOOLEAN` | Private. Download the update ZIP file. |

`g2_gdcUpdateCommon`:

| Function | Description |
|---|---|
| `g2_validGDCUpdateDir() RETURNS BOOLEAN` | Test that the update directory is usable. |
| `g2_getCurrentGDC() RETURNS(STRING, STRING)` | Return the version and the build of the running GDC. |
| `g2_chkIfUpdate(l_curGDC STRING, l_newGDC STRING) RETURNS BOOLEAN` | Compare two versions, and report if an update is necessary. |
| `g2_getUpdateFileName(l_newGDC, l_gdcBuild, l_gdcos) RETURNS BOOLEAN` | Build the name of the update file. |
| `g2_setReply(l_stat INT, l_txt STRING, l_msg STRING)` | Fill the reply record. |

Both modules read `GDCUPDATEDIR` and `GDCUPDATESERVER`.

---

### g2_merge4st

| Function | Description |
|---|---|
| `g2_merge4st(l_file STRING)` | Merge the styles of a `.4st` file into the `StyleList` of the running AUI tree. |

The function looks for the file in the first directory of
`FGLRESOURCEPATH`. A style that exists is replaced attribute by
attribute. A new style is added. Use this function to add or change
styles while the program runs.

---

## 6. Forms

| Form | Used by | Description |
|---|---|---|
| `g2_db_connection.per` | `g2_db.g2_showInfo()` | Shows the database connection settings and the AWS token. |
| `gl_grwCfg.per` | `g2_grw.getOutput()` | Asks for the report output device, the orientation and the file name. |

All other windows in the library are built at run time with `g2_aui`.

---

## 7. Include files

| File | Description |
|---|---|
| `g2_debug.inc` | The `GL_DBGMSG(lev, msg)` macro and the `gl_dbgLev` global. |
| `g2_import_all.inc` | One `IMPORT FGL g2_lib.<module>` line for each module. |

---

## 8. Environment variables

### Library

| Variable | Description |
|---|---|
| `FJS_GL_DBGLEV` | Debug level: 0 = none, 1 = general, 2 = all. |
| `FJS_MDICONT` | MDI container name. |
| `FJS_MDITITLE` | MDI window title. |
| `G2_PARENTPID` | Process ID of the parent program. Set by `g2_init`. |
| `G2_USER` | User name for the program run log. `g2_logging.logProgramRun()` reads it, and sets it when it is empty. |
| `README` | Path of the file that `g2_aui.g2_showReadMe()` shows. |

### Logs and reports

| Variable | Description |
|---|---|
| `LOGDIR` | Log directory. The default is `../logs/`. |
| `LOGFILEDATE` | Add the date to the log file name. |
| `REPORTDIR` | Report directory. |
| `GRESERVER`, `GRESRVPORT`, `GREOUTPUTDIR` | GRE server, port (default 6490) and output directory. |

### Database

| Variable | Description |
|---|---|
| `DBNAME`, `DBDRIVER`, `DBSPACE`, `DBPATH`, `DBDATE`, `DBDEBUG`, `DB_LOCALE` | Standard Genero database settings. |
| `CUSTOM_DB` | Full path of the encrypted custom database configuration file. |
| `CUSTOM_DB_FILE` | File name of the custom database configuration. The default is `custom_db_enc4.json`. |
| `SQLITEDB` | SQLite database file. |
| `INFORMIXDIR`, `INFORMIXSERVER`, `INFORMIXSQLHOSTS` | Informix settings. |
| `HC_DBNAME`, `HC_DBDRIVER`, `HC_DBSERVER`, `HC_DBUSER`, `HC_DBCERTS` | Connection settings that are used when there is no custom configuration file. `HC_DBCERTS` adds a certificate to the connection string. |
| `AWS_REGION`, `AWS_DEFAULT_REGION` | Region for the AWS RDS token. |

### GDC update

| Variable | Description |
|---|---|
| `GDCUPDATEDIR` | Directory that holds the GDC update files. |
| `GDCUPDATESERVER` | URL of the update web service. |

The library also reads the standard Genero variables `FGLDIR`,
`FGLSERVER`, `FGLPROFILE`, `FGLIMAGEPATH`, `FGLGBCDIR`,
`FGLRESOURCEPATH`, `FGLASDIR` and `LANG`.

---

## 9. Examples and tests

`src_expects/` holds small programs that use the library. `make test`
builds them with `test.4pw`.

| Program | Shows |
|---|---|
| `g2_exp_sql.4gl` | `g2_sql` — fetch a row, and convert it to a record with JSON. |
| `g2_exp_lookup.4gl` | `g2_lookup` and `g2_lookup2`, with a menu of examples. |
| `g2_exp_encStr.4gl` | `g2_encrypt` — encrypt and decrypt with a password. |
| `g2_exp_ws.4gl` | `g2_ws.service_reply()` — the JSON response format. |
| `g2_exp_merge4st.4gl` | `g2_merge4st` — merge `etc/test.4st` at run time. |
| `lib_expect.4gl` | The small test framework: `test()`, `okay()`, `failed()` and `results()`. `results()` exits with status 1 after a failure. |
| `njm_demo400.sch`, `njm_demo400.4db` | The demo schema and database definition. |

Run a test program in terminal mode:

```bash
FGLGUI=0 TERM=xterm fglrun g2_exp_sql.42m
```

---

## 10. Code conventions

* Local variables and parameters use the `l_` prefix.
* Module level variables use the `m_` prefix.
* Public library variables use the `g2_` prefix, for example `g2_log`.
* Types use the `t_` prefix.
* A line of 80 hyphens follows each `END FUNCTION`.
* Use `SFMT()` in place of the double pipe operator, except in a static
  SQL statement.
* A module that uses the database starts with a `SCHEMA` statement, and
  defines its records with `DEFINE ... LIKE`.
* Doc comments use the `#+` prefix, with `@param`, `@return` and `@code`
  tags.

The formatter settings are in `.fgl-format`: a 120 character column
limit, a 2 space indent, tabs, uppercase keywords, and aligned
assignments and types.
