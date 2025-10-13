@ECHO off
REM krb_kdestroy: Destroy credentials cache or keytab
REM vim: fileformat=dos:

SETLOCAL enabledelayedexpansion

SET REALM=%USERDNSDOMAIN%

IF "%SQLDEV_HOME%" == "" (
	SET SQLDEV_HOME=C:\Oracle\sqldeveloper
)
IF NOT EXIST !SQLDEV_HOME!\sqldeveloper.exe (
	ECHO Invalid SQL Developer home
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
)
IF "%KRB5_KTNAME%" == "" (
	REM JDK does not recognise KRB5_KTNAME
	SET KRB5_KTNAME=%LOCALAPPDATA%\krb5_%USERNAME%.keytab
)

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
	GOTO usage
)

GOTO parse
:endparse

IF "!FILES!" == "" (
	SET FILES=!KRB5CCNAME!
)
IF EXIST %HOMEDRIVE%%HOMEPATH%\krb5cc_%USERNAME% (
	SET FILES=!FILES! %HOMEDRIVE%%HOMEPATH%\krb5cc_%USERNAME% 
)

IF NOT "!EFLAG!" == "" (
	ECHO del !FILES! 
	EXIT /B 0
)

DEL !FILES!

ENDLOCAL
EXIT /B 0

:usage
	ECHO Usage: krb_kdestroy [-c] [-k]
	ECHO   -c               specifies credential cache KRB5CCNAME (default: !KRB5CCNAME!^)
	ECHO                    this is the default action if neither -c nor -k are specified
	ECHO   -k               specifies keytab KRB5_KTNAME (default: !KRB5_KTNAME!^)
	ECHO   -e               echo the command only
ENDLOCAL
EXIT /B 1
