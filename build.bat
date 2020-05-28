@ECHO OFF &SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
SETLOCAL

SET BUILD_DIR=%~dp0
SET SCRIPT_NAME=%~0

:: Overridable build locations
IF "%DEFAULT_OPENSSL_DIST%"=="" SET DEFAULT_OPENSSL_DIST=%BUILD_DIR%\openssl
IF "%OBJDIR_ROOT%"=="" SET OBJDIR_ROOT=%BUILD_DIR%\target
IF "%CONFIGS_DIR%"=="" SET CONFIGS_DIR=%BUILD_DIR%\configs

:: Options to control the build
IF "%MSVC_VERSION%"=="" (
    SET MSVC_VERSION_INT=14.2
    SET BUILD_PLATFORM_NAME=windows
) ELSE (
    SET MSVC_VERSION_INT=%MSVC_VERSION%
    SET BUILD_PLATFORM_NAME=windows-msvc-%MSVC_VERSION%
)
IF "%MSVC_VERSION_INT%"=="14.2" (
    SET VCVAR_ENTERPRISE_DIR=C:\Program Files (x86^)\Microsoft Visual Studio\2019\Enterprise\VC\Auxiliary\Build
    SET VCVAR_PROFESSIONAL_DIR=C:\Program Files (x86^)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build
    IF EXIST "!VCVAR_ENTERPRISE_DIR!" (
        SET VCVAR_DIR=!VCVAR_ENTERPRISE_DIR!
    ) ELSE IF EXIST "!VCVAR_PROFESSIONAL_DIR!" (
        SET VCVAR_DIR=!VCVAR_PROFESSIONAL_DIR!
    ) ELSE (
        echo Uninstalled MSVC for "%MSVC_VERSION_INT%". 1>&2
        echo. 1>&2
        GOTO print_usage
    )
) ELSE IF "%MSVC_VERSION_INT%"=="14.1" (
    SET VCVAR_ENTERPRISE_DIR=C:\Program Files (x86^)\Microsoft Visual Studio\2017\Enterprise\VC\Auxiliary\Build
    SET VCVAR_PROFESSIONAL_DIR=C:\Program Files (x86^)\Microsoft Visual Studio\2017\Professional\VC\Auxiliary\Build
    IF EXIST "!VCVAR_ENTERPRISE_DIR!" (
        SET VCVAR_DIR=!VCVAR_ENTERPRISE_DIR!
    ) ELSE IF EXIST "!VCVAR_PROFESSIONAL_DIR!" (
        SET VCVAR_DIR=!VCVAR_PROFESSIONAL_DIR!
    ) ELSE (
        echo Uninstalled MSVC for "%MSVC_VERSION_INT%". 1>&2
        echo. 1>&2
        GOTO print_usage
    )
) ELSE IF "%MSVC_VERSION_INT%"=="14.0" (
    SET VCVAR_DIR=C:\Program Files (x86^)\Microsoft Visual Studio 14.0\VC
) ELSE (
    echo Unsupported MSVC version "%MSVC_VERSION_INT%". 1>&2
    echo. 1>&2
    GOTO print_usage
)

:: Options for OpenSSL
IF "%COMMON_OPENSSL_BUILD_OPTIONS%"=="" SET COMMON_OPENSSL_BUILD_OPTIONS=no-shared no-pinshared
IF "%OPENSSL_BUILD_OPTIONS%"=="" SET OPENSSL_BUILD_OPTIONS=no-afalgeng          ^
                                                           no-aria              ^
                                                           no-blake2            ^
                                                           no-camellia          ^
                                                           no-capieng           ^
                                                           no-cast              ^
                                                           no-chacha            ^
                                                           no-cmac              ^
                                                           no-cms               ^
                                                           no-ct                ^
                                                           no-deprecated        ^
                                                           no-des               ^
                                                           no-dtls              ^
                                                           no-dtls1-method      ^
                                                           no-dtls1_2-method    ^
                                                           no-engine            ^
                                                           no-filenames         ^
                                                           no-gost              ^
                                                           no-heartbeats        ^
                                                           no-hw-padlock        ^
                                                           no-idea              ^
                                                           no-md2               ^
                                                           no-md4               ^
                                                           no-mdc2              ^
                                                           no-nextprotoneg      ^
                                                           no-ocb               ^
                                                           no-poly1305          ^
                                                           no-rc2               ^
                                                           no-rc4               ^
                                                           no-rc5               ^
                                                           no-rdrand            ^
                                                           no-rfc3779           ^
                                                           no-rmd160            ^
                                                           no-scrypt            ^
                                                           no-sctp              ^
                                                           no-seed              ^
                                                           no-siphash           ^
                                                           no-sm2               ^
                                                           no-sm3               ^
                                                           no-sm4               ^
                                                           no-srp               ^
                                                           no-srtp              ^
                                                           no-ssl               ^
                                                           no-ssl3-method       ^
                                                           no-static-engine     ^
                                                           no-tests             ^
                                                           no-whirlpool         ^
                                                           no-zlib

