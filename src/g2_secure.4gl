#+ Provide function to:
#+ * Handle an encrypted XML config file
#+ * Encrypt / Decrypt a password & salt pair for storing in a databaase
#+
#+ For Genero 3.00:
#+	password encrypted using SHA512 ( with salt + multiple iterations )
#+	you need to store the Salt and the Password hash
#+
#+ For Genero 3.10:
#+	password encrypted using bcrypt ( Blowfish )
#+	you only need to store the Password hash ( bcrypt included salt in hash )
#+
#+ WARNING: the two encryption methods are NOT compatible - so if you start the 3.00 then
#+ upgrade to Genero 3.10 and want to use bcrypt you WILL have to regenerate all the password
#+ hashes for your existing accounts!
#+
#+ This module initially written by: Neil J.Martin ( neilm@4js.com )
#+

IMPORT xml
IMPORT os
IMPORT security
IMPORT util

IMPORT FGL g2_lib
IMPORT FGL g2_encrypt

-- Private variables:
DEFINE m_doc xml.domDocument
DEFINE m_user_node, m_pass_node xml.domNode
DEFINE m_file STRING
DEFINE m_enc encrypt

CONSTANT C_CERTFILE = "../etc/publickey.crt"
CONSTANT C_PRIVATEKEY = "../etc/private.key"
CONSTANT C_DEFPASSLEN = 8
CONSTANT C_SYMBOLS = "!$%^&*,.;@#?<>"
CONSTANT C_SHA_ITERATIONS = 64
--------------------------------------------------------------------------------
#+ Generate a random password that conforms to the follow set of rules:
#+ Password must be at least DEFPASSLEN chars long
#+ Password must contain at least one number
#+ Password must contain at least one symbol
#+
#+ @return String - password
FUNCTION g2_genPassword() RETURNS STRING
  DEFINE l_pass CHAR(C_DEFPASSLEN)
  DEFINE x, y SMALLINT
-- because it's base64 encoded it will return 16 chars or larger!!
  WHILE TRUE
    LET l_pass = security.RandomGenerator.CreateRandomString(C_DEFPASSLEN)
    FOR x = 1 TO C_DEFPASSLEN -- make sure we have at least one number
      IF l_pass[x] MATCHES "[0-9]" THEN
        EXIT WHILE
      END IF
    END FOR
  END WHILE
-- Add a random symbol to the random string.
  CALL util.math.srand()
  LET x = util.math.rand(C_DEFPASSLEN - 1) + 1
  LET y = util.math.rand(C_SYMBOLS.getLength())
  DISPLAY "X:", x, " Y:", y
  LET l_pass[x] = C_SYMBOLS.getCharAt(y)
--	DISPLAY "Pass:",l_pass
  RETURN l_pass
END FUNCTION
--------------------------------------------------------------------------------
#+ Get the hash type
#+
#+ @return string
FUNCTION g2_getHashType() RETURNS STRING
  RETURN "BCRYPT"
END FUNCTION
--------------------------------------------------------------------------------
#+ Generate a salt string
#+
#+ @param  l_hashtype - String -The type of hash to use ( can be NULL for default )
#+ @returns String - salt value
FUNCTION g2_genSalt(l_hashtype STRING) RETURNS STRING
  DEFINE l_salt STRING
  IF l_hashtype IS NULL THEN
    LET l_hashtype = g2_getHashType()
  END IF
  CASE l_hashtype
    WHEN "BCRYPT"
      CALL g2_lib.g2_log.logIt("Generating BCrypt Salt")
      TRY
        LET l_salt = security.BCrypt.GenerateSalt(12)
      CATCH
        CALL g2_lib.g2_log.logIt("ERROR:" || STATUS || ":" || SQLCA.SQLERRM)
      END TRY
    WHEN "SHA512"
      CALL g2_lib.g2_log.logIt("Generating Random Salt")
      LET l_salt = security.RandomGenerator.CreateRandomString(16)
    OTHERWISE
      CALL g2_lib.g2_errPopup(% "Unsupported Encryption Type Requested!")
      EXIT PROGRAM
  END CASE
  CALL g2_lib.g2_log.logIt("Salt Generated:" || l_salt || " (" || l_salt.getLength() || ")")
  RETURN l_salt
