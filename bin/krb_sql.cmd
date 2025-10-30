@ECHO off
REM krb_sql: SQLcl using Kerberos
REM vim: fileformat=dos:

SETLOCAL enabledelayedexpansion

SET PROG=krb_sql

SET ORACLE_HOME=

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

SET _TNS_SOURCE=!_C_ENV!
SET SQLOPTS=-kerberos -thin -noupdates

IF "%KRB5_CONFIG%" == "" (
	REM set after SetJavaHome evaluation
	REM %PROGRAMDATA%\Kerberos\krb5.conf is system default for MIT Kerberos5
	REM %APPDATA%\krb5.conf is a fallback for MIT Kerberos5
	REM SET KRB5_CONFIG=%APPDATA%\krb5.conf
	REM SET KRB5_CONFIG=!SQLDEV_HOME!\jdk\jre\conf\security\krb5.conf
	SET _KRB5_CONFIG_SOURCE=!_C_INT!
) ELSE (
	SET _KRB5_CONFIG_SOURCE=!_C_ENV!
)

IF "%KRB5CCNAME%" == "" (
	REM This is the default cache unless overridden by specifying KRB5CCNAME
	SET KRB5CCNAME=%LOCALAPPDATA%\krb5cc_%USERNAME%
	SET _KRB5CCNAME_SOURCE=!_C_INT!
) ELSE (
	SET _KRB5CCNAME_SOURCE=!_C_ENV!
)

REM TODO: add -k krb5_ktname|-K options
SET KRB5_KTNAME=!LOCALAPPDATA!\krb5_!USERNAME!.keytab

REM JAAS configuration entry name
SET NAME=Oracle

IF "%JAAS_CONFIG%" == "" (
	REM This is the default file used in <jre_home>\conf\security\java.security
	SET JAAS_CONFIG=%HOMEDRIVE%%HOMEPATH%\.java.login.config
	SET _JAAS_CONFIG_SOURCE=!_C_INT!
) ELSE (
	SET _JAAS_CONFIG_SOURCE=!_C_ENV!
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

REM Define a Linefeed variable - the two lines after are significant
set LF=^



SET ERRFLAG=

:parse
REM IF "%1" == "" SET ERRFLAG=Y

SET option=%~1
SET arg=%~2

IF "%option%" == "-k" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET KRB5_CONFIG=%arg%
		SET _KRB5_CONFIG_SOURCE=!_C_OPT!
		SHIFT
	) ELSE (
		SET ERRFLAG=Y
	)
	IF NOT "!LLFLAG!" == "" SET ERRFLAG=Y
	IF NOT "!KKFLAG!" == "" SET ERRFLAG=Y
	SET KFLAG=Y
) ELSE IF "%option%" == "-t" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET TNS_ADMIN=%arg%
		SHIFT
	) ELSE (
		SET ERRFLAG=Y
	)
	SET _TNS_SOURCE=!_C_OPT!
	SET TFLAG=Y
	IF NOT "!AFLAG!" == "" (
		GOTO endparse
	)
) ELSE IF "%option%" == "-K" (
	SHIFT
	SET KRB5_CONFIG=
	SET _KRB5_CONFIG_SOURCE=!_C_INT!
	IF NOT "!KFLAG!" == "" SET ERRFLAG=Y
	IF NOT "!LLFLAG!" == "" SET ERRFLAG=Y
	SET KKFLAG=Y
) ELSE IF "%option%" == "-L" (
	SHIFT
	SET KRB5_CONFIG=
	SET _KRB5_CONFIG_SOURCE=!_C_DNS!
	IF NOT "!KFLAG!" == "" SET ERRFLAG=Y
	IF NOT "!KKFLAG!" == "" SET ERRFLAG=Y
	SET LLFLAG=Y
) ELSE IF "%option%" == "-c" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET KRB5CCNAME=%arg%
		SET _KRB5CCNAME_SOURCE=!_C_OPT!
		SHIFT
	) ELSE (
		SET ERRFLAG=Y
	)
	IF NOT "!CCFLAG!" == "" SET ERRFLAG=Y
	SET CFLAG=Y
) ELSE IF "%option%" == "-C" (
	SHIFT
	SET KRB5CCNAME=
	IF NOT "!CFLAG!" == "" SET ERRFLAG=Y
	SET CCFLAG=Y
) ELSE IF "%option%" == "-e" (
	SHIFT
	SET EFLAG=Y
) ELSE IF "%option%" == "-i" (
	SHIFT
	SET IFLAG=Y
) ELSE IF "%option%" == "-j" (
	SHIFT
	REM can use the later JDK_JAVA_OPTIONS in place of JAVA_TOOL_OPTIONS
	SET JFLAG=Y
) ELSE IF "%option%" == "-a" (
	REM this option needs Git for Windows UNIX tools
	SHIFT
	IF "%arg%" == "" (
		GOTO endparse
	)
	IF NOT "!TFLAG!" == "" (
		GOTO endparse
	)
	IF NOT "!PFLAG!" == "" SET ERRFLAG=Y
	SET AFLAG=Y
) ELSE IF "%option%" == "-x" (
	SHIFT
	SET XFLAG=Y
) ELSE IF "%option%" == "-w" (
	SHIFT
	SET WFLAG=Y
) ELSE IF "%option%" == "-p" (
	SHIFT
	IF NOT "!AFLAG!" == "" SET ERRFLAG=Y
	SET PFLAG=Y
) ELSE IF "%option%" == "-J" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET JAVA_HOME=%arg%
		SET _JAVA_HOME_SOURCE=!_C_OPT!
		SHIFT
	) ELSE (
		SET ERRFLAG=Y
	)
	SET JJFLAG=Y
) ELSE IF NOT "%option:~0,1%" == "-" (
	SET arg=%option%
	REM SHIFT
	GOTO endparse
) ELSE (
	IF "!PFLAG!" == "" SET ERRFLAG=Y
	GOTO endparse
)

