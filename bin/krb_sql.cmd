@ECHO off
REM krb_sql: SQLcl using Kerberos
REM vim: fileformat=dos:

SETLOCAL enabledelayedexpansion

SET ORACLE_HOME=
IF "%SQLDEV_HOME%" == "" (
	SET SQLDEV_HOME=C:\Oracle\sqldeveloper
)
SET SQLPATH=!SQLDEV_HOME!\sqldeveloper

IF NOT EXIST !SQLDEV_HOME!\sqldeveloper.exe (
	ECHO Invalid SQL Developer home>&2
	EXIT /B 1
)

SET _TNS_SOURCE=[96m
SET SQLOPTS=-kerberos -thin -noupdates

IF "%KRB5_CONFIG%" == "" (
	REM set after SetJavaHome evaluation
	REM %PROGRAMDATA%\Kerberos\krb5.conf is system default for MIT Kerberos5
	REM %APPDATA%\krb5.conf is a fallback for MIT Kerberos5
	REM SET KRB5_CONFIG=%APPDATA%\krb5.conf
	REM SET KRB5_CONFIG=!SQLDEV_HOME!\jdk\jre\conf\security\krb5.conf
	SET _KRB5_CONFIG_SOURCE=[31m
) ELSE (
	SET _KRB5_CONFIG_SOURCE=[96m
)

IF "%KRB5CCNAME%" == "" (
	REM This is the default cache unles overridden by specifying KRB5CCNAME
	SET KRB5CCNAME=%LOCALAPPDATA%\krb5cc_%USERNAME%
	SET _KRB5CCNAME_SOURCE=[31m
) ELSE (
	SET _KRB5CCNAME_SOURCE=[96m
)

IF "%JAAS_CONFIG%" == "" (
	REM This is the default file used in <jre_home>\conf\security\java.security
	SET JAAS_CONFIG=%HOMEDRIVE%%HOMEPATH%\.java.login.config
	SET _JAAS_CONFIG_SOURCE=[31m
) ELSE (
	SET _JAAS_CONFIG_SOURCE=[96m
)

IF "%JAVA_HOME%" == "" (
	SET _JAVA_HOME_SOURCE=[31m
) ELSE (
	SET _JAVA_HOME_SOURCE=[96m
)

REM Define a Linefeed variable - the two lines after are significant
set LF=^



SET ERRFLAG=

:parse
IF "%1" == "" SET ERRFLAG=Y

SET option=%~1
SET arg=%~2

IF "%option%" == "-k" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET KRB5_CONFIG=%arg%
		SET _KRB5_CONFIG_SOURCE=[33m
		SHIFT
	) ELSE (
		SET ERRFLAG=y
	)
	SET KFLAG=y
) ELSE IF "%option%" == "-t" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET TNS_ADMIN=%arg%
		SHIFT
	) ELSE (
		SET ERRFLAG=y
	)
	SET _TNS_SOURCE=[33m
	SET TFLAG=y
	IF NOT "!AFLAG!" == "" (
		GOTO endparse
	)
) ELSE IF "%option%" == "-K" (
	SHIFT
	SET KRB5_CONFIG=
	SET KKFLAG=y
) ELSE IF "%option%" == "-c" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET KRB5CCNAME=%arg%
		SET _KRB5CCNAME_SOURCE=[33m
		SHIFT
	) ELSE (
		SET ERRFLAG=y
	)
	SET CFLAG=y
) ELSE IF "%option%" == "-C" (
	SHIFT
	SET KRB5CCNAME=
	SET CCFLAG=y
) ELSE IF "%option%" == "-e" (
	SHIFT
	SET EFLAG=y
) ELSE IF "%option%" == "-i" (
	SHIFT
	SET IFLAG=y
) ELSE IF "%option%" == "-j" (
	SHIFT
	REM can use the later JDK_JAVA_OPTIONS in place of JAVA_TOOL_OPTIONS
	SET JFLAG=y
) ELSE IF "%option%" == "-a" (
	REM this option needs Git for Windows UNIX tools
	SHIFT
	SET AFLAG=y
	IF "%arg%" == "" (
		GOTO endparse
	)
	IF NOT "!TFLAG!" == "" (
		GOTO endparse
	)
) ELSE IF "%option%" == "-x" (
	SHIFT
	SET XFLAG=y
) ELSE IF "%option%" == "-w" (
	SHIFT
	SET WFLAG=y
) ELSE IF "%option%" == "-J" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET JAVA_HOME=%arg%
		SET _JAVA_HOME_SOURCE=[33m
		SHIFT
	) ELSE (
		SET ERRFLAG=y
	)
	SET JJFLAG=y
) ELSE IF NOT "%option:~0,1%" == "-" (
	SET arg=%option%
	REM SHIFT
	GOTO endparse
) ELSE (
	SET ERRFLAG=y
	GOTO endparse
)

GOTO parse
:endparse

IF "%1" == "" (
	IF "!AFLAG!" == "" SET ERRFLAG=Y
)

REM If TNS_ADMIN not set on command line or in environment get from registry
IF "!TNS_ADMIN!" == "" (
	CALL :regquery TNS_ADMIN
	SET _TNS_SOURCE=[36m
)

IF NOT "!TNS_ADMIN!" == "" (
	IF NOT EXIST "!TNS_ADMIN!\tnsnames.ora" (
		IF "!EFLAG!" == "" (
			IF "!ERRFLAG!" == "" (
				ECHO TNS File !TNS_ADMIN!\tnsnames.ora does not exist>&2
				EXIT /B 1
			)
		)
	)
	SET SQLOPTS=!SQLOPTS! -tnsadmin !TNS_ADMIN!
)

IF NOT "!AFLAG!" == "" (
	IF NOT EXIST "C:\Program Files\Git\usr\bin\awk.exe" (
		ECHO Install Git for Windows to use this option>&2
		exit /B 1
	)
	IF "!TNS_ADMIN!" == "" (
		ECHO TNS_ADMIN not set or no default>&2
		exit /B 1
	)
	awk "/^[A-Z0-1]* =/ { print $1 }" %TNS_ADMIN%\tnsnames.ora
	EXIT /B 0
)
IF NOT "!KFLAG!" == "" (
	IF NOT "!KKFLAG!" == "" (
		SET ERRFLAG=Y
	)
)
IF NOT "!CFLAG!" == "" (
	IF NOT "!CCFLAG!" == "" (
		SET ERRFLAG=Y
	)
)
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
		ECHO Invalid JAVA_HOME %JAVA_HOME%>&2
		REM EXIT /B 1
		SET ERRFLAG=Y
	)
)

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

IF NOT "!KRB5_CONFIG!" == "" (
	IF NOT "!JFLAG!" == "" (
		SET JAVA_TOOL_OPTIONS=!JAVA_TOOL_OPTIONS! -Djava.security.krb5.conf=!KRB5_CONFIG!
	)
	SET SQLOPTS=!SQLOPTS! -krb5_config !KRB5_CONFIG!
)
IF NOT "!KRB5CCNAME!" == "" (
	SET SQLOPTS=!SQLOPTS! -krb5ccname !KRB5CCNAME!
)

IF NOT "!ERRFLAG!" == "" GOTO usage

SET p=%~1
SET alias=%p:*@=%

IF NOT "!IFLAG!" == "" (
	REM Later versions of sqlcl support:
	REM ECHO set sqlprompt "@red| SQL|@> " > !SQLPATH!\login.sql
	
	SET colour=31
	CALL :hexprint "set sqlprompt 0x220x1b[!colour!mSQL0x1b[0m0x3e 0x22" > !SQLPATH!\login.sql

	ECHO set statusbar on >> !SQLPATH!\startup.sql
	ECHO set statusbar add editmode >> !SQLPATH!\startup.sql
	ECHO set statusbar add txn >> !SQLPATH!\startup.sql
	ECHO set statusbar add timing >> !SQLPATH!\startup.sql
	ECHO set highlighting on >> !SQLPATH!\startup.sql
	ECHO set highlighting keyword foreground green >> !SQLPATH!\startup.sql
	ECHO set highlighting identifier foreground magenta >> !SQLPATH!\startup.sql
	ECHO set highlighting string foreground yellow >> !SQLPATH!\startup.sql
	ECHO set highlighting number foreground cyan >> !SQLPATH!\startup.sql
	ECHO set highlighting comment background white >> !SQLPATH!\startup.sql
	ECHO set highlighting comment foreground black >> !SQLPATH!\startup.sql
	ECHO set sqlformat ansiconsole -config=!SQLPATH!\highlight.json >> !SQLPATH!\startup.sql
	ECHO -- FORMAT RULES !SQLPATH!\formatter-rules.xml >> !SQLPATH!\startup.sql
)
IF NOT "!XFLAG!" == "" (
	SET KRB5_TRACE=%TEMP%\krb5_trace.log
	SET DEBUG=true
	ECHO. > !KRB5_TRACE!
) ELSE (
	SET DEBUG=false
)

IF NOT "!WFLAG!" == "" (
	IF EXIST !JAAS_CONFIG! DEL !JAAS_CONFIG!
)
IF NOT "!JFLAG!" == "" (
	REM can use the later JDK_JAVA_OPTIONS in place of JAVA_TOOL_OPTIONS
	IF "!JAVA_HOME!" == "" SET JAVA_HOME=!SQLDEV_HOME!\jdk
	SET JAVA_TOOL_OPTIONS=-Djava.security.auth.login.config=!JAAS_CONFIG! -Doracle.net.KerberosJaasLoginModule=Oracle
	IF NOT EXIST !JAAS_CONFIG! CALL :jaasconfig
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
SET PATH="!SQLPATH!\bin";%PATH%

sql %SQLOPTS% /@%alias%

ENDLOCAL
EXIT /B 0

:usage
	ECHO [91mUsage[0m: [1mkrb_sql[0m [[93m-e[0m] [[93m-K[0m^|[93m-k[0m [33mkrb5_config[0m] [[93m-t[0m [33mtns_admin[0m] [[93m-i[0m] [[93m-j[0m[[93m-w[0m]] [[93m-J[0m [33mjava_home[0m] [[93m-x[0m] [33mtns_alias[0m>&2
	ECHO   [93m-k[0m [33mkrb5_config[0m   Specify [96mKRB5_CONFIG[0m (default: !_KRB5_CONFIG_SOURCE!!KRB5_CONFIG![0m^)>&2
	ECHO   [93m-K[0m               Unset any default value of [96mKRB5_CONFIG[0m i.e. use DNS SRV lookup>&2
	ECHO   [93m-t[0m [33mtns_admin[0m     Specify [96mTNS_ADMIN[0m (default: !_TNS_SOURCE!!TNS_ADMIN![0m^)>&2
	ECHO                     if not in [96menvironment[0m try [36mregistry[0m>&2
	ECHO   [93m-c[0m [33mkrb5ccname[0m    Specify [96mKRB5CCNAME[0m (default: !_KRB5CCNAME_SOURCE!!KRB5CCNAME![0m^)>&2
	ECHO   [93m-C[0m               Unset any default value of [96mKRB5CCNAME[0m>&2
	ECHO   [93m-e[0m               Echo the command only>&2
	ECHO   [93m-i[0m               Install a template startup.sql>&2
	ECHO   [93m-j[0m               Use JAAS - overide the default file with [96mJAAS_CONFIG[0m >&2
	ECHO   [93m-w[0m               Overwrite JAAS configuration !_JAAS_CONFIG_SOURCE!!JAAS_CONFIG![0m>&2
	ECHO   [93m-x[0m               Produce trace (in %TEMP%\krb5_trace.log)>&2
	IF NOT "!JAVA_HOME!" == "" (
		ECHO   [93m-J[0m [33mjava_home[0m     Specify [96mJAVA_HOME[0m (default: !_JAVA_HOME_SOURCE!!JAVA_HOME![0m^) if unset>&2
	) ELSE (
		ECHO   [93m-J[0m [33mjava_home[0m     Specify [96mJAVA_HOME[0m (default: !_JAVA_HOME_SOURCE!!SQLDEV_HOME!\jdk\jre[0m^) if unset>&2
	)
	ECHO                     use SetJavaHome from product.conf or SQL Developer built-in JDK>&2
	ECHO.>&2
	ECHO [91mUsage[0m: [1mkrb_sql[0m [93m-a[0m [[93m-t [33mtns_admin[0m]>&2
	ECHO   [93m-a[0m               Print aliases>&2
	ECHO   [93m-t[0m [33mtns_admin[0m     Specify [96mTNS_ADMIN[0m (default: !_TNS_SOURCE!!TNS_ADMIN![0m^)>&2
ENDLOCAL
EXIT /B 1

:hexPrint  string  [rtnVar]
	for /f eol^=^%LF%%LF%^ delims^= %%A in (
		'forfiles /p "%~dp0." /m "%~nx0" /c "cmd /c echo(%~1"'
	) do if "%~2" neq "" (set %~2=%%A) else echo(%%A
EXIT /B

:jaasconfig
	ECHO Oracle { > !JAAS_CONFIG!
  	ECHO   com.sun.security.auth.module.Krb5LoginModule required>> !JAAS_CONFIG!
  	ECHO   refreshKrb5Config=true>> !JAAS_CONFIG!
  	ECHO   doNotPrompt=true>> !JAAS_CONFIG!
  	ECHO   useKeyTab=false>> !JAAS_CONFIG!
  	ECHO   useTicketCache=true >> !JAAS_CONFIG!
  	REM It is less problematic to use KRB5CCNAME or -krb5ccname than specify ticketCache
  	REM ECHO   ticketCache=!KRB5CCNAME!>> !JAAS_CONFIG!
  	ECHO   storeKey=false>> !JAAS_CONFIG!
  	ECHO   renewTGT=false>> !JAAS_CONFIG!
  	ECHO   debug=!DEBUG!;>> !JAAS_CONFIG!
	ECHO }; >> !JAAS_CONFIG!
EXIT /B

:regquery str
	REM Retrieve value of str from HKLM\SOFTWARE\ORACLE
	FOR /f "tokens=3" %%i IN ('reg query HKLM\SOFTWARE\ORACLE /s /f "%~1" /e ^| findstr %~1') DO (CALL set %~1=%%i%%)
EXIT /B 0

:toUpper str
	FOR %%a IN ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I"
		"j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R"
		"s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z") DO (
		CALL SET %~1=%%%~1:%%~a%%
	)
EXIT /B 0

:toLower str
	FOR %%a IN ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i"
		"J=j" "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r"
		"S=s" "T=t" "U=u" "V=v" "W=w" "X=x" "Y=y" "Z=z") DO (
		CALL SET %~1=%%%~1:%%~a%%
	)
EXIT /B 0

REM retrieve a setting from a .properties file
:getprop str file
        FOR /F "tokens=1,2 delims=^=" %%i IN (%2) DO (IF %%i == %1 CALL SET %~1=%%j%%)

EXIT /B 0

REM retrieve a setting from a .conf file
:getconf str file
	FOR /F "tokens=1,2" %%i IN (%2) DO (IF %%i == %1 CALL SET %~1=%%j%%)
EXIT /B 0