END FUNCTION
--------------------------------------------------------------------------------
#+ Generate a hash of a password using a salt string
#+
#+ @param l_pass - String - Password
#+ @param l_salt - String - The salt value ( optional for Genero 3.10 )
#+ @param  l_hashtype - String -The type of hash to use ( can be NULL for default )
#+ @return String - An Encrypted string using SHA512 or BCrypt( Genero 3.10 )
FUNCTION g2_genPasswordHash(l_pass STRING, l_salt STRING, l_hashtype STRING) RETURNS STRING
  DEFINE l_hash STRING
  DEFINE l_dgst security.Digest
  DEFINE x SMALLINT

  LET l_pass = l_pass.trim()
  LET l_salt = l_salt.trim()
  IF l_hashtype IS NULL THEN
    LET l_hashtype = g2_getHashType()
  END IF
  IF l_salt IS NULL THEN
    LET l_salt = g2_genSalt(l_hashtype)
  END IF
  TRY
    CASE l_hashtype
      WHEN "BCRYPT"
        CALL g2_lib.g2_log.logIt("Generating BCrypt HashPassword")
        LET l_hash = Security.BCrypt.HashPassword(l_pass, l_salt)
      WHEN "SHA512"
        CALL g2_lib.g2_log.logIt("Generating " || l_hashtype || " HashPassword")
        LET l_hash = l_pass || l_salt
        FOR x = 1 TO C_SHA_ITERATIONS
          LET l_dgst = security.Digest.CreateDigest(l_hashtype)
          CALL l_dgst.AddStringData(l_hash)
          LET l_hash = l_dgst.DoBase64Digest()
        END FOR
      OTHERWISE
        CALL g2_lib.g2_errPopup(% "Unsupported Encryption Type Requested!")
        EXIT PROGRAM
    END CASE
    CALL g2_lib.g2_log.logIt("Hash created:" || l_hash || " (" || l_hash.getLength() || ")")
  CATCH
    CALL g2_lib.g2_log.logIt("ERROR:" || STATUS || ":" || SQLCA.SQLERRM)
  END TRY

  RETURN l_hash
END FUNCTION
--------------------------------------------------------------------------------
#+ Check the password against it's hash
#+
#+ @param l_pass - String - Password
#+ @param l_passhash - String - Password Hash
#+ @param l_salt - String - The salt value ( not required for BCRYPT )
#+ @param  l_hashtype - String -The type of hash to use ( can be NULL for default )
#+ @return boolean
FUNCTION g2_chkPassword(
    l_pass STRING, l_passhash STRING, l_salt STRING, l_hashtype STRING)
    RETURNS BOOLEAN
  DEFINE l_hash STRING

  LET l_pass = l_pass.trim()
  LET l_passhash = l_passhash.trim()
  IF l_hashtype IS NULL THEN
    LET l_hashtype = g2_getHashType()
  END IF
  CASE l_hashtype
    WHEN "BCRYPT"
      CALL g2_lib.g2_log.logIt("checking password using BCRYPT")
      TRY
        IF Security.BCrypt.CheckPassword(l_pass, l_passhash) THEN
          CALL g2_lib.g2_log.logIt("Password checked okay.")
          RETURN TRUE
        END IF
      CATCH
        CALL g2_lib.g2_log.logIt("ERROR:" || STATUS || ":" || SQLCA.SQLERRM)
      END TRY
    WHEN "SHA512"
      CALL g2_lib.g2_log.logIt("checking password using " || l_hashtype)
      LET l_hash = g2_genPasswordHash(l_pass, l_salt, l_hashtype)
      IF l_hash = l_passhash THEN
        CALL g2_lib.g2_log.logIt("Password checked okay.")
        RETURN TRUE
      END IF
    OTHERWISE
      CALL g2_lib.g2_errPopup(% "Unsupported Encryption Type Requested!")
      EXIT PROGRAM
  END CASE

  CALL g2_lib.g2_log.logIt("Password checked failed.")
  RETURN FALSE