GOTO parse
:endparse

IF "%1" == "" (
	IF NOT "!PFLAG!"! == "" (
		REM prompt for TNS alias
	) ELSE (
		IF "!AFLAG!" == "" SET ERRFLAG=Y
	)
) ELSE (
	IF NOT "!PFLAG!" == "" SET ERRFLAG=Y
)

REM If TNS_ADMIN not set on command line or in environment get from registry
IF "!TNS_ADMIN!" == "" (
	CALL :regquery TNS_ADMIN
	SET _TNS_SOURCE=!_C_REG!
)

IF NOT "!TNS_ADMIN!" == "" (
	IF NOT EXIST "!TNS_ADMIN!\tnsnames.ora" (
		IF "!EFLAG!" == "" (
			IF "!ERRFLAG!" == "" (
				ECHO !_C_ERR!!PROG!!_C_OFF!: TNS File !TNS_ADMIN!\tnsnames.ora does not exist>&2
				EXIT /B 1
			)
		)
	)
	SET SQLOPTS=!SQLOPTS! -tnsadmin !TNS_ADMIN!
)

IF NOT "!AFLAG!" == "" (
	IF NOT EXIST "C:\Program Files\Git\usr\bin\awk.exe" (
		ECHO !_C_ERR!!PROG!!_C_OFF!: Install Git for Windows to use this option>&2
		exit /B 1
	)
	IF "!TNS_ADMIN!" == "" (
		ECHO !_C_ERR!!PROG!!_C_OFF!: TNS_ADMIN not set or no default>&2
		exit /B 1
	)
	awk "/^[A-Z0-1]* =/ { print $1 }" %TNS_ADMIN%\tnsnames.ora
	EXIT /B 0
)
REM IF NOT "!KFLAG!" == "" (
REM 	IF NOT "!KKFLAG!" == "" (
REM 		SET ERRFLAG=Y
REM 	)
REM )
REM IF NOT "!CFLAG!" == "" (
REM 	IF NOT "!CCFLAG!" == "" (
REM 		SET ERRFLAG=Y
REM 	)
REM )
IF NOT "!WFLAG!" == "" (
	IF "!JFLAG!" == "" (
		SET ERRFLAG=Y
	)
)

