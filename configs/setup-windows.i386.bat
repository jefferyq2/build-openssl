@echo off
CALL "%VCVAR_DIR%\vcvarsall.bat" x86 || exit /B %ERRORLEVEL%
SET PLATFORM_DEFINITION=defined^^^(_WIN32^^^) ^^^&^^^& defined^^^(_M_IX86^^^)
SET OPENSSL_CONFIGURE_NAME=VC-WIN32
exit /B 0
