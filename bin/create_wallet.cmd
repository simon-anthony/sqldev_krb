@ECHO off
REM create_wallet: create a wallet
REM vim: fileformat=dos:

SETLOCAL enabledelayedexpansion

SET PROG=create_wallet

REM Note that %~dp0 will be C:\path\to\ and %~dpf0 will be C:\path\to\file.cmd
SET BIN=%~dp0
SET ETC=%BIN:\bin=%etc

CALL %BIN%\COLOURS.CMD

SET ORACLE_HOME=C:\Oracle\client_home
SET WALLET_ROOT=%USERPROFILE%\ORACLE\WALLETS
SET CA=ipa.home_ca
SET WALLET=%WALLET_ROOT%\DEFAULT

SET USERNAME=%USERNAME: =%
CALL :toLower USERNAME

SET NAME=windows11.ipa.home

SET SSL_CERT=P:\Certs\!NAME!.crt
SET SSL_KEY=P:\Certs\!NAME!.key
SET CA_CERT=P:\Certs\!CA!.crt
SET SSL_PKCS12=

SET _SSL_CERT_SOURCE=!_C_INT!
SET _SSL_KEY_SOURCE=!_C_INT!
SET _CA_CERT_SOURCE=!_C_INT!
SET _WALLET_SOURCE=!_C_INT!

REM Define a Linefeed variable - the two lines after are significant
set LF=^



SET ERRFLAG=

:parse
IF "%1" == "" GOTO endparse

SET option=%~1
SET arg=%~2

