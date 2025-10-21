@ECHO off
REM krb_klist: List contents of credentials cache or keytab
REM vim: fileformat=dos:

SETLOCAL enabledelayedexpansion

SET REALM=%USERDNSDOMAIN%

IF "%SQLDEV_HOME%" == "" (
	SET SQLDEV_HOME=C:\Oracle\sqldeveloper
)

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
)
IF "%KRB5_KTNAME%" == "" (
	REM JDK does not recognise KRB5_KTNAME
	SET KRB5_KTNAME=%LOCALAPPDATA%\krb5_%USERNAME%.keytab
)

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
	SET KLISTOPTS=!KLISTOPTS! -C
	SET MMFLAG=y
) ELSE IF "%option%" == "-D" (
	SHIFT
	SET JAVA_TOOL_OPTIONS="-Dsun.security.krb5.debug=true"
	SET DDFLAG=y
) ELSE IF "%option%" == "-V" (
	SHIFT
	SET VVFLAG=y
) ELSE IF NOT "%option:~0,1%" == "-" (
	SET arg=%option%
	REM SHIFT
	GOTO endparse
) ELSE (
	GOTO usage
)

GOTO parse
:endparse


REM Was a name supplied?
SET NAME=%~1

IF "!MMFLAG!" == "" (
	IF NOT EXIST !SQLDEV_HOME!\sqldeveloper.exe (
		ECHO Invalid SQL Developer home
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
			ECHO Invalid JAVA_HOME %JAVA_HOME%
			EXIT /B 1
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
	ECHO klist !KLISTOPTS! !NAME!
	EXIT /B 0
)
IF NOT "!XFLAG!" == "" (
	SET KRB5_TRACE=%TEMP%\krb5_trace.log
	ECHO. > !KRB5_TRACE!
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
	ECHO Usage: krb_klist [-M] [-e] [-V] [-c^|-k] [^<name^>]
	ECHO   -c               specifies credential cache KRB5CCNAME (default: !KRB5CCNAME!^)
	ECHO   -k               specifies keytab KRB5_KTNAME (default: !KRB5_KTNAME!^)
	ECHO   -e               echo the command only
	ECHO   -x               produce trace (in %TEMP%\krb5_trace.log)
	ECHO   -D               turn on krb5.debug
	ECHO   -M               use MIT Kerberos
	ECHO   -V               print Java version and exit
	ECHO when no cache or keytab is specified the default action is to search for all credential caches
ENDLOCAL
EXIT /B 1

:javaversion java_home vers
	FOR /f "tokens=3" %%i IN ('%1\bin\java -version 2^>^&1^|findstr version') DO (CALL set %~2=%%~i%%)
EXIT /B 0
