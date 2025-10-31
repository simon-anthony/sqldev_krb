@ECHO off
REM krb_klist: List contents of credentials cache or keytab
REM vim: fileformat=dos:

SETLOCAL enabledelayedexpansion

SET PROG=krb_klist

REM Note that %~dp0 will be C:\path\to\ and %~dpf0 will be C:\path\to\file.cmd
SET BIN=%~dp0
SET ETC=%BIN:\bin=%etc

CALL %BIN%\COLOURS.CMD

SET REALM=%USERDNSDOMAIN%

SET KLISTOPTS=

IF "%KRB5_CONFIG%" == "" (
	REM %PROGRAMDATA%\Kerberos\krb5.conf is system default for MIT Kerberos5
	REM %APPDATA%\krb5.conf is a fallback for MIT Kerberos5
	SET KRB5_CONFIG=%APPDATA%\krb5.conf
)
IF "%KRB5CCNAME%" == "" (
	REM This is the default cache unles overridden by specifying KRB5CCNAME
	REM JDK kinit uses %HOMEPATH%\krb5cc_%USERNAME%
	SET KRB5CCNAME=%LOCALAPPDATA%\krb5cc_%USERNAME%
	SET _KRB5CCNAME_SOURCE=!_C_INT!
) ELSE (
	SET _KRB5CCNAME_SOURCE=!_C_ENV!
)
IF "%KRB5_KTNAME%" == "" (
	REM JDK does not recognise KRB5_KTNAME
	SET KRB5_KTNAME=%LOCALAPPDATA%\krb5_%USERNAME%.keytab
	SET _KRB5_KTNAME_SOURCE=!_C_INT!
) ELSE (
	SET _KRB5_KTNAME_SOURCE=!_C_ENV!
)

IF "%JAVA_HOME%" == "" (
	SET _JAVA_HOME_SOURCE=!_C_INT!
) ELSE (
	SET _JAVA_HOME_SOURCE=!_C_ENV!
)

IF "%SQLDEV_HOME%" == "" (
	ECHO !_C_ERR!!PROG!!_C_OFF!: !_C_ENV!SQLDEV_HOME!_C_OFF! must be set in the environment>&2
	SET SQLDEV_HOME=!_C_ERR!SQLDEV_HOME!_C_OFF!
	IF "%~1" == "-?"  GOTO usage
	EXIT /B 1
)
IF NOT EXIST !SQLDEV_HOME!\sqldeveloper.exe (
	ECHO !_C_ERR!!PROG!!_C_OFF!: invalid SQL Developer home !SQLDEV_HOME!>&2
	IF "%~1" == "-?"  GOTO usage
	EXIT /B 1
)

SET ERRFLAG=

:parse
IF "%1" == "" GOTO endparse

SET option=%~1
SET arg=%~2

IF "%option%" == "-c" (
	SHIFT 
	SET KLISTOPTS=!KLISTOPTS! -e -c -f
	SET CFLAG=y
) ELSE IF "%option%" == "-k" (
	SHIFT 
	SET KLISTOPTS=!KLISTOPTS! -e -t -k -K
	SET KFLAG=y
) ELSE IF "%option%" == "-e" (
	SHIFT
	SET EFLAG=y
) ELSE IF "%option%" == "-x" (
	SHIFT
	SET XFLAG=y
) ELSE IF "%option%" == "-M" (
	SHIFT
	IF NOT "!JFLAG!" == "" SET ERRFLAG=Y
	SET KLISTOPTS=!KLISTOPTS! -C
	SET MMFLAG=y
) ELSE IF "%option%" == "-D" (
	SHIFT
	SET JAVA_TOOL_OPTIONS="-Dsun.security.krb5.debug=true"
	SET DDFLAG=y
) ELSE IF "%option%" == "-V" (
	SHIFT
	SET VVFLAG=y
) ELSE IF "%option%" == "-j" (
	SHIFT 
	IF NOT "!MMFLAG!" == "" SET ERRFLAG=Y
	IF NOT "%arg:~0,1%" == "-" (
		SET JAVA_HOME=%arg%
		SET _JAVA_HOME_SOURCE=!_C_OPT!
		SHIFT
	) ELSE (
		SET ERRFLAG=Y
	)
	SET JFLAG=y
) ELSE IF NOT "%option:~0,1%" == "-" (
	SET arg=%option%
	REM SHIFT
	GOTO endparse
) ELSE (
	SET ERRFLAG=Y
	GOTO endparse
)

GOTO parse
:endparse


REM Was a name supplied?
SET NAME=%~1

IF "!MMFLAG!" == "" (
	IF NOT EXIST !SQLDEV_HOME!\sqldeveloper.exe (
		ECHO !_C_ERR!!PROG!!_C_OFF!: invalid SQL Developer home>&2
		EXIT /B 1
	)
	IF NOT "!KFLAG!" == "" (
		IF "!NAME!" == "" (
			SET NAME=!KRB5_KTNAME!
		)
	) ELSE (
		IF "!NAME!" == "" (
			REM TODO - allow setting to null to try internal default
			SET NAME=!KRB5CCNAME!
		)
	)
	IF NOT "%JAVA_HOME%" == "" (
		IF NOT EXIST "%JAVA_HOME%\bin\java.exe" (
			ECHO !_C_ERR!!PROG!!_C_OFF!: invalid JAVA_HOME %JAVA_HOME%>&2
			IF "!ERRFLAG!" == "" EXIT /B 1
			SET ERRFLAG=Y
		)
		SET KRB5_BIN=%JAVA_HOME%\bin
	) ELSE (
		SET KRB5_BIN=!SQLDEV_HOME!\jdk\jre\bin
	)
) ELSE (
	SET KRB5_BIN=C:\Program Files\MIT\Kerberos\bin
)
IF "!KFLAG!" == "" (
	IF "!CFLAG!" == "" (
		SET KLISTOPTS=!KLISTOPTS! -e -c -f
	)
)
IF NOT "!EFLAG!" == "" (
	ECHO klist !KLISTOPTS! !NAME!>&2
	EXIT /B 0
)
IF NOT "!XFLAG!" == "" (
	SET KRB5_TRACE=%TEMP%\krb5_trace.log
	ECHO. > !KRB5_TRACE!
)