END FUNCTION
--------------------------------------------------------------------------------
#+ Get the password rules as a string
#+
#+ @param l_max Max length of the password as stored in DB.
#+ @returns string of the rules
FUNCTION g2_passwordRules(l_max INTEGER) RETURNS STRING
  RETURN SFMT(% "The password must confirm to the following rules:\n"
          || "At least %1 characters, max is %2\n"
          || "At least 1 lower case letter and 1 upper case letter\n"
          || "At least 1 number and at least 1 symbol from the this list: %3",
      C_DEFPASSLEN, l_max, C_SYMBOLS)
END FUNCTION
--------------------------------------------------------------------------------
#+ Validate that the password is legal.
#+
#+ @param l_pass Password to validate.
#+ @returns String with "Okay" or an Error message is the password is not legal.
FUNCTION g2_isPasswordLegal(l_pass STRING) RETURNS STRING
  DEFINE l_gotUp, l_gotLow, l_gotNum, l_gotSym BOOLEAN
  DEFINE x, y SMALLINT

  IF l_pass IS NULL THEN
    RETURN % "Password can't be NULL"
  END IF
  IF l_pass.getLength() < C_DEFPASSLEN THEN
    RETURN SFMT(% "Password is less than %1 characters", C_DEFPASSLEN)
  END IF

  LET l_gotNum = FALSE
  LET l_gotUp = FALSE
  LET l_gotLow = FALSE
  LET l_gotSym = FALSE

  --DISPLAY "Pass:",l_pass
  FOR x = 1 TO length(l_pass)
    IF l_pass.getCharAt(x) >= "0" AND l_pass.getCharAt(x) <= "9" THEN
      LET l_gotNum = TRUE
      CONTINUE FOR
    END IF
    IF l_pass.getCharAt(x) >= "A" AND l_pass.getCharAt(x) <= "Z" THEN
      LET l_gotUp = TRUE
      CONTINUE FOR
    END IF
    IF l_pass.getCharAt(x) >= "a" AND l_pass.getCharAt(x) <= "z" THEN
      LET l_gotLow = TRUE
      CONTINUE FOR
    END IF
    LET y = 1
    WHILE y <= C_SYMBOLS.getLength()
      --DISPLAY "Symbol check:",l_pass[x]," sym:",c_sym.getCharAt(y)
      IF l_pass.getCharAt(x) = C_SYMBOLS.getCharAt(y) THEN
        LET l_gotSym = TRUE
        CONTINUE FOR
      END IF
      LET y = y + 1
    END WHILE
    ERROR % "Password contains an iilegal character:", l_pass.getCharAt(x)
  END FOR

  IF NOT l_gotUp OR NOT l_gotLow THEN
    RETURN % "Password must contain a mix of upper and lower case letters."
  END IF
  IF NOT l_gotNum THEN
    RETURN % "Password must contain at least one number."
  END IF
  IF NOT l_gotSym THEN
    RETURN SFMT(% "Password must contain at least one symbol: %1.", C_SYMBOLS)
  END IF

  RETURN "Okay"
END FUNCTION
--------------------------------------------------------------------------------
#+ Get a string from base64 string or raise an error prompt
#+
#+ @param l_str - String
#+ @return String or NULL if failed.
FUNCTION g2_fromBase64(l_str STRING) RETURNS STRING

  IF l_str IS NULL THEN
    RETURN NULL
  END IF
  TRY
    LET l_str = security.Base64.toString(l_str)
  CATCH
    CALL g2_lib.g2_errPopup(% "Error in security module!\n" || SQLCA.SQLERRM)
    LET l_str = NULL
  END TRY

  RETURN l_str
END FUNCTION
--------------------------------------------------------------------------------
#+ Get base64 version of a string or raise an error prompt
#+
#+ @param l_str - String
#+ @return String or NULL if failed.
FUNCTION g2_toBase64(l_str STRING) RETURNS STRING

  IF l_str IS NULL THEN
    RETURN NULL
  END IF
  TRY
    LET l_str = security.Base64.fromString(l_str)
  CATCH
    CALL g2_lib.g2_errPopup(% "Error in security module!\n" || SQLCA.SQLERRM)
    LET l_str = NULL
  END TRY

  RETURN l_str