:: Include files which are platform-specific
SET PLATFORM_SPECIFIC_HEADERS=openssl^\opensslconf.h

:: Calculate the path to the openssl-dist repository
IF EXIST "%~f1" (
	SET PATH_TO_OPENSSL_DIST=%~f1
	SHIFT
) ELSE (
	SET PATH_TO_OPENSSL_DIST=%DEFAULT_OPENSSL_DIST%
)
IF NOT EXIST "%PATH_TO_OPENSSL_DIST%\Configure" (
    echo Invalid OpenSSL directory: 1>&2
    echo     "%PATH_TO_OPENSSL_DIST%" 1>&2
    GOTO print_usage
)

:: Check for perl to be installed
perl -e1 2>NUL || (
    echo Perl is not installed, but is required. 1>&2
    echo. 1>&2
    GOTO print_usage
)

:: Check for active perl to be installed
perl -v | findstr -i MSWin32 >NUL || (
    echo Perl is not installed, but it is not Active Perl. 1>&2
    echo. 1>&2
    GOTO print_usage
)

:: Check for NASM to be installed
nasm -h >NUL 2>NUL || (
    echo NASM is not installed, but is required. 1>&2
    echo. 1>&2
    GOTO print_usage
)

:: Set up the target and the command-line arguments
SET TARGET=%1
SHIFT
:GetArgs
IF "%~1" NEQ "" (
    SET CL_ARGS=%CL_ARGS% %1
    SHIFT
    GOTO GetArgs
)
IF DEFINED CL_ARGS SET CL_ARGS=%CL_ARGS:~1%

:: Call the appropriate function based on target
IF "%TARGET%"=="clean" (
    CALL :do_clean %CL_ARGS% || exit /B 1
) ELSE (
    CALL :do_build %TARGET% %CL_ARGS% || exit /B 1
)
:: Success
exit /B 0


:print_usage
    echo Usage: %SCRIPT_NAME% \path\to\openssl-dist ^<arch^|'clean'^> 1>&2
    echo. 1>&2
    echo "\path\to\openssl-dist" is optional and defaults to: 1>&2
    echo     "%DEFAULT_OPENSSL_DIST%" 1>&2
    echo. 1>&2
    CALL :get_archs
    echo Possible architectures are:
    echo     !ARCHS: =, ! 1>&2
    echo. 1>&2
    echo When specifying clean, you may optionally include an arch to clean, 1>&2
    echo i.e. "%SCRIPT_NAME% clean i386" to clean only the i386 architecture. 1>&2
    echo. 1>&2
@exit /B 1

:get_archs
    @ECHO OFF
    SET ARCHS=
    FOR %%F IN ("%CONFIGS_DIR%\setup-windows.*.bat") DO (
        SET ARCH=%%~nF
        SET ARCHS=!ARCHS! !ARCH:setup-windows.=!
    )
    IF DEFINED ARCHS SET ARCHS=%ARCHS:~1%
@exit /B 0

:do_make_openssl
    perl "%PATH_TO_OPENSSL_DIST%\Configure" %~1 %~3 ^
                                            %COMMON_OPENSSL_BUILD_OPTIONS% ^
                                            %OPENSSL_BUILD_OPTIONS% ^
                                            --prefix="%~2" ^
                                            --openssldir="%~2" || exit /B %ERRORLEVEL%
    nmake install_sw || exit /B %ERRORLEVEL%
