@ECHO off
REM krb_pkinit: Get TGT from certificate
REM vim: fileformat=dos:

SETLOCAL enabledelayedexpansion

SET PROG=krb_pkinit

REM Note that %~dp0 will be C:\path\to\ and %~dpf0 will be C:\path\to\file.cmd
SET BIN=%~dp0
SET ETC=%BIN:\bin=%etc

CALL %BIN%\COLOURS.CMD

SET REALM=%USERDNSDOMAIN%

SET KINITOPTS=

SET CERTDIR=%USERPROFILE%\Certs

SET USERNAME=%USERNAME: =%
CALL :toLower USERNAME

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
	SET _KRB5CCNAME_SOURCE=!_C_INT!
) ELSE (
	SET _KRB5CCNAME_SOURCE=!_C_ENV!
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
		SET _KRB5CCNAME_SOURCE=!_C_OPT!
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
	ECHO !_C_ERR!Usage!_C_OFF!: !_C_BLD!!PROG! !_C_OFF![!_C_ARG!-e!_C_OFF!] [!_C_ARG!-x!_C_OFF!] [!_C_ARG!-C!_C_OFF!^|!_C_ARG!-c !_C_OPT!krb5ccname^>!_C_OFF!] [!_C_ARG!-d !_C_OPT!dir!_C_OFF!] [!_C_ARG!-D !_C_OPT!dir!_C_OFF!] [!_C_ARG!-A !_C_OPT!dir!_C_OFF!]>&2

	ECHO   !_C_ARG!-c!_C_OFF! !_C_OPT!krb5ccname!_C_OFF!    Specify !_C_ENV!KRB5CCNAME!_C_OFF! (default: !_KRB5CCNAME_SOURCE!!KRB5CCNAME!!_C_OFF!^)>&2
	ECHO   !_C_ARG!-C!_C_OFF!               Unset any default value of !_C_ENV!KRB5CCNAME!_C_OFF!>&2

	ECHO   !_C_ARG!-d!_C_OFF!               Directory !_C_OPT!dir!_C_OFF! in which to find certificate (%USERNAME%.crt)>&2
	ECHO   !_C_ARG!-D!_C_OFF!               Directory !_C_OPT!dir!_C_OFF! in which to find key (%USERNAME%.key)>&2
	ECHO   !_C_ARG!-A!_C_OFF!               Directory !_C_OPT!dir!_C_OFF! in which to find anchor certificate (ca.crt)>&2
	ECHO   !_C_ARG!-e!_C_OFF!               Echo the command only>&2
	ECHO   !_C_ARG!-x!_C_OFF!               Produce trace (in %TEMP%\krb5_trace.log)>&2
	ECHO  Default !_C_OPT!dir!_C_OFF! is %USERPROFILE%\Certs>&2
ENDLOCAL
EXIT /B 1

REM toUpper: make str uppercase
:toUpper str
	FOR %%a IN ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I"
		"j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R"
		"s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z") DO (
		CALL SET %~1=%%%~1:%%~a%%
	)
EXIT /B 0

REM toLower: make str lowercase
:toLower str
	FOR %%a IN ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i"
		"J=j" "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r"
		"S=s" "T=t" "U=u" "V=v" "W=w" "X=x" "Y=y" "Z=z") DO (
		CALL SET %~1=%%%~1:%%~a%%
	)
EXIT /B 0
