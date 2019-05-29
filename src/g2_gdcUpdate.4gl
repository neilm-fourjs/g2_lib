# Library functions for GDC Auto Update.
IMPORT os
IMPORT com
IMPORT util

IMPORT FGL g2_lib
IMPORT FGL g2_aui
IMPORT FGL g2_gdcUpdateCommon
&include "g2_debug.inc"

TYPE t_myReply RECORD
  stat SMALLINT,
  stat_txt STRING,
  reply STRING,
  upd_url STRING,
  upd_dir STRING,
  upd_file STRING
END RECORD
PUBLIC DEFINE m_ret t_myReply
PUBLIC DEFINE m_gdcUpdateDir STRING

--------------------------------------------------------------------------------
-- Primary function to call from program to test for and do GDC update.
FUNCTION g2_gdcUpate()
  DEFINE l_updServer STRING
  DEFINE l_curGDC, l_os, l_osTarget, l_tmp, l_localFile, l_newFile STRING
  DEFINE l_newGDC, l_newGDCBuild STRING
  DEFINE x SMALLINT
  DEFINE l_stat SMALLINT
  DEFINE l_ret SMALLINT

  IF DOWNSHIFT(ui.Interface.getFrontEndName()) != "gdc" THEN
    RETURN
  END IF

  LET l_curGDC = ui.Interface.getFrontEndVersion()
  LET x = l_curGDC.getIndexOf("-", 1)
  IF x < 5 THEN
    CALL g2_lib.g2_winMessage(
        "Error", SFMT(% "Invalid GDC Version error '%1'!", l_curGDC), "exclamation")
    RETURN
  END IF
  LET l_curGDC = l_curGDC.subString(1, x - 1)
  CALL ui.Interface.frontCall("standard", "feinfo", "target", l_osTarget)

  IF NOT g2_gdcUpdateCommon.g2_validGDCUpdateDir() THEN
    DISPLAY g2_gdcUpdateCommon.m_ret.stat_txt, ":", g2_gdcUpdateCommon.m_ret.reply
    RETURN
  END IF

-- Do we have an update server defined?
  LET l_updServer = fgl_getenv("GDCUPDATESERVER")
  IF l_updServer.getLength() > 1 THEN
    CALL useGDCUpdateWS(l_updServer || "/chkgdc?ver=" || l_curGDC || "&os=" || l_osTarget)
  ELSE -- no update server, try a local update
    CALL g2_gdcUpdateCommon.g2_getCurrentGDC() RETURNING l_newGDC, l_newGDCBuild
    IF NOT g2_gdcUpdateCommon.g2_chkIfUpdate(l_curGDC, l_newGDC) THEN
      RETURN
    END IF
    IF NOT g2_gdcUpdateCommon.g2_getUpdateFileName(l_newGDC, l_newGDCBuild, l_osTarget) THEN
      RETURN
    END IF
  END IF

  DISPLAY "Stat:",
      l_stat,
      " Reply:",
      g2_gdcUpdateCommon.m_ret.reply,
      " ReplyStat:",
      g2_gdcUpdateCommon.m_ret.stat
  IF g2_gdcUpdateCommon.m_ret.stat != 1 THEN
    RETURN
  END IF

-- We have a new GDC Update ! confirm with user
  IF g2_lib.g2_winQuestion(
              "GDC Update",
              SFMT(% "%1\nUpdate Now?", g2_gdcUpdateCommon.m_ret.reply),
              "Yes",
              "Yes|No",
              "question")
          = "No"
      THEN
    RETURN
  END IF

  CALL g2_aui.g2_notify(SFMT(% "%1\nPreparing\nPlease Wait ...", g2_gdcUpdateCommon.m_ret.reply))

-- does the GDC update file exist on our server
  LET l_localFile = os.path.join(g2_gdcUpdateCommon.m_gdcUpdateDir, g2_gdcUpdateCommon.m_ret.upd_file)
  IF NOT os.path.exists(l_localFile) THEN
    IF g2_gdcUpdateCommon.m_ret.upd_url IS NOT NULL THEN
      CALL g2_aui.g2_notify(
          SFMT(% "%1\nServer Downloading Update File\nPlease Wait ...", g2_gdcUpdateCommon.m_ret.reply))
      IF NOT getGDCUpdateZipFile(
              l_localFile, g2_gdcUpdateCommon.m_ret.upd_url, g2_gdcUpdateCommon.m_ret.upd_file)
          THEN
        CALL abortGDCUpdate(SFMT(% "Getting GDC Update file failed!\nFile:%1", l_localFile))
        RETURN
      END IF
    ELSE
      CALL abortGDCUpdate(SFMT(% "The GDC Update file is missing!\nFile:%1", l_localFile))
      RETURN
    END IF
  END IF

