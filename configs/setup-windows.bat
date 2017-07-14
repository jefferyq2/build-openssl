@echo off
IF NOT EXIST "%VCVAR_DIR%\vcvarsall.bat" (
    echo Cannot set VCVARS from "%VCVAR_DIR%\vcvarsall.bat"> 1&2
    echo. 1>2
    exit /B 1
)
exit /B 0
