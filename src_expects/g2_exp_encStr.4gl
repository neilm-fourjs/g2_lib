
IMPORT FGL g2_encrypt
MAIN
    DEFINE l_str STRING
    DEFINE l_enc_str STRING
    DEFINE l_denc_str STRING
    DEFINE l_enc encrypt
    LET l_str = "Hello World"
    
    LET l_enc_str = l_enc.g2_encStringPasswd( l_str )
    IF l_enc_str IS NULL THEN
        DISPLAY SFMT("Failed: %1", l_enc.errorMessage )
    ELSE
        DISPLAY SFMT("Result: %1", l_enc_str)
    END IF
    
    LET l_denc_str = l_enc.g2_dencStringPasswd( l_enc_str )
    IF l_denc_str IS NULL THEN
        DISPLAY SFMT("Failed: %1", l_enc.errorMessage )
    ELSE
        DISPLAY SFMT("Result: %1", l_denc_str)
    END IF
END MAIN