END FUNCTION
--------------------------------------------------------------------------------
#+ Retrieve a username/password combination from an encrypted xml config file
#+
#+ @param l_typ - String - The type of the data to return, eg: EMAIL / SMS provider creds
#+ @returns - Strings : username, password
FUNCTION g2_getCreds(l_typ STRING) RETURNS(STRING, STRING)
  DEFINE l_user, l_pwd STRING
  DEFINE l_node xml.DomNode
  DEFINE l_enc xml.Encryption
  DEFINE l_symkey xml.CryptoKey
  DEFINE l_list xml.DomNodeList
  DEFINE l_key CHAR(32)

  IF m_file.getLength() < 2 THEN
    CALL get_credFile()
  END IF

  LET l_key = seclogit()

  LET m_doc = xml.DomDocument.Create()
# Notice that whitespaces are significants in crytography,
# therefore it is recommended to remove unnecessary whitespace.
  CALL m_doc.setFeature("whitespace-in-element-content", FALSE)
  TRY
    # Load encrypted XML file
    --DISPLAY "Loading xml ..."
    CALL m_doc.load(m_file)
    # Retrieve encrypted l_node (if any) from the document
    LET l_list = m_doc.getElementsByTagNameNS("EncryptedData", "http://www.w3.org/2001/04/xmlenc#")
    IF l_list.getCount() == 1 THEN
      LET l_node = l_list.getItem(1)
    ELSE
      CALL g2_lib.g2_log.logIt("No encrypted l_node found")
      EXIT PROGRAM 210
    END IF
    # Check if symmetric key name matches the expected "MySecretKey" (Not mandatory)
    --DISPLAY "Looking for key name ..."
    LET l_list =
        l_node.selectByXPath(
            "dsig:KeyInfo/dsig:KeyName[position()=1 and text()=\"MySecretKey\"]",
            "dsig",
            "http://www.w3.org/2000/09/xmldsig#")
    IF l_list.getCount() != 1 THEN
      CALL g2_lib.g2_log.logIt("Key name doesn't match")
      EXIT PROGRAM 211
    END IF
  CATCH
    CALL g2_lib.g2_log.logIt("Unable to load / process XML file :" || STATUS || ":" || err_get(STATUS))
    EXIT PROGRAM 212
  END TRY

  TRY
    # Create symmetric AES256 key for XML decryption purpose
    LET l_symkey = xml.CryptoKey.Create("http://www.w3.org/2001/04/xmlenc#aes256-cbc")
    CALL l_symkey.setKey(l_key) # password of 256 bits
    # Decrypt the entire document
    LET l_enc = xml.Encryption.Create()
    CALL l_enc.setKey(l_symkey) # Set the symmetric key to be used
    CALL l_enc.decryptElement(l_node) # Decrypt
    # Save encrypted document back to disk
    CALL m_doc.setFeature("format-pretty-print", TRUE)
    --CALL l_doc.save("DecryptedXMLFile.xml")
    --DISPLAY l_doc.saveToString()
    --DISPLAY "Successful decrypted"
  CATCH
    CALL g2_lib.g2_log.logIt("Unable to decrypt XML file :" || STATUS || ":" || err_get(STATUS))
    EXIT PROGRAM 213
  END TRY

  LET l_list = m_doc.selectByXPath("//" || l_typ || "/user", "")
  IF l_list.getCount() < 1 THEN
    --DISPLAY "Failed to find:",l_typ
  ELSE
    LET l_node = l_list.getItem(1)
    LET m_user_node = l_node.getFirstChild()
    LET l_user = m_user_node.getNodeValue()
    --DISPLAY l_typ," User:",l_usr
  END IF

  LET l_list = m_doc.selectByXPath("//" || l_typ || "/password", "")
  IF l_list.getCount() < 1 THEN
    --DISPLAY "Failed to find:",l_typ
  ELSE
    LET l_node = l_list.getItem(1)
    LET m_pass_node = l_node.getFirstChild()
    LET l_pwd = m_pass_node.getNodeValue()
    --DISPLAY l_typ," Pass:",l_pwd
  END IF

  RETURN l_user, l_pwd
