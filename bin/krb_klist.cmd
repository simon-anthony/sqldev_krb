@ECHO off
REM krb_klist: List contents of credentials cache or keytab

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
	SET KRB5_KTNAME=%LOCALAPPDATA%\krb5cc_%USERNAME%.keytab
)

:parse
IF "%1" == "" GOTO endparse

SET option=%~1
SET arg=%~2

IF "%option%" == "-c" (
	SHIFT 
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
	SET SNAME=
	SET MMFLAG=y
) ELSE (
	GOTO usage
)

GOTO parse
:endparse

IF NOT "!KFLAG!" == "" (
	IF NOT "!CFLAG!" == "" (
		GOTO usage
	)
)
IF "!MMFLAG!" == "" (
	IF NOT "!KFLAG!" == "" (
		SET NAME=!KRB5_KTNAME!
	)
	SET KRB5_BIN=!SQLDEV_HOME!\jdk\jre\bin
) ELSE (
	SET KRB5_BIN=C:\Program Files\MIT\Kerberos\bin
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

klist !KLISTOPTS! !NAME!

ENDLOCAL
EXIT /B 0

:usage
	ECHO Usage: krb_klist [-M] [-c^|-k] [^<name^>]
	ECHO   -c               specifies credential cache KRB5CCNAME (default: !KRB5CCNAME!^)
	ECHO   -k               specifies keytab KRB5_KTNAME (default: !KRB5_KTNAME!^)
	ECHO   -e               echo the command only
	ECHO   -x               produce trace (in %TEMP%\krb5_trace.log)
	ECHO   -M               use MIT Kerberos
ENDLOCAL
EXIT /B 1