IF "%option%" == "-k" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET SSL_KEY=%arg%
		SET _SSL_KEY_SOURCE=!_C_OPT!
		SHIFT
	) ELSE (
		SET ERRFLAG=Y
	)
	IF NOT "!LFLAG!" == "" SET ERRFLAG=Y
	IF NOT "!PFLAG!" == "" SET ERRFLAG=Y
	SET KFLAG=Y
) ELSE IF "%option%" == "-c" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET SSL_CERT=%arg%
		SET _SSL_CERT_SOURCE=!_C_OPT!
		SHIFT
	) ELSE (
		SET ERRFLAG=Y
	)
	IF NOT "!LFLAG!" == "" SET ERRFLAG=Y
	IF NOT "!PFLAG!" == "" SET ERRFLAG=Y
	SET CFLAG=Y
) ELSE IF "%option%" == "-r" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET CA_CERT=%arg%
		SET _CA_CERT_SOURCE=!_C_OPT!
		SHIFT
	) ELSE (
		SET ERRFLAG=Y
	)
	IF NOT "!LFLAG!" == "" SET ERRFLAG=Y
	IF NOT "!PFLAG!" == "" SET ERRFLAG=Y
	SET RFLAG=Y
) ELSE IF "%option%" == "-p" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET SSL_PKCS12=%arg%
		SET _SSL_PKCS12_SOURCE=!_C_OPT!
		SHIFT
	) ELSE (
		SET ERRFLAG=Y
	)
	IF NOT "!CFLAG!" == "" SET ERRFLAG=Y
	IF NOT "!KFLAG!" == "" SET ERRFLAG=Y
	IF NOT "!RFLAG!" == "" SET ERRFLAG=Y
	SET PFLAG=Y
) ELSE IF "%option%" == "-w" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET WALLET=%arg%
		REM If no path specified then prefix WALLET_ROOT
		IF "!WALLET:\= !" == "!WALLET!" SET WALLET=!WALLET_ROOT!\!WALLET!
		SET _WALLET_SOURCE=!_C_OPT!
		SHIFT
	) ELSE (
		SET ERRFLAG=Y
	)
	SET WFLAG=Y
) ELSE IF "%option%" == "-e" (
	SHIFT
	SET EFLAG=Y
) ELSE IF "%option%" == "-f" (
	SHIFT
	IF NOT "!LFLAG!" == "" SET ERRFLAG=Y
	SET FFLAG=Y
) ELSE IF "%option%" == "-l" (
	SHIFT
	IF NOT "!KFLAG!" == "" SET ERRFLAG=Y
	IF NOT "!CFLAG!" == "" SET ERRFLAG=Y
	IF NOT "!RFLAG!" == "" SET ERRFLAG=Y
	IF NOT "!PFLAG!" == "" SET ERRFLAG=Y
	SET LFLAG=Y
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

IF NOT "!ERRFLAG!" == "" GOTO usage

SET PATH=!ORACLE_HOME!\bin;%PATH%

IF "!LFLAG!" == "" (
	FOR /f %%i IN ('openssl rand -base64 16') DO (CALL set PASSWORD=%%i%%)

	REM Create wallet
	IF EXIST "!WALLET!"\ewallet.p12 (
		IF NOT "!FFLAG!" == "" (
			ECHO !_C_WRN!!PROG!!_C_OFF!: removing wallet>&2
			RMDIR /Q /S "!WALLET!"
		) ELSE (
			ECHO !_C_ERR!!PROG!!_C_OFF!: wallet already exists>&2
			EXIT /B 1
		)
	) 
	IF NOT EXIST "!WALLET!"\ewallet.p12 (
		ECHO !_C_MSG!!PROG!!_C_OFF!: creating wallet>&2
		MKDIR "!WALLET!
		CALL orapki wallet create -wallet "!WALLET!" -pwd "!PASSWORD!" -auto_login 
	)

	IF "!PFLAG!" == "" (
		REM FOR /f %%i IN ('mktemp -p %TEMP%') DO (CALL set SSL_PKCS12=%%i%%)
		SET SSL_PKCS12=%TEMP%\pkcs12file
		SET PKCS12_PASSWORD=!PASSWORD!

		REM Add CA cert
		CALL orapki wallet add -wallet "!WALLET!" -trusted_cert -cert "!CA_CERT!" -pwd "!PASSWORD!" 

		SET DOMAIN=%NAME:*.=%
		SET ALIAS=!NAME:.%DOMAIN%=!

		REM Create PKCS12
		openssl pkcs12 -export -in "!SSL_CERT!" -inkey "!SSL_KEY!" -out "!SSL_PKCS12!" -passout pass:"!PASSWORD!" -name !NAME!
	) ELSE (
		IF NOT EXIST "!SSL_PKCS12!" (
			ECHO !PROG!: file !SSL_PKCS12! does not exist>&2
			EXIT /B 1
		)
		SET /p PKCS12_PASSWORD="Enter password for !SSL_PKCS12!: "
	)

	REM Import PKCS12
	CALL orapki wallet import_pkcs12 -wallet "!WALLET!" -pkcs12file "!SSL_PKCS12!" -pwd "!PASSWORD!" -pkcs12pwd "!PKCS12_PASSWORD!" 
)

CALL orapki wallet display -wallet "!WALLET!" -complete


ENDLOCAL
EXIT /B 0

:usage
rem 	ECHO !_C_ERR!Usage!_C_OFF!: !_C_BLD!!PROG!!_C_OFF! [!_C_ARG!-e!_C_OFF!] [!_C_ARG!-f!_C_OFF!] [!_C_ARG!-k!_C_OFF! !_C_OPT!ssl_key!_C_OFF!] [!_C_ARG!-c!_C_OFF! !_C_OPT!ssl_cert!_C_OFF!] [!_C_ARG!-r!_C_OFF! !_C_OPT!ca_cert!_C_OFF!] [!_C_ARG!-w!_C_OFF! !_C_OPT!wallet!_C_OFF!]>&2
	ECHO !_C_ERR!Usage!_C_OFF!: !_C_BLD!!PROG!!_C_OFF! [!_C_ARG!-e!_C_OFF!] [!_C_ARG!-f!_C_OFF!] [[!_C_ARG!-k!_C_OFF! !_C_OPT!ssl_key!_C_OFF!] [!_C_ARG!-c!_C_OFF! !_C_OPT!ssl_cert!_C_OFF!] [!_C_ARG!-r!_C_OFF! !_C_OPT!ca_cert!_C_OFF!] ^| !_C_ARG!-p!_C_OFF! !_C_OPT!pkcs12_file!_C_OFF!] [!_C_ARG!-w!_C_OFF! !_C_OPT!wallet!_C_OFF!]>&2
	ECHO   !_C_ARG!-k!_C_OFF! !_C_OPT!ssl_key!_C_OFF!       Specify !_C_ENV!SSL_KEY!_C_OFF! (default: !_SSL_KEY_SOURCE!!SSL_KEY!!_C_OFF!^)>&2
	ECHO   !_C_ARG!-c!_C_OFF! !_C_OPT!ssl_cert!_C_OFF!      Specify !_C_ENV!SSL_CERT!_C_OFF! (default: !_SSL_CERT_SOURCE!!SSL_CERT!!_C_OFF!^)>&2
	ECHO   !_C_ARG!-r!_C_OFF! !_C_OPT!ca_cert!_C_OFF!       Specify !_C_ENV!CA_CERT!_C_OFF! (default: !_CA_CERT_SOURCE!!CA_CERT!!_C_OFF!^)>&2
	ECHO   !_C_ARG!-p!_C_OFF! !_C_OPT!ssl_pkcs12!_C_OFF!    Specify !_C_ENV!SSL_PKCS12!_C_OFF! containing, key, cert and CA cert (default: !_SSL_PKCS12_SOURCE!!SSL_PKCS12!!_C_OFF!^)>&2
	ECHO   !_C_ARG!-w!_C_OFF! !_C_OPT!wallet!_C_OFF!        Specify !_C_ENV!WALLET!_C_OFF! (default: !_WALLET_SOURCE!!WALLET!!_C_OFF!^)>&2
	ECHO   !_C_ARG!-e!_C_OFF!               Echo the command only>&2
	ECHO   !_C_ARG!-f!_C_OFF!               Force creation of a new wallet>&2
	ECHO.
	ECHO !_C_ERR!Usage!_C_OFF!: !_C_BLD!!PROG!!_C_OFF! !_C_ARG!-l!_C_OFF! [!_C_ARG!-w!_C_OFF! !_C_OPT!wallet!_C_OFF!]>&2
	ECHO   !_C_ARG!-l!_C_OFF!               Display contents of wallet>&2
	ECHO   !_C_ARG!-w!_C_OFF! !_C_OPT!wallet!_C_OFF!        Specify !_C_ENV!WALLET!_C_OFF! (default: !_WALLET_SOURCE!!WALLET!!_C_OFF!^)>&2
ENDLOCAL
EXIT /B 1

:hexPrint  string  [rtnVar]
	for /f eol^=^%LF%%LF%^ delims^= %%A in (
		'forfiles /p "%~dp0." /m "%~nx0" /c "cmd /c echo(%~1"'
	) do if "%~2" neq "" (set %~2=%%A) else echo(%%A
EXIT /B

REM regquery: retrieve value of str from HKLM\SOFTWARE\ORACLE
:regquery str
	FOR /f "tokens=3" %%i IN ('reg query HKLM\SOFTWARE\ORACLE /s /f "%~1" /e ^| findstr %~1') DO (CALL set %~1=%%i%%)
EXIT /B 0

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
