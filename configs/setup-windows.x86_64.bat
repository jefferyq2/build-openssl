@echo off
CALL "%VCVAR_DIR%\vcvarsall.bat" amd64 || exit /B %ERRORLEVEL%
SET PLATFORM_DEFINITION=defined^^^(_WIN32^^^) ^^^&^^^& defined^^^(_M_AMD64^^^)
SET OPENSSL_CONFIGURE_NAME=VC-WIN64A
exit /B 0