@exit /B 0

:do_build_openssl
    @ECHO OFF
    SET TARGET=%~1
    SET OUTPUT_ROOT=%~2
    SET BUILD_ROOT=%OUTPUT_ROOT%\build\openssl

    IF "%PLATFORM_DEFINITION%"=="" (
        echo PLATFORM_DEFINITION is not set for %TARGET% & exit /B 1
    )
    IF "%OPENSSL_CONFIGURE_NAME%"=="" (
        echo OPENSSL_CONFIGURE_NAME is not set for %TARGET% & exit /B 1
    )
    
    IF NOT EXIST "%BUILD_ROOT%" (
        echo Creating build directory for %TARGET%...
        mkdir "%BUILD_ROOT%" || exit /B %ERRORLEVEL%
    )

    PUSHD "%BUILD_ROOT%" || exit /B %ERRORLEVEL%
    echo Building architecture "%~1"...
    CALL :do_make_openssl "%OPENSSL_CONFIGURE_NAME%" "%OUTPUT_ROOT%" --release || (
        POPD & exit /B 1
    )
    
    echo Building debug architecture "%~1"...
    CALL :do_make_openssl "%OPENSSL_CONFIGURE_NAME%" "%OUTPUT_ROOT%" --debug || (
        POPD & exit /B 1
    )
    
    :: Update platform-specific headers
    FOR %%h in (%PLATFORM_SPECIFIC_HEADERS%) DO (
        echo Updating header '%%h' for %TARGET%..."
        echo #if %PLATFORM_DEFINITION% >"%OUTPUT_ROOT%\include\%%h.tmp"
        type "%OUTPUT_ROOT%\include\%%h" >>"%OUTPUT_ROOT%\include\%%h.tmp"
        echo #endif  >>"%OUTPUT_ROOT%\include\%%h.tmp"
        move /y "%OUTPUT_ROOT%\include\%%h.tmp" "%OUTPUT_ROOT%\include\%%h" || (
            POPD & exit /B 1
        )
    )
    
    :: Delete cruft files
    rmdir /Q /S "%OUTPUT_ROOT%\bin" 2>NUL
    rmdir /Q /S "%OUTPUT_ROOT%\lib\engines-1_1" 2>NUL
    
    POPD & echo Done!    
@exit /B 0

:do_build
    @ECHO OFF
    SET CONFIG_SETUP=%CONFIGS_DIR%\setup-windows.%~1.bat
    
    :: Clean here - in case we pass a "clean" command
    IF "%~2"=="clean" (
        CALL :do_clean %~1
        exit /B %ERRORLEVEL%
    )

    IF EXIST "%CONFIG_SETUP%" (
        :: Load configuration files
        IF EXIST "%CONFIGS_DIR%\setup-windows.bat" (
            CALL "%CONFIGS_DIR%\setup-windows.bat" || exit /B 1
        )
        
        :: Generate the project and build
        CALL "%CONFIG_SETUP%" || exit /B 1
        CALL :do_build_openssl %~1 "%OBJDIR_ROOT%\objdir-%BUILD_PLATFORM_NAME%.%~1" || exit /B %ERRORLEVEL%
    ) ELSE (
        echo Missing/invalid target "%~1" 1>&2
        GOTO print_usage
    )
@exit /B 0

:do_clean
    @ECHO OFF
    IF "%~1"=="" (
        echo Cleaning up all builds in "%OBJDIR_ROOT%"...
        FOR /D %%D IN ("%OBJDIR_ROOT%\objdir-*") DO rmdir /Q /S "%%D" 2>NUL
    ) ELSE (
        echo Cleaning up %~1 builds in "%OBJDIR_ROOT%"...
        rmdir /Q /S "%OBJDIR_ROOT%\objdir-%~1" 2>NUL
        rmdir /Q /S "%OBJDIR_ROOT%\objdir-%BUILD_PLATFORM_NAME%.%~1" 2>NUL
        IF "%~1"=="headers" SET CLEAN_HEADERS=yes
    )

    :: Remove some leftovers
    rmdir /Q "%OBJDIR_ROOT%" 2>NUL
@exit /B 0
