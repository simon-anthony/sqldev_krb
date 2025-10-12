@ECHO off
REM krb_sql: SQLcl using Kerberos

SETLOCAL enabledelayedexpansion
SET ORACLE_HOME=
IF "%SQLDEV_HOME%" == "" (
	SET SQLDEV_HOME=C:\Oracle\sqldeveloper
)
SET SQLPATH=!SQLDEV_HOME!\sqldeveloper

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
	REM This is the default cache unles overridden by specifying KRB5CCNAME
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
) ELSE IF "%option%" == "-T" (
	SHIFT
	SET TNS_ADMIN=
	SET TTFLAG=y
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
	awk "/^[A-Z0-1]* =/ { print $1 }" %TNS_ADMIN%\tnsnames.ora
	EXIT /B 1
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

IF NOT "!KFLG!" == "" (
	IF NOT "!KKFLG!" == "" (
		GOTO usage
	)
)
IF NOT "!TFLG!" == "" (
	IF NOT "!TTFLG!" == "" (
		GOTO usage
	)
)
IF NOT "!CFLG!" == "" (
	IF NOT "!CCFLG!" == "" (
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
IF NOT "!TNS_ADMIN!" == "" (
	SET SQLOPTS=!SQLOPTS! -tnsadmin !TNS_ADMIN!
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
	ECHO Usage: krb_sql [-e] [-K^|-k ^<krb5_config^>] [-T^|-t ^<tns_admin^>] ^<tns_alias^>
	ECHO   -k ^<krb5_config^> specify KRB5_CONFIG (default: !KRB5_CONFIG!^)
	ECHO   -K               unset any default value of KRB5_CONFIG
	ECHO   -t ^<tns_admin^>   specify TNS_ADMIN (default: !TNS_ADMIN!^)
	ECHO   -T               unset any default value of TNS_ADMIN
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
  	ECHO storeKey=false >> !JAAS_CONFIG!
  	ECHO renewTGT=false >> !JAAS_CONFIG!
  	ECHO debug=true; >> !JAAS_CONFIG!
	ECHO }; >> !JAAS_CONFIG!
EXIT /B