SET PROPS=!SQLDEV_HOME!\sqldeveloper\bin\version.properties
CALL :getprop VER_FULL !PROPS!
CALL :getprop VER !PROPS!
SET CONF=%APPDATA%\sqldeveloper\!VER!\product.conf
CALL :getconf SetJavaHome !CONF!

IF "!JJFLAG!" == "" (
	IF NOT "!SetJavaHome!" == "" (
		REM Overrides all JAVA_HOME settings unless -J specified
		SET JAVA_HOME=!SetJavaHome!
	)
)
IF NOT "%JAVA_HOME%" == "" (
	IF NOT EXIST "%JAVA_HOME%\bin\java.exe" (
		ECHO !_C_ERR!!PROG!!_C_OFF!: invalid JAVA_HOME %JAVA_HOME%>&2
		IF "!ERRFLAG!" == "" EXIT /B 1
		SET ERRFLAG=Y
	)
)

IF "!LLFLAG!" == "" (
	IF "%KRB5_CONFIG%" == "" (
		REM set after SetJavaHome evaluation
		REM %PROGRAMDATA%\Kerberos\krb5.conf is system default for MIT Kerberos5
		REM %APPDATA%\krb5.conf is a fallback for MIT Kerberos5
		REM SET KRB5_CONFIG=%APPDATA%\krb5.conf
		IF NOT "!JAVA_HOME!" == "" (
			IF EXIST !JAVA_HOME!\conf\security\krb5.conf SET KRB5_CONFIG=!JAVA_HOME!\conf\security\krb5.conf
		) ELSE (
			IF EXIST !SQLDEV_HOME!\jdk\jre\conf\security\krb5.conf SET KRB5_CONFIG=!SQLDEV_HOME!\jdk\jre\conf\security\krb5.conf
		)
	)
)

IF NOT "!KRB5_CONFIG!" == "" (
	IF NOT "!JFLAG!" == "" (
		SET JAVA_TOOL_OPTIONS=!JAVA_TOOL_OPTIONS! -Djava.security.krb5.conf=!KRB5_CONFIG!
	)
	SET SQLOPTS=!SQLOPTS! -krb5_config !KRB5_CONFIG!
)

IF NOT "!KRB5CCNAME!" == "" (
	REM JAAS set Cache
	IF "!JFLAG!" == "" SET SQLOPTS=!SQLOPTS! -krb5ccname !KRB5CCNAME!
)

REM IF NOT "!ERRFLAG!" == "" GOTO usage

IF NOT "!PFLAG!" == "" (
	IF "!ERRFLAG!" == "" (
		SET /p p="Enter TNS alias: "
	)
) ELSE (
	SET p=%~1
)
SET alias=%p:*@=%

IF NOT "!IFLAG!" == "" (
	REM Later versions of sqlcl support:
	REM ECHO set sqlprompt "@red| SQL|@> " > !SQLPATH!\login.sql
	
	SET colour=31
	CALL :hexprint "set sqlprompt 0x220x1b[!colour!mSQL0x1b[0m0x3e 0x22"> !SQLPATH!\login.sql

	ECHO set statusbar on>> !SQLPATH!\startup.sql
	ECHO set statusbar add editmode>> !SQLPATH!\startup.sql
	ECHO set statusbar add txn>> !SQLPATH!\startup.sql
	ECHO set statusbar add timing>> !SQLPATH!\startup.sql
	ECHO set highlighting on>> !SQLPATH!\startup.sql
	ECHO set highlighting keyword foreground green>> !SQLPATH!\startup.sql
	ECHO set highlighting identifier foreground magenta>> !SQLPATH!\startup.sql
	ECHO set highlighting string foreground yellow>> !SQLPATH!\startup.sql
	ECHO set highlighting number foreground cyan>> !SQLPATH!\startup.sql
	ECHO set highlighting comment background white>> !SQLPATH!\startup.sql
	ECHO set highlighting comment foreground black>> !SQLPATH!\startup.sql
	ECHO set sqlformat ansiconsole -config=!SQLPATH!\highlight.json>> !SQLPATH!\startup.sql
	ECHO -- FORMAT RULES !SQLPATH!\formatter-rules.xml>> !SQLPATH!\startup.sql
)

