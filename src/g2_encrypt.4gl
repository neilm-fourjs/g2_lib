-- Library to encrypt a String with a cert and private key.

IMPORT xml
IMPORT security

IMPORT FGL g2_lib

PUBLIC TYPE encrypt RECORD
		certFile STRING,
		privateKey STRING,
		errorMessage STRING
	END RECORD


FUNCTION (this encrypt) init(l_cert STRING, l_key STRING)
  LET this.certFile = l_cert
  LET this.privateKey = l_key
END FUNCTION
--------------------------------------------------------------------------------
#+ Encrypt a string using a certificate
#+
#+ @param l_str String to encrypt
#+ @returns NULL is fails
FUNCTION (this encrypt) encrypt(l_str STRING) RETURNS STRING
  DEFINE l_doc xml.DomDocument
  DEFINE l_root, l_str_node xml.DomNode
  DEFINE l_enc xml.Encryption
  DEFINE l_symkey xml.CryptoKey
  DEFINE l_kek xml.CryptoKey
  DEFINE l_cert xml.CryptoX509

	IF this.certFile IS NULL THEN
		CALL this.g2_encryptError("Certificate file name is NULL!")
		RETURN NULL
	END IF
	IF this.privateKey IS NULL THEN
		CALL this.g2_encryptError("Private key is NULL!")
		RETURN NULL
	END IF

  LET l_doc = xml.DomDocument.CreateDocument("encrypedxml")
  # Notice that whitespaces are significants in crytography,
  # therefore it is recommended to remove unnecessary ones
  CALL l_doc.setFeature("whitespace-in-element-content", FALSE)
  TRY
    # Create the XML to be l_encrypted
    LET l_root = l_doc.getFirstDocumentNode()
    LET l_str_node = l_doc.createElement("Value")
    CALL l_str_node.appendChild(l_doc.createTextNode(l_str))
    CALL l_root.appendChild(l_str_node)
  CATCH
    CALL this.g2_encryptError(
        SFMT(% "Error building XML from '%1':%2:%3", l_str, STATUS, err_get(STATUS)))
    RETURN NULL
  END TRY
  TRY
    # Load the X509 certificate and retrieve the public RSA key for key-encryption purpose
    LET l_cert = xml.CryptoX509.Create()
    CALL l_cert.loadPEM(this.certFile)
    LET l_kek = l_cert.createPublicKey("http://www.w3.org/2001/04/xmlenc#rsa-1_5")
    # Generate symmetric key for XML l_encryption purpose
  CATCH
    CALL this.g2_encryptError(
        SFMT(% "Error with certificate '%1':%2:%3", this.certFile, STATUS, err_get(STATUS)))
    RETURN NULL
  END TRY
  TRY
    LET l_symkey = xml.CryptoKey.Create("http://www.w3.org/2001/04/xmlenc#aes256-cbc")
    CALL l_symkey.generateKey(NULL)
    # Encrypt the entire l_document
    LET l_enc = xml.Encryption.Create()
    CALL l_enc.setKey(l_symkey) # Set the symmetric key to be used
    CALL l_enc.setKeyEncryptionKey(
        l_kek) # Set the key-encryption key to be used for protecting the symmetric key
    CALL l_enc.encryptElement(l_root) # Encrypt
    RETURN security.Base64.FromString(l_doc.saveToString())
  CATCH
    CALL this.g2_encryptError(SFMT(% "Unable to l_encrypt XML file %1:%2", STATUS, err_get(STATUS)))
    RETURN NULL
  END TRY
END FUNCTION
--------------------------------------------------------------------------------
#+ Decrypt a string using a private key
#+
#+ @param l_str String to decrypt
#+ @returns NULL is fails
--------------------------------------------------------------------------------
FUNCTION (this encrypt) decrypt(l_str STRING) RETURNS STRING
  DEFINE l_doc xml.DomDocument
  DEFINE l_root xml.DomNode
  DEFINE l_enc xml.Encryption
  DEFINE l_kek xml.CryptoKey
  DEFINE l_list xml.DomNodeList

  LET l_str = security.Base64.toString(l_str)
  LET l_doc = xml.DomDocument.Create()
  # Notice that whitespaces are significants in crytography,
  # therefore it is recommended to remove unnecessary ones
  CALL l_doc.setFeature("whitespace-in-element-content", FALSE)
  TRY
    # Load l_encrypted XML file								
    CALL l_doc.loadFromString(l_str)
    LET l_root = l_doc.getFirstDocumentNode()
--		DISPLAY "Decrypt XML:",l_root.toString()
  CATCH
    CALL this.g2_encryptError(
        SFMT(% "Error Loading XML from '%1':%2:%3", l_str, STATUS, err_get(STATUS)))
    RETURN NULL
  END TRY
  TRY
    # Load the private RSA key
    LET l_kek = xml.CryptoKey.create("http://www.w3.org/2001/04/xmlenc#rsa-1_5")
    CALL l_kek.loadPEM(this.privateKey)
  CATCH
    CALL this.g2_encryptError(
        SFMT(% "Error with private key '%1':%2:%3", this.privateKey, STATUS, err_get(STATUS)))
    RETURN NULL
  END TRY
  TRY
    # Decrypt the entire document
    LET l_enc = xml.Encryption.Create()
    CALL l_enc.setKeyEncryptionKey(
        l_kek) # Set the key-encryption key to decrypted the protected symmetric key
    CALL l_enc.decryptElement(l_root) # Decrypt
  CATCH
    CALL this.g2_encryptError(SFMT(% "Unable to decrypt XML file %1:%2", STATUS, err_get(STATUS)))
    RETURN NULL
  END TRY
  LET l_list = l_doc.getElementsByTagName("Value")
  IF l_list.getCount() = 1 THEN
    RETURN l_list.getItem(1).getFirstChild().getNodeValue()
  ELSE
    CALL this.g2_encryptError("No Value found")
  END IF
  RETURN NULL

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION (this encrypt) g2_encryptError(l_msg STRING)
  LET this.errorMessage = l_msg
  CALL g2_lib.g2_log.logIt(l_msg)
END FUNCTION
--------------------------------------------------------------------------------
