@ECHO off
REM krb_pkinit: Get TGT from certificate
REM REM vim: fileformat=dos:

SETLOCAL enabledelayedexpansion

SET REALM=%USERDNSDOMAIN%

SET KINITOPTS=

SET CERTDIR=C:\Users\%USERNAME%\Certs
SET KEYDIR=C:\Users\%USERNAME%\Certs

IF "%TNS_ADMIN" == "" (
	SET TNS_ADMIN=%APPDATA%
)
SET SQLNET_ORA=!TNS_ADMIN!\sqlnet.ora

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

SET X509_PROXY=FILE:!CERTDIR!\%USERNAME%.crt,!KEYDIR!\%USERNAME%.key
SET X509_ANCHORS=FILE:!CERTDIR!\ca.crt

:parse
IF "%1" == "" GOTO endparse

SET option=%~1
SET arg=%~2

IF "%option%" == "-c" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET KRB5CCNAME=%arg%
		SHIFT
	) ELSE (
		GOTO usage
	)
	SET CFLAG=y
) ELSE IF "%option%" == "-C" (
	SHIFT
	SET KRB5CCNAME=
	SET CCFLAG=y
) ELSE IF "%option%" == "-e" (
	SHIFT
	SET EFLAG=y
) ELSE IF "%option%" == "-x" (
	SHIFT
	SET XFLAG=y
) ELSE (
	GOTO usage
)

GOTO parse
:endparse

IF NOT "!CFLAG!" == "" (
	IF NOT "!CCFLAG!" == "" (
		GOTO usage
	)
)

IF NOT "!KRB5CCNAME!" == "" (
	SET KINITOPTS=!KINITOPTS! -c !KRB5CCNAME!
)

IF NOT "!EFLAG!" == "" (
	ECHO kinit -V %KINITOPTS% -X X590_user_identity=!X509_PROXY! -X X509_anchors=!X509_ANCHORS! %USERNAME%@!REALM!
	EXIT /B 0
)
IF NOT "!XFLAG!" == "" (
	SET KRB5_TRACE=%TEMP%\krb5_trace.log
	ECHO. > !KRB5_TRACE!
)

SET KRB5_BIN=C:\Program Files\MIT\Kerberos\bin
SET PATH=!KRB5_BIN!;%PATH%

echo Krb5.conf: !KRB5_CONFIG!
kinit -V %KINITOPTS% -X X590_user_identity=!X509_PROXY! -X X509_anchors=!X509_ANCHORS! %USERNAME%@!REALM!

ENDLOCAL
EXIT /B 0

:usage
	ECHO Usage: krb_pkinit [-e] [-x] [-C^|-c ^<krb5ccname^>]
	ECHO   -c ^<krb5ccname^>    specify KRB5CCNAME (default: !KRB5CCNAME!^)
	ECHO   -C                 unset any default value of KRB5CCNAME
	ECHO   -e                 echo the command only
	ECHO   -x                 produce trace (in %TEMP%\krb5_trace.log)
ENDLOCAL
EXIT /B 1
