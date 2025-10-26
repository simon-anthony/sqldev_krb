@ECHO off
REM krb_pkinit: Get TGT from certificate
REM vim: fileformat=dos:

SETLOCAL enabledelayedexpansion

SET PROG=krb_pkinit

SET REALM=%USERDNSDOMAIN%

SET KINITOPTS=

SET CERTDIR=%USERPROFILE%\Certs

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
	SET _KRB5CCNAME_SOURCE=[31m
) ELSE (
	SET _KRB5CCNAME_SOURCE=[96m
)

SET ERRFLAG=

:parse
IF "%1" == "" GOTO endparse

SET option=%~1
SET arg=%~2

IF "%option%" == "-c" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET KRB5CCNAME=%arg%
		SET _KRB5CCNAME_SOURCE=[33m
		SHIFT
	) ELSE (
		ERRFLAG=Y
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
) ELSE IF "%option%" == "-d" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET CERTDIR=%arg%
		SHIFT
	) ELSE (
		SET ERRFLAG=Y
	)
	SET DFLAG=y
) ELSE IF "%option%" == "-D" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET KEYDIR=%arg%
		SHIFT
	) ELSE (
		SET ERRFLAG=Y
	)
	SET DDFLAG=y
) ELSE IF "%option%" == "-A" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET ANCHDIR=%arg%
		SHIFT
	) ELSE (
		SET ERRFLAG=Y
	)
	SET AAFLAG=y
) ELSE (
	SET ERRFLAG=Y
	GOTO endparse
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
IF "!KEYDIR!" == "" (
	SET KEYDIR=!CERTDIR!
)	
IF "!ANCHDIR!" == "" (
	SET ANCHDIR=!CERTDIR!
)

SET X509_PROXY=FILE:!CERTDIR!\%USERNAME%.crt,!KEYDIR!\%USERNAME%.key
SET X509_ANCHORS=FILE:!ANCHDIR!\ca.crt

IF NOT "!ERRFLAG!" == "" GOTO usage

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
	ECHO [91mUsage[0m: [1mkrb_pkinit [0m[[93m-e[0m] [[93m-x[0m] [[93m-C[0m^|[93m-c [33mkrb5ccname^>[0m] [[93m-d [33mdir[0m] [[93m-D [33mdir[0m] [[93m-A [33mdir[0m]>&2

	ECHO   [93m-c[0m [33mkrb5ccname[0m    Specify [96mKRB5CCNAME[0m (default: !_KRB5CCNAME_SOURCE!!KRB5CCNAME![0m^)>&2
	ECHO   [93m-C[0m               Unset any default value of [96mKRB5CCNAME[0m>&2

	ECHO   -d               Directory [33mdir[0m in which to find certificate (%USERNAME%.crt)>&2
	ECHO   -D               Directory [33mdir[0m in which to find key (%USERNAME%.key)>&2
	ECHO   -A               Directory [33mdir[0m in which to find anchor certificate (ca.crt)>&2
	ECHO   -e               Echo the command only>&2
	ECHO   -x               Produce trace (in %TEMP%\krb5_trace.log)>&2
	ECHO  Default [33mdir[0m is %USERPROFILE%\Certs>&2
ENDLOCAL
EXIT /B 1
