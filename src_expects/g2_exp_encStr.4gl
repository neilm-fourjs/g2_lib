IMPORT security
IMPORT FGL g2_lib.g2_encrypt
MAIN
    DEFINE l_str STRING
    DEFINE l_enc_str STRING
    DEFINE l_denc_str STRING
    DEFINE l_pass CHAR(32)
    DEFINE l_enc encrypt
    LET l_str = "Hello World"
    
    DISPLAY "Test Encrypt - default password"
    LET l_enc_str = l_enc.g2_encStringPasswd( l_str, NULL )
    IF l_enc_str IS NULL THEN
        DISPLAY SFMT("Failed: %1", l_enc.errorMessage )
    ELSE
        DISPLAY SFMT("Result: %1", l_enc_str)
    END IF
    
    DISPLAY "Test Decrypt - default password"
    LET l_denc_str = l_enc.g2_decStringPasswd( l_enc_str, NULL )
    IF l_denc_str IS NULL THEN
        DISPLAY SFMT("Failed: %1", l_enc.errorMessage )
    ELSE
        DISPLAY SFMT("Result: %1", l_denc_str)
    END IF

    DISPLAY "Test Decrypt - invalid password"
    LET l_pass = "this is an invalid password and should fail to decrypted"
    LET l_denc_str = l_enc.g2_decStringPasswd( l_enc_str, l_pass )
    IF l_denc_str IS NULL THEN
        DISPLAY SFMT("Failed: %1", l_enc.errorMessage )
    ELSE
        DISPLAY SFMT("Result: %1", l_denc_str)
    END IF

    LET l_pass = security.Base64.FromString("this is a test password")
    DISPLAY "Test Encrypt - custom password"
    LET l_enc_str = l_enc.g2_encStringPasswd( l_str, l_pass )
    IF l_enc_str IS NULL THEN
        DISPLAY SFMT("Failed: %1", l_enc.errorMessage )
    ELSE
        DISPLAY SFMT("Result: %1", l_enc_str)
    END IF
    
    DISPLAY "Test Decrypt - custom password"
    LET l_denc_str = l_enc.g2_decStringPasswd( l_enc_str, l_pass )
    IF l_denc_str IS NULL THEN
        DISPLAY SFMT("Failed: %1", l_enc.errorMessage )
    ELSE
        DISPLAY SFMT("Result: %1", l_denc_str)
    END IF
END MAIN