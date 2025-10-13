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
	REM %PROGRAMDATA%\Kerberos\krb5.conf is system default for MIT Kerberos5
	REM %APPDATA%\krb5.conf is a fallback for MIT Kerberos5
	SET KRB5_CONFIG=%APPDATA%\krb5.conf
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
	SET JAVA_HOME=!SQLDEV_HOME!\jdk
	SET JAVA_TOOL_OPTIONS=-Djava.security.auth.login.config=!JAAS_CONFIG! -Doracle.net.KerberosJaasLoginModule=Oracle
	IF NOT EXIST !JAAS_CONFIG! CALL :jaasconfig
	SET JFLAG=y
) ELSE IF "%option%" == "-a" (
	REM this option needs Git for Windowss UNIX tools
	SHIFT
	SET AFLAG=y
) ELSE IF NOT "%option:~0,1%" == "-" (
	SET arg=%option%
	REM SHIFT
	GOTO endparse
) ELSE (
	GOTO usage
)

GOTO parse
:endparse

IF "%1" == "" GOTO usage

REM If TNS_ADMIN not set on command line or in environment get from registry
IF "!TNS_ADMIN!" == "" call :regquery TNS_ADMIN

IF NOT "!TNS_ADMIN!" == "" (
	IF NOT EXIST "!TNS_ADMIN!\tnsnames.ora" (
		ECHO File !TNS_ADMIN!\tnsnames.ora does not exist 
		EXIT /B 1
	)
	SET SQLOPTS=!SQLOPTS! -tnsadmin !TNS_ADMIN!
)

IF NOT "!AFLAG!" == "" (
	IF NOT EXIST "C:\Program Files\Git\usr\bin\awk" (
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

IF NOT "!KRB5_CONFIG!" == "" (
	IF NOT "!JFLAG!" == "" (
		ECHO KRB5_CONFIG=!KRB5_CONFIG!
		SET JAVA_TOOL_OPTIONS=!JAVA_TOOL_OPTIONS! -Djava.security.krb5.conf=!KRB5_CONFIG!
	) ELSE (
		SET SQLOPTS=!SQLOPTS! -krb5_config !KRB5_CONFIG!
	)
)
IF NOT "!KRB5CCNAME!" == "" (
	SET SQLOPTS=!SQLOPTS! -krb5ccname !KRB5CCNAME!
)

SET p=%~1
SET alias=%p:*@=%

IF NOT "!EFLAG!" == "" (
	IF NOT "!JFLAG!" == "" (
		ECHO JAVA_TOOL_OPTIONS: !JAVA_TOOL_OPTIONS!
	)
	ECHO sql %SQLOPTS% /@%alias%
	EXIT /B 0
)
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

SET PATH="!SQLPATH!\bin";%PATH%

sql %SQLOPTS% /@%alias%

ENDLOCAL
EXIT /B 0

:usage
	IF "!TNS_ADMIN!" == "" call :regquery TNS_ADMIN
	ECHO Usage: krb_sql [-e] [-K^|-k ^<krb5_config^>] [-t ^<tns_admin^>] ^<tns_alias^>
	ECHO   -k ^<krb5_config^> specify KRB5_CONFIG (default: !KRB5_CONFIG!^)
	ECHO   -K               unset any default value of KRB5_CONFIG i.e. use DNS SRV lookup
	ECHO   -t ^<tns_admin^>   specify TNS_ADMIN (default: !TNS_ADMIN!^)
	ECHO   -c ^<krb5ccname^>  specify KRB5CCNAME (default: !KRB5CCNAME!^)
	ECHO   -C               unset any default value of KRB5CCNAME
	ECHO   -e               echo the command only
	ECHO   -i               install a template startup.sql
	ECHO   -j               use JAAS
	ECHO Usage: krb_sql -a
	ECHO   -a               print aliases
ENDLOCAL
EXIT /B 1

:hexPrint  string  [rtnVar]
	for /f eol^=^%LF%%LF%^ delims^= %%A in (
		'forfiles /p "%~dp0." /m "%~nx0" /c "cmd /c echo(%~1"'
	) do if "%~2" neq "" (set %~2=%%A) else echo(%%A
EXIT /B

:jaasconfig
	ECHO Oracle { > !JAAS_CONFIG!
  	ECHO com.sun.security.auth.module.Krb5LoginModule required >> !JAAS_CONFIG!
  	ECHO refreshKrb5Config=true >> !JAAS_CONFIG!
  	ECHO doNotPrompt=true >> !JAAS_CONFIG!
  	ECHO useKeyTab=false >> !JAAS_CONFIG!
  	ECHO useTicketCache=true >> !JAAS_CONFIG!
  	REM ECHO ticketCache=%%{LOCAL_APPDATA}\krb5cc_%%{username} >> !JAAS_CONFIG!
  	ECHO storeKey=false >> !JAAS_CONFIG!
  	ECHO renewTGT=false >> !JAAS_CONFIG!
  	ECHO debug=true; >> !JAAS_CONFIG!
	ECHO }; >> !JAAS_CONFIG!
EXIT /B

:regquery str
	REM If TNS_ADMIN not set on command line or in environment get from registry
	FOR /f "tokens=3" %%i IN ('reg query HKLM\SOFTWARE\ORACLE /s /f "%~1" /e ^| findstr %~1') DO (call set %~1=%%i%%)
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