SET PROPS=!SQLDEV_HOME!\sqldeveloper\bin\version.properties
CALL :getprop VER_FULL !PROPS!
CALL :getprop VER !PROPS!
SET CONF=%APPDATA%\sqldeveloper\!VER!\product.conf
CALL :getconf SetJavaHome !CONF!

IF "!JFLAG!" == "" (
	IF NOT "!SetJavaHome!" == "" (
		REM Overrides all JAVA_HOME settings unless -j specified
		SET JAVA_HOME=!SetJavaHome!
	)
)

IF NOT "%JAVA_HOME%" == "" (
	IF NOT EXIST "%JAVA_HOME%\bin\java.exe" (
		ECHO !_C_ERR!!PROG!!_C_OFF!: invalid JAVA_HOME %JAVA_HOME%>&2
		IF "!ERRFLAG!" == "" EXIT /B 1
	)
	SET KRB5_BIN=%JAVA_HOME%\bin
) ELSE (
	SET KRB5_BIN=!SQLDEV_HOME!\jdk\jre\bin
)
SET PATH=!KRB5_BIN!;%PATH%

IF NOT "!VVFLAG!" == "" (
	IF NOT "!JAVA_HOME!" == "" (
		CALL :javaversion !JAVA_HOME! VERSION
	) ELSE (
		CALL :javaversion !SQLDEV_HOME!\jdk\jre VERSION
	)
	ECHO !VERSION!
	EXIT /B 0
)

IF NOT "!ERRFLAG!" == "" GOTO usage

klist !KLISTOPTS! !NAME!

IF "!CFLAG!" == "" (
	IF "!KFLAG!" == "" (
		IF EXIST %HOMEDRIVE%%HOMEPATH%\krb5cc_%USERNAME% (
			klist !KLISTOPTS! %HOMEDRIVE%%HOMEPATH%\krb5cc_%USERNAME%
		)
	)
)
ENDLOCAL
EXIT /B 0

:usage
	ECHO !_C_ERR!Usage!_C_OFF!: !_C_BLD!krb_klist!_C_OFF! [!_C_ARG!-M!_C_OFF!^|!_C_ARG!-j !_C_OPT!java_home!_C_OFF!] [!_C_ARG!-e!_C_OFF!] [!_C_ARG!-V!_C_OFF!] [!_C_ARG!-c!_C_OFF!^|!_C_ARG!!_C_ARG!-k!_C_OFF!] [!_C_OPT!name!_C_OFF!]>&2
	ECHO   !_C_ARG!-c!_C_OFF!               Specifies credential cache !_C_ENV!KRB5CCNAME!_C_OFF! (default: !_KRB5CCNAME_SOURCE!!KRB5CCNAME!!_C_OFF!^)>&2
	ECHO   !_C_ARG!-k!_C_OFF!               Specifies keytab !_C_ENV!KRB5_KTNAME!_C_OFF! (default: !_KRB5_KTNAME_SOURCE!!KRB5_KTNAME!!_C_OFF!^)>&2
	ECHO   !_C_ARG!-e!_C_OFF!               Echo the command only>&2
	ECHO   !_C_ARG!-x!_C_OFF!               Produce trace (in %TEMP%\krb5_trace.log)>&2
	ECHO   !_C_ARG!-D!_C_OFF!               Turn on krb5.debug>&2
	ECHO   !_C_ARG!-M!_C_OFF!               Use MIT Kerberos>&2
	ECHO   !_C_ARG!-V!_C_OFF!               Print Java version and exit>&2
	IF NOT "!JAVA_HOME!" == "" (
		ECHO   !_C_ARG!-j!_C_OFF! !_C_OPT!java_home!_C_OFF!     Specify !_C_ENV!JAVA_HOME!_C_OFF! (default: !_JAVA_HOME_SOURCE!!JAVA_HOME!!_C_OFF!^) if unset>&2
	) ELSE (
		ECHO   !_C_ARG!-j!_C_OFF! !_C_OPT!java_home!_C_OFF!     Specify !_C_ENV!JAVA_HOME!_C_OFF! (default: !_JAVA_HOME_SOURCE!!SQLDEV_HOME!\jdk\jre!_C_OFF!^) if unset>&2
	)
	ECHO                     use SetJavaHome from !_C_CFG!product.conf!_C_OFF! or SQL Developer built-in JDK>&2
	ECHO   !_C_OPT!name!_C_OFF!             The cache or keytab of which to list the contents>&2
	ECHO When no cache or keytab is specified the default action is to search for all credential caches>&2
ENDLOCAL
EXIT /B 1

REM javaversion: print Java version
:javaversion java_home vers
	FOR /f "tokens=3" %%i IN ('%1\bin\java -version 2^>^&1^|findstr version') DO (CALL set %~2=%%~i%%)
EXIT /B 0

REM getprop: retrieve a setting from a .properties file
:getprop str file
        FOR /F "tokens=1,2 delims=^=" %%i IN (%2) DO (IF %%i == %1 CALL SET %~1=%%j%%)

EXIT /B 0

REM getconf: retrieve a setting from a .conf file
:getconf str file
	FOR /F "tokens=1,2" %%i IN (%2) DO (IF %%i == %1 CALL SET %~1=%%j%%)
EXIT /B 0