IF NOT "!XFLAG!" == "" (
	SET KRB5_TRACE=%TEMP%\krb5_trace.log
	SET DEBUG=true
	ECHO. > !KRB5_TRACE!
) ELSE (
	SET DEBUG=false
)

IF NOT "!WFLAG!" == "" (
	IF "!ERRFLAG!" == "" (
		IF "!EFLAG!" == "" (
			IF EXIST !JAAS_CONFIG! DEL !JAAS_CONFIG!
		)
	)
)
IF NOT "!JFLAG!" == "" (
	REM can use the later JDK_JAVA_OPTIONS in place of JAVA_TOOL_OPTIONS
	IF "!JAVA_HOME!" == "" SET JAVA_HOME=!SQLDEV_HOME!\jdk
	SET JAVA_TOOL_OPTIONS=-Djava.security.auth.login.config=!JAAS_CONFIG! -Doracle.net.KerberosJaasLoginModule=!NAME!
	IF NOT EXIST !JAAS_CONFIG! CALL :jaasconfig
	SET _KRB5CCNAME_SOURCE=!_C_JAA!
)
IF NOT "!EFLAG!" == "" (
	IF NOT "!XFLAG!" == "" (
		ECHO KRB5_CONFIG=!KRB5_CONFIG!
		ECHO KRB5CCNAME=!KRB5CCNAME!
		ECHO TNS_ADMIN=!TNS_ADMIN!
	)
	IF NOT "!JFLAG!" == "" (
		ECHO JAVA_TOOL_OPTIONS: !JAVA_TOOL_OPTIONS!
	)
	ECHO sql %SQLOPTS% /@%alias%
	EXIT /B 0
)

IF NOT "!ERRFLAG!" == "" GOTO usage

SET PATH="!SQLPATH!\bin";%PATH%

sql %SQLOPTS% /@%alias%

ENDLOCAL
EXIT /B 0

