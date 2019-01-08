@echo off
IF NOT EXIST "%VCVAR_DIR%\vcvarsall.bat" (
    echo Cannot set VCVARS from "%VCVAR_DIR%\vcvarsall.bat"> 1&2
    echo. 1>2
    exit /B 1
)
IF "%MIN_WIN_NT_VERSION%"=="" SET MIN_WIN_NT_VERSION=0x0A00
SET CFLAGS=-DWINVER=%MIN_WIN_NT_VERSION% -D_WIN32_WINNT=%MIN_WIN_NT_VERSION%

exit /B 0
