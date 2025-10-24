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
	ECHO Invalid SQL Developer home
	EXIT /B 1
)

SET SQLOPTS=-kerberos -thin -noupdates

IF "%KRB5_CONFIG%" == "" (
	REM set after SetJavaHome evaluation
	REM %PROGRAMDATA%\Kerberos\krb5.conf is system default for MIT Kerberos5
	REM %APPDATA%\krb5.conf is a fallback for MIT Kerberos5
	REM SET KRB5_CONFIG=%APPDATA%\krb5.conf
	REM SET KRB5_CONFIG=!SQLDEV_HOME!\jdk\jre\conf\security\krb5.conf
)
IF "%KRB5CCNAME%" == "" (
	REM This is the default cache unles overridden by specifying KRB5CCNAME
	SET KRB5CCNAME=%LOCALAPPDATA%\krb5cc_%USERNAME%
)
IF "%JAAS_CONFIG%" == "" (
	REM This is the default file used in <jre_home>\conf\security\java.security
	SET JAAS_CONFIG=%HOMEDRIVE%%HOMEPATH%\.java.login.config
)

REM Define a Linefeed variable - the two lines after are significant
set LF=^



:parse
IF "%1" == "" GOTO usage

SET option=%~1
SET arg=%~2

IF "%option%" == "-k" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET KRB5_CONFIG=%arg%
		SHIFT
	) ELSE (
		GOTO usage
	)
	SET KFLAG=y
) ELSE IF "%option%" == "-t" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET TNS_ADMIN=%arg%
		SHIFT
	) ELSE (
		GOTO usage
	)
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
) ELSE IF "%option%" == "-i" (
	SHIFT
	SET IFLAG=y
) ELSE IF "%option%" == "-j" (
	SHIFT
	REM can use the later JDK_JAVA_OPTIONS in place of JAVA_TOOL_OPTIONS
REM 	SET JAVA_HOME=!SQLDEV_HOME!\jdk
REM 	SET JAVA_TOOL_OPTIONS=-Djava.security.auth.login.config=!JAAS_CONFIG! -Doracle.net.KerberosJaasLoginModule=Oracle
REM 	IF NOT EXIST !JAAS_CONFIG! CALL :jaasconfig
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
		SHIFT
	) ELSE (
		GOTO usage
	)
	SET JJFLAG=y
) ELSE IF NOT "%option:~0,1%" == "-" (
	SET arg=%option%
	REM SHIFT
	GOTO endparse
) ELSE (
	GOTO usage
)

GOTO parse
:endparse

IF "%1" == "" (
	IF "!AFLAG!" == "" (
		GOTO usage
	)
)
REM If TNS_ADMIN not set on command line or in environment get from registry
IF "!TNS_ADMIN!" == "" CALL :regquery TNS_ADMIN

IF NOT "!TNS_ADMIN!" == "" (
	IF NOT EXIST "!TNS_ADMIN!\tnsnames.ora" (
		IF "!EFLAG!" == "" (
			ECHO TNS File !TNS_ADMIN!\tnsnames.ora does not exist 
		       	EXIT /B 1
		)
	)
	SET SQLOPTS=!SQLOPTS! -tnsadmin !TNS_ADMIN!
)

IF NOT "!AFLAG!" == "" (
	IF NOT EXIST "C:\Program Files\Git\usr\bin\awk.exe" (
		ECHO Install Git for Windows to use this option
		exit /B 1
	)
	IF "!TNS_ADMIN!" == "" (
		ECHO TNS_ADMIN not set or no default
		exit /B 1
	)
	awk "/^[A-Z0-1]* =/ { print $1 }" %TNS_ADMIN%\tnsnames.ora
	EXIT /B 0
)
IF NOT "!KFLAG!" == "" (
	IF NOT "!KKFLAG!" == "" (
		GOTO usage
	)
)
IF NOT "!CFLAG!" == "" (
	IF NOT "!CCFLAG!" == "" (
		GOTO usage
	)
)
IF NOT "!WFLAG!" == "" (
	IF "!JFLAG!" == "" (
		GOTO usage
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
		ECHO Invalid JAVA_HOME %JAVA_HOME%
		EXIT /B 1
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
	IF "!TNS_ADMIN!" == "" CALL :regquery TNS_ADMIN
	ECHO Usage: krb_sql [-e] [-K^|-k ^<krb5_config^>] [-t ^<tns_admin^>] [-i] [-j[-w]] [-J ^<java_home^>] [-x] ^<tns_alias^>
	ECHO   -k ^<krb5_config^> specify KRB5_CONFIG (default: !KRB5_CONFIG!^)
	ECHO   -K               unset any default value of KRB5_CONFIG i.e. use DNS SRV lookup
	ECHO   -t ^<tns_admin^>   specify TNS_ADMIN (default: !TNS_ADMIN!^)
	ECHO   -c ^<krb5ccname^>  specify KRB5CCNAME (default: !KRB5CCNAME!^)
	ECHO   -C               unset any default value of KRB5CCNAME
	ECHO   -e               echo the command only
	ECHO   -i               install a template startup.sql
	ECHO   -j               use JAAS 
	ECHO   -w               overwrite !JAAS_CONFIG!
	ECHO   -x               produce trace (in %TEMP%\krb5_trace.log)
	ECHO   -J ^<java_home^>   specify JAVA_HOME (default: !JAVA_HOME!^) if unset use 
	ECHO                    SetJavaHome from product.conf or SQL Developer built-in JDK
	ECHO Usage: krb_sql -a [-t ^<tns_admin^>] 
	ECHO   -a               print aliases
	ECHO   -t ^<tns_admin^>   specify TNS_ADMIN (default: !TNS_ADMIN!^)
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
	REM If TNS_ADMIN not set on command line or in environment get from registry
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