:usage
	ECHO !_C_ERR!Usage!_C_OFF!: !_C_BLD!krb_sql!_C_OFF! [!_C_ARG!-e!_C_OFF!] [!_C_ARG!-K!_C_OFF!^|!_C_ARG!-L!_C_OFF!^|!_C_ARG!-k!_C_OFF! !_C_OPT!krb5_config!_C_OFF!] [!_C_ARG!-t!_C_OFF! !_C_OPT!tns_admin!_C_OFF!] [!_C_ARG!-i!_C_OFF!] [!_C_ARG!-j!_C_OFF![!_C_ARG!-w!_C_OFF!]] [!_C_ARG!-J!_C_OFF! !_C_OPT!java_home!_C_OFF!] [!_C_ARG!-x!_C_OFF!] !_C_ARG!-p!_C_OFF!^|!_C_OPT!tns_alias!_C_OFF!>&2
	IF NOT "!LLFLAG!" == "" SET KRB5_CONFIG=DNS
	ECHO   !_C_ARG!-k!_C_OFF! !_C_OPT!krb5_config!_C_OFF!   Specify !_C_ENV!KRB5_CONFIG!_C_OFF! (default: !_KRB5_CONFIG_SOURCE!!KRB5_CONFIG!!_C_OFF!^)>&2
	ECHO   !_C_ARG!-K!_C_OFF!               Unset any value of !_C_ENV!KRB5_CONFIG!_C_OFF! i.e. use !_C_INT!internal!_C_OFF! default>&2
	ECHO   !_C_ARG!-L!_C_OFF!               Unset any value of !_C_ENV!KRB5_CONFIG!_C_OFF! and !_C_INT!internal!_C_OFF! default i.e. use !_C_DNS!DNS SRV!_C_OFF! lookup>&2
	ECHO   !_C_ARG!-t!_C_OFF! !_C_OPT!tns_admin!_C_OFF!     Specify !_C_ENV!TNS_ADMIN!_C_OFF! (default: !_TNS_SOURCE!!TNS_ADMIN!!_C_OFF!^)>&2
	ECHO                     if not in !_C_ENV!environment!_C_OFF! try !_C_REG!registry!_C_OFF!>&2
	IF NOT "!JFLAG!" == "" (
		ECHO   !_C_ARG!-c!_C_OFF! !_C_OPT!krb5ccname!_C_OFF!    Specify !_C_ENV!KRB5CCNAME!_C_OFF! (default: !_KRB5CCNAME_SOURCE!JAAS!_C_OFF!^)>&2
		C
		ECHO   !_C_ARG!-c!_C_OFF! !_C_OPT!krb5ccname!_C_OFF!    Specify !_C_ENV!KRB5CCNAME!_C_OFF! (default: !_KRB5CCNAME_SOURCE!!KRB5CCNAME!!_C_OFF!^)>&2
	)
	ECHO   !_C_ARG!-C!_C_OFF!               Unset any default value of !_C_ENV!KRB5CCNAME!_C_OFF!>&2
	ECHO   !_C_ARG!-e!_C_OFF!               Echo the command only>&2
	ECHO   !_C_ARG!-i!_C_OFF!               Install a template startup.sql>&2
	ECHO   !_C_ARG!-j!_C_OFF!               Use !_C_JAA!JAAS!_C_OFF!. The environment variable !_C_ENV!JAAS_CONFIG!_C_OFF! can be set to use>&2
        ECHO                     another login file (default: !_C_INT!!HOMEDRIVE!!HOMEPATH!\.java.login.config!_C_OFF!^)>&2
	ECHO   !_C_ARG!-w!_C_OFF!               Overwrite !_C_JAA!JAAS!_C_OFF! configuration with internal defaults>&2
	ECHO   !_C_ARG!-x!_C_OFF!               Produce trace (in %TEMP%\krb5_trace.log)>&2
	IF NOT "!JAVA_HOME!" == "" (
		ECHO   !_C_ARG!-J!_C_OFF! !_C_OPT!java_home!_C_OFF!     Specify !_C_ENV!JAVA_HOME!_C_OFF! (default: !_JAVA_HOME_SOURCE!!JAVA_HOME!!_C_OFF!^) if unset>&2
	) ELSE (
		ECHO   !_C_ARG!-J!_C_OFF! !_C_OPT!java_home!_C_OFF!     Specify !_C_ENV!JAVA_HOME!_C_OFF! (default: !_JAVA_HOME_SOURCE!!SQLDEV_HOME!\jdk\jre!_C_OFF!^) if unset>&2
	)
	ECHO                     use SetJavaHome from !_C_CFG!product.conf!_C_OFF! or SQL Developer built-in JDK>&2
	ECHO   !_C_ARG!-p!_C_OFF!               Prompt the user for !_C_OPT!tns_alias!_C_OFF!>&2

	ECHO.>&2
	ECHO !_C_ERR!Usage!_C_OFF!: !_C_BLD!krb_sql!_C_OFF! !_C_ARG!-a!_C_OFF! [!_C_ARG!-t !_C_OPT!tns_admin!_C_OFF!]>&2
	ECHO   !_C_ARG!-a!_C_OFF!               Print aliases>&2
	ECHO   !_C_ARG!-t!_C_OFF! !_C_OPT!tns_admin!_C_OFF!     Specify !_C_ENV!TNS_ADMIN!_C_OFF! (default: !_TNS_SOURCE!!TNS_ADMIN!!_C_OFF!^)>&2
ENDLOCAL
EXIT /B 1

