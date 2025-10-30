@ECHO off
REM krb_kdestroy: Destroy credentials cache or keytab
REM vim: fileformat=dos:

SETLOCAL enabledelayedexpansion

SET PROG=krb_kdestroy
SET REALM=%USERDNSDOMAIN%

IF "%SQLDEV_HOME%" == "" (
	ECHO [91m!PROG![0m: [96mSQLDEV_HOME[0m must be set in the environment>&2
	SET SQLDEV_HOME=[91mSQLDEV_HOME[0m
	IF "%~1" == "-?"  GOTO :usage
	EXIT /B 1
)
IF NOT EXIST !SQLDEV_HOME!\sqldeveloper.exe (
	ECHO [91m!PROG![0m: invalid SQL Developer home !SQLDEV_HOME!>&2
	IF "%~1" == "-?"  GOTO :usage
	EXIT /B 1
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
	SET _KRB5CCNAME_SOURCE=[31m
) ELSE (
	SET _KRB5CCNAME_SOURCE=[96m
)
IF "%KRB5_KTNAME%" == "" (
	REM JDK does not recognise KRB5_KTNAME
	SET KRB5_KTNAME=%LOCALAPPDATA%\krb5_%USERNAME%.keytab
	SET _KRB5_KTNAME_SOURCE=[31m
) ELSE (
	SET _KRB5_KTNAME_SOURCE=[96m
)


SET ERRFLAG=

:parse
IF "%1" == "" GOTO endparse

SET option=%~1
SET arg=%~2

IF "%option%" == "-k" (
	SHIFT 
	IF NOT "!KFLAG!" == "" GOTO usage
	SET FILES=!FILES! !KRB5_KTNAME!
	SET KFLAG=y
) ELSE IF "%option%" == "-c" (
	SHIFT
	IF NOT "!CFLAG!" == "" GOTO usage
	SET FILES=!FILES! !KRB5CCNAME!
	SET CFLAG=y
) ELSE IF "%option%" == "-e" (
	SHIFT
	SET EFLAG=y
) ELSE (
	SET ERRFLAG=Y
	GOTO endparse
)

GOTO parse
:endparse

IF "!FILES!" == "" (
	SET FILES=!KRB5CCNAME!
)
IF EXIST %HOMEDRIVE%%HOMEPATH%\krb5cc_%USERNAME% (
	SET FILES=!FILES! %HOMEDRIVE%%HOMEPATH%\krb5cc_%USERNAME% 
)

IF NOT "!ERRFLAG!" == "" GOTO usage

IF NOT "!EFLAG!" == "" (
	ECHO del !FILES! 
	EXIT /B 0
)

DEL !FILES!

ENDLOCAL
EXIT /B 0

:usage
	ECHO [91mUsage[0m: [1mkrb_kdestroy [0m[[93m-c[0m] [[93m-k[0m]
	ECHO   [93m-c[0m               Specifies credential cache [096mKRB5CCNAME[0m (default: !_KRB5CCNAME_SOURCE!!KRB5CCNAME![0m^)>&2
	ECHO                    this is the default action if neither [93m-c[0m nor [93m-k[0m are specified
	ECHO   [93m-k[0m               Specifies keytab [96mKRB5_KTNAME[0m (default: !_KRB5_KTNAME_SOURCE!!KRB5_KTNAME![0m^)
	ECHO   [93m-e[0m               Echo the command only
ENDLOCAL
EXIT /B 1