END FUNCTION
--------------------------------------------------------------------------------
#+ Update creditials in an encrypted XML File
#+
#+ @param l_typ - String - The type of the data to return, eg: EMAIL / SMS provider creds
#+ @param l_user - String - Username
#+ @param l_pass - String - Password
#+ @returns boolean
FUNCTION g2_updCreds(l_typ STRING, l_user STRING, l_pass STRING) RETURNS BOOLEAN
  DEFINE l_old_usr, l_old_pass STRING
  DEFINE l_root xml.DomNode
  DEFINE enc xml.Encryption
  DEFINE symkey xml.CryptoKey
  DEFINE l_myKey CHAR(32)
  DEFINE l_dte STRING

  CALL g2_getCreds(l_typ) RETURNING l_old_usr, l_old_pass

  LET l_myKey = seclogit()

  LET l_dte = util.Datetime.format(CURRENT, "%Y%m%d%H%M")
  TRY
    LET l_root = m_doc.getDocumentElement()
    CALL m_user_node.setNodeValue(l_user)
    CALL m_pass_node.setNodeValue(l_pass)
    # CALL m_doc.save("DecryptedXMLFile.xml")
    IF NOT os.Path.rename(m_file, m_file || l_dte) THEN
      CALL g2_lib.g2_log.logIt("Failed to backup creds file:" || STATUS || ":" || err_get(STATUS))
      RETURN FALSE
    END IF
    # Create symmetric AES256 key for XML encryption purposes
    LET symkey = xml.CryptoKey.Create("http://www.w3.org/2001/04/xmlenc#aes256-cbc")
    CALL symkey.setKey(l_mykey) # password of 256 bits
    CALL symKey.setFeature(
        "KeyName", "MySecretKey") # Name the password in order to identify the key (Not mandatory)
    # Encrypt the entire document
    LET enc = xml.Encryption.Create()
    CALL enc.setKey(symkey) # Set the symmetric key to be used
    CALL enc.encryptElement(l_root) # Encrypt
    # Save encrypted document back to disk
    CALL m_doc.save(m_file)
  CATCH
    CALL g2_lib.g2_log.logIt("Unable to encrypt XML file :" || STATUS || ":" || err_get(STATUS))
    RETURN FALSE
  END TRY
  RETURN TRUE
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION g2_saveSession(l_id STRING, l_user STRING) RETURNS ()
  DEFINE l_val STRING

  IF ui.interface.getFrontEndName() = "GGC" THEN
    RETURN
  END IF
  IF NOT g2_lib.g2_chkClientVer("GDC", "3.10.18", "localeStorage") THEN
    RETURN
  END IF
  CALL m_enc.init(C_CERTFILE, C_PRIVATEKEY)
  LET l_val = m_enc.encrypt(CURRENT YEAR TO MINUTE || "|" || l_user)
  IF l_val IS NOT NULL THEN
    CALL g2_lib.g2_log.logIt(SFMT("Save Session id=%1 val=%2", l_id, l_val))
    CALL ui.Interface.frontCall("localStorage", "setItem", [l_id, l_val], [])
  END IF
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION g2_getSession(l_id STRING, l_age INTEGER) RETURNS STRING
  DEFINE l_val STRING
  DEFINE l_ts DATETIME YEAR TO MINUTE
  DEFINE x SMALLINT
  IF ui.interface.getFrontEndName() = "GGC" THEN
    RETURN NULL
  END IF
  IF NOT g2_lib.g2_chkClientVer("GDC", "3.10.18", "localeStorage") THEN
    RETURN NULL
  END IF
  IF NOT os.Path.readable(C_PRIVATEKEY) THEN
    CALL g2_lib.g2_winMessage(
        "Warning", "Private key file can not be read!\nAuto login not available.", "information")
    RETURN NULL
  END IF
  CALL m_enc.init(C_CERTFILE, C_PRIVATEKEY)
	TRY
		DISPLAY "localStorage - getItem..."
		CALL ui.Interface.frontCall("localStorage", "getItem", l_id, l_val)
		DISPLAY "localStorage - getItem done"
	CATCH
		CALL g2_lib.g2_errPopup("localStorage - getItem Failed!")
		RETURN NULL
	END TRY
  CALL g2_lib.g2_log.logIt(SFMT("Get Session id=%1 val=%2", l_id, l_val))
  IF l_val IS NULL THEN
    RETURN NULL
  END IF
  LET l_val = m_enc.decrypt(l_val)