:hexPrint  string  [rtnVar]
	for /f eol^=^%LF%%LF%^ delims^= %%A in (
		'forfiles /p "%~dp0." /m "%~nx0" /c "cmd /c echo(%~1"'
	) do if "%~2" neq "" (set %~2=%%A) else echo(%%A
EXIT /B

REM jaasconfig: create JAAS Config using keytab and cache
REM When multiple mechanisms to retrieve a ticket or key are provided, the preference order is:
REM    1. ticket cache
REM    2. keytab
REM    3. shared state
REM    4. user prompt
REM MB JAAS defaults for cache and keytab differ from MIT
:jaasconfig
	SET _KRB5_KTNAME=!KRB5_KTNAME!
	CALL :canon  _KRB5_KTNAME
	ECHO !NAME! { > !JAAS_CONFIG!
  	ECHO   com.sun.security.auth.module.Krb5LoginModule required>> !JAAS_CONFIG!
  	ECHO   refreshKrb5Config=true>> !JAAS_CONFIG!
  	ECHO   doNotPrompt=true>> !JAAS_CONFIG!
  	ECHO   useTicketCache=true>> !JAAS_CONFIG!
  	REM There are many combinations of KRB5CCNAME or -krb5ccname and ticketCache
	IF NOT "!KRB5CCNAME!" == "" (
		REM If not specified default is {user.home}{file.separator}krb5cc_{user.name}
		SET _KRB5CCNAME=!KRB5CCNAME!
		CALL :canon  _KRB5CCNAME
		ECHO   ticketCache="FILE:!_KRB5CCNAME!">> !JAAS_CONFIG!
	)
  	ECHO   useKeyTab=true>> !JAAS_CONFIG!
	REM If not specified default is {user.home}{file.separator}krb5.keytab
  	ECHO   keyTab="FILE:!_KRB5_KTNAME!">> !JAAS_CONFIG!
	REM Required to negotiate with KDC when requesting TGT
	CALL :getuserprincipal PRINCIPAL
	CALL :formatprincipal PRINCIPAL 
  	REM ECHO   principal=!USERNAME!>> !JAAS_CONFIG!
  	REM ECHO   principal="!PRINCIPAL!">> !JAAS_CONFIG!
  	ECHO   principal="!PRINCIPAL!">> !JAAS_CONFIG!
  	ECHO   storeKey=false>> !JAAS_CONFIG!
  	ECHO   renewTGT=false>> !JAAS_CONFIG!
  	ECHO   debug=!DEBUG!;>> !JAAS_CONFIG!
	ECHO }; >> !JAAS_CONFIG!
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

REM getprop: retrieve a setting from a .properties file
:getprop str file
        FOR /F "tokens=1,2 delims=^=" %%i IN (%2) DO (IF %%i == %1 CALL SET %~1=%%j%%)

EXIT /B 0

REM getconf: retrieve a setting from a .conf file
:getconf str file
	FOR /F "tokens=1,2" %%i IN (%2) DO (IF %%i == %1 CALL SET %~1=%%j%%)
EXIT /B 0

REM canon: canonicalize path URLs for Java
:canon str
	FOR %%a IN ("\=/") DO (
		CALL SET %~1=%%%~1:%%~a%%
	)
EXIT /B 0

REM getuserprincipal: set user to userPrincipalName
:getuserprincipal user
	FOR /f "tokens=1" %%i IN ('powershell -NoLogo -NoProfile -NonInteractive -OutputFormat Text -Command ^(Get-AdUser %USERNAME% ^^^| Select-Object UserPrincipalName^).UserPrincipalName') DO (CALL set %~1=%%i%%)
EXIT /B 0

REM formatprincipal: format principal to standard Kerberos capitalization return value in var
:formatprincipal principal
	CALL SET _principal=%%%~1%%%
	FOR /f "delims=@" %%i IN ("%_principal%") DO (set _primary=%%i)
	FOR /f "tokens=2 delims=@" %%i IN ("%_principal%") DO (set _realm=%%i)
	CALL :toupper _realm
	CALL SET %~1=%%_primary%%@%%_realm%%
EXIT /B 0
