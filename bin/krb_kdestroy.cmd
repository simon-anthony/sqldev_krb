@ECHO off
REM krb_kdestroy: Destroy credentials cache or keytab
REM vim: fileformat=dos:

SETLOCAL enabledelayedexpansion

SET PROG=krb_kdestroy

REM COLOURS
SET _C_INT=[38;5;214m
SET _C_ENV=[96m
SET _C_ERR=[91m
SET _C_MSG=[92m
SET _C_DNS=[35m
SET _C_ARG=[93m
SET _C_OPT=[33m
SET _C_CFG=[32m
SET _C_JAA=[38;5;115m
SET _C_REG=[36m
SET _C_OFF=[0m
SET _C_BLD=[0m

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
	ECHO !_C_ERR!Usage!_C_OFF!: !_C_BLD!krb_kdestroy !_C_OFF![!_C_ARG!-c!_C_OFF!] [!_C_ARG!-k!_C_OFF!]
	ECHO   !_C_ARG!-c!_C_OFF!               Specifies credential cache !_C_ENV!KRB5CCNAME!_C_OFF! (default: !_KRB5CCNAME_SOURCE!!KRB5CCNAME!!_C_OFF!^)>&2
	ECHO                    this is the default action if neither !_C_ARG!-c!_C_OFF! nor !_C_ARG!-k!_C_OFF! are specified
	ECHO   !_C_ARG!-k!_C_OFF!               Specifies keytab !_C_ENV!KRB5_KTNAME!_C_OFF! (default: !_KRB5_KTNAME_SOURCE!!KRB5_KTNAME!!_C_OFF!^)
	ECHO   !_C_ARG!-e!_C_OFF!               Echo the command only
ENDLOCAL
EXIT /B 1