-- we have a new GDC to update to - a client temp folder name
  CALL ui.Interface.frontcall("standard", "feinfo", "ostype", [l_os])
  CALL ui.Interface.frontcall("standard", "getenv", ["TEMP"], [l_tmp])
  IF l_os = "WINDOWS" THEN
    IF l_tmp.getLength() < 2 THEN
      LET l_tmp = "C:\\TEMP"
    END IF
    LET l_tmp = l_tmp.append("\\")
  ELSE
    IF l_tmp.getLength() < 2 THEN
      LET l_tmp = "/tmp"
    END IF
    LET l_tmp = l_tmp.append("/")
  END IF

-- Put the local GDC update file to the client
  LET l_newFile = l_tmp || g2_gdcUpdateCommon.m_ret.upd_file
  DISPLAY "Put:", l_localFile, " to ", l_newFile
  CALL g2_aui.g2_notify(
      SFMT(% "%1\nClient Downloading Update File\nPlease Wait ...", g2_gdcUpdateCommon.m_ret.reply))
  TRY
    CALL fgl_putfile(l_localFile, l_tmp || g2_gdcUpdateCommon.m_ret.upd_file)
  CATCH
    CALL abortGDCUpdate(
        SFMT(% "Copy of GDC auto update file failed!\nSource:%1\nDest:%2\nErr:%3",
            os.path.join(g2_gdcUpdateCommon.m_ret.upd_dir, g2_gdcUpdateCommon.m_ret.upd_file),
            l_newFile,
            err_get(STATUS)))
    RETURN
  END TRY

  CALL g2_aui.g2_notify("")

-- Trigger the GDC update
  CALL ui.Interface.frontCall("monitor", "update", [l_newFile], [l_ret])
  IF l_ret != 0 THEN
    CALL abortGDCUpdate("GDC Autoupdate Failed!")
  END IF
END FUNCTION
--------------------------------------------------------------------------------
-- Do the web service REST call to check for a new GDC
PRIVATE FUNCTION abortGDCUpdate(l_msg STRING)
  CALL g2_aui.g2_notify("")
  CALL g2_lib.g2_winMessage(% "Error", l_msg, "exclamation")
END FUNCTION
--------------------------------------------------------------------------------
-- Do the web service REST call to check for a new GDC
PRIVATE FUNCTION useGDCUpdateWS(l_url STRING)
  DEFINE l_req com.HttpRequest
  DEFINE l_resp com.HttpResponse
  DEFINE l_stat SMALLINT
  DISPLAY "useGDCUpdateWS URL:", l_url
-- Do Rest call to find out if we have a new GDC Update
  TRY
    LET l_req = com.HttpRequest.Create(l_url)
    CALL l_req.setMethod("GET")
    CALL l_req.setHeader("Content-Type", "application/json")
    CALL l_req.setHeader("Accept", "application/json")
    CALL l_req.doRequest()
    LET l_resp = l_req.getResponse()
    LET l_stat = l_resp.getStatusCode()
    IF l_stat = 200 THEN
      CALL util.JSON.parse(l_resp.getTextResponse(), g2_gdcUpdateCommon.m_ret)
    ELSE
      CALL abortGDCUpdate(
          SFMT("WS chkgdc call failed!\n%1\n%1-%2", l_url, l_stat, l_resp.getStatusDescription()))
    END IF
  CATCH
    LET l_stat = STATUS
    LET g2_gdcUpdateCommon.m_ret.reply = err_get(l_stat)
  END TRY
END FUNCTION
--------------------------------------------------------------------------------
-- get the zip file from a remote server
PRIVATE FUNCTION getGDCUpdateZipFile(
    l_localFile STRING, l_url STRING, l_file STRING)
    RETURNS BOOLEAN
  DEFINE l_cmd STRING

  MESSAGE "Getting GDC zip from " || l_url || "  Please wait ... "
  CALL ui.interface.refresh()

  LET l_cmd = "wget -q -O " || l_localFile || " " || l_url || "/" || l_file
  RUN l_cmd

  IF os.Path.exists(l_localFile) THEN
    RETURN TRUE
  END IF
  RETURN FALSE
END FUNCTION