--	CALL g2_lib.g2_logIt(SFMT("Get Session val=%1",l_val))
  LET x = l_val.getIndexOf("|", 1)
  LET l_ts = l_val.subString(1, x - 1)
  IF l_ts IS NULL THEN
    RETURN NULL
  END IF
  --DISPLAY "TS:",l_ts," CURR:",CURRENT YEAR TO MINUTE, " Calcd:",( CURRENT - l_age UNITS MINUTE )
  IF (CURRENT - l_age UNITS MINUTE) > l_ts THEN
    RETURN "expired"
  END IF
  LET l_id = l_val.subString(x + 1, l_val.getLength())
  RETURN l_id
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION g2_removeSession(l_id STRING)

  IF ui.interface.getFrontEndName() = "GGC" THEN
    RETURN
  END IF
  IF NOT g2_lib.g2_chkClientVer("GDC", "3.10.18", "localeStorage") THEN
    RETURN
  END IF

  CALL ui.Interface.frontCall("localStorage", "removeItem", [l_id], [])

END FUNCTION
--------------------------------------------------------------------------------
--  PRIVATE FUNCTIONS
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Obfuscation Code
PRIVATE FUNCTION secchk(l_s STRING) RETURNS STRING
  DEFINE l_e STRING
  DEFINE x SMALLINT
  FOR x = 11 TO 4 STEP -1
    LET l_e = l_e.append(l_s.getCharAt(x))
  END FOR
  RETURN l_e
END FUNCTION
--------------------------------------------------------------------------------
-- obfuscate our key
{PRIVATE}
FUNCTION seclogit() RETURNS STRING
  DEFINE s1, s2, s3, s4 STRING
--TODO: fixme
  LET s1 =
      ASCII (62),
      ASCII (68),
      ASCII (62),
      ASCII (64),
      ASCII (66),
      ASCII (67),
      ASCII (69),
      ASCII (68),
      ASCII (68),
      ASCII (67),
      ASCII (66),
      ASCII (62),
      ASCII (62),
      ASCII (60),
      ASCII (60),
      ASCII (62)
  LET s2 =
      ASCII (67),
      ASCII (66),
      ASCII (62),
      ASCII (61),
      ASCII (67),
      ASCII (64),
      ASCII (69),
      ASCII (64),
      ASCII (60),
      ASCII (60),
      ASCII (62),
      ASCII (67),
      ASCII (62),
      ASCII (61),
      ASCII (64),
      ASCII (67)
  LET s3 =
      ASCII (62),
      ASCII (68),
      ASCII (62),
      ASCII (64),
      ASCII (66),
      ASCII (67),
      ASCII (69),
      ASCII (68),
      ASCII (68),
      ASCII (67),
      ASCII (66),
      ASCII (62),
      ASCII (62),
      ASCII (60),
      ASCII (60),
      ASCII (62)
  LET s4 =
      ASCII (67),
      ASCII (66),
      ASCII (62),
      ASCII (61),
      ASCII (67),
      ASCII (64),
      ASCII (69),
      ASCII (64),
      ASCII (60),
      ASCII (60),
      ASCII (62),
      ASCII (67),
      ASCII (62),
      ASCII (61),
      ASCII (64),
      ASCII (67)

  RETURN secchk(s1) || secchk(s2) || secchk(s3) || secchk(s4)
END FUNCTION
--------------------------------------------------------------------------------
-- Used to generate obfuscation code
PRIVATE FUNCTION b(s STRING) RETURNS STRING
  DEFINE r STRING
  DEFINE x, c SMALLINT
  FOR x = 1 TO s.getLength()
    FOR c = 12 TO 127
      IF s.getCharAt(x) = ASCII (c) THEN
        LET r = r.append("ASCII(" || c || "),")
      END IF
    END FOR
  END FOR
  RETURN r
END FUNCTION
--------------------------------------------------------------------------------
#+ Sets the m_file module variable and validates that the file exists.
PRIVATE FUNCTION get_credFile() RETURNS ()
  LET m_file = "../etc/.creds.xml"
  IF NOT os.Path.exists(m_file) THEN
    CALL g2_lib.g2_log.logIt("Creditials File is Missing!")
  ELSE
    CALL g2_lib.g2_log.logIt("Creditials File is " || m_file)
  END IF
END FUNCTION
