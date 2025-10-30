@ECHO off
REM krb_conf: genarate configuration files
REM vim: fileformat=dos:
REM https://docs.oracle.com/en/java/javase/22/docs/api/jdk.security.auth/com/sun/security/auth/module/Krb5LoginModule.html

SETLOCAL enabledelayedexpansion

SET PROG=krb_conf
REM realm in upper case
SET REALM=%USERDNSDOMAIN%
CALL :toUpper REALM
REM domain in lower case
SET DOMAIN=%USERDNSDOMAIN%
CALL :toLower DOMAIN

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

REM Note that %~dp0 will be C:\path\to\ and %~dpf0 will be C:\path\to\file.cmd
SET BIN=%~dp0
SET ETC=%BIN:\bin=%etc

IF "%KRB5CCNAME%" == "" (
	SET _KRB5CCNAME_SOURCE=!_C_INT!
) ELSE (
	SET _KRB5CCNAME_SOURCE=!_C_ENV!
)

IF NOT "%SQLDEV_HOME%" == "" (
	SET _SQLDEV_HOME_SOURCE=!_C_ENV!
) 

IF "%JAVA_HOME%" == "" (
	SET _JAVA_HOME_SOURCE=!_C_INT!
) ELSE (
	SET _JAVA_HOME_SOURCE=!_C_ENV!
)

REM JAAS configuration entry name
SET NAME=Oracle
SET SHORTCUT=sqldeveloper
SET SHORTCUTSQL=sql
SET ERRFLAG=

:parse
IF "%1" == "" GOTO endparse

SET option=%~1
SET arg=%~2

IF "%option%" == "-c" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET _KRB5CCNAME_SOURCE=!_C_OPT!
		SHIFT
	) ELSE (
		SET ERRFLAG=Y
	)
	SET CFLAG=Y
) ELSE IF "%option%" == "-h" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET SQLDEV_HOME=%arg%
		SET _SQLDEV_HOME_SOURCE=!_C_OPT!
		SHIFT
	) ELSE (
		SET ERRFLAG=Y
	)
	SET HFLAG=Y
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
) ELSE IF "%option%" == "-t" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET KRB5_CONFIG_TEMPLATE=%arg%
		SHIFT
	) ELSE (
		SET ERRFLAG=Y
	)
	SET TFLAG=Y
) ELSE IF "%option%" == "-e" (
	SHIFT
	SET EFLAG=Y
) ELSE IF "%option%" == "-p" (
	SHIFT
	SET PFLAG=Y
) ELSE IF "%option%" == "-v" (
	SHIFT
	SET VFLAG=Y
) ELSE IF "%option%" == "-r" (
	SHIFT
	SET RFLAG=Y
) ELSE IF "%option%" == "-H" (
	SHIFT
	SET HHFLAG=Y
) ELSE IF "%option%" == "-w" (
	SHIFT
	IF NOT "!UFLG!" == "" SET ERRFLAG=Y
	SET WFLAG=Y
) ELSE IF "%option%" == "-u" (
	SHIFT
	IF NOT "!WFLG!" == "" SET ERRFLAG=Y
	SET UFLAG=Y
) ELSE IF "%option%" == "-E" (
	SHIFT
	SET EEFLAG=Y
) ELSE IF "%option%" == "-V" (
	SHIFT
	SET VVFLAG=Y
) ELSE (
	SET ERRFLAG=Y
	GOTO endparse
)

GOTO parse
:endparse

IF "%SQLDEV_HOME%" == "" (
	REM ECHO !_C_ERR!!PROG!!_C_OFF!: !_C_ENV!SQLDEV_HOME!_C_OFF! must be set in the environment or set with !_C_ARG!-h!_C_OFF!>&2
	SET SQLDEV_HOME=!_C_ERR!SQLDEV_HOME!_C_OFF!
	GOTO usage
)
IF NOT EXIST !SQLDEV_HOME!\sqldeveloper.exe (
	ECHO !_C_ERR!!PROG!!_C_OFF!: invalid SQL Developer home>&2
	EXIT /B 1
)

IF NOT "!HHFLAG!" == "" (
	IF "!HFLAG!" == "" (
		SET ERRFLAG=Y
	) ELSE (
		ECHO|SET /p="!_C_MSG!!PROG!!_C_OFF!: creating SQLDEV_HOME in registry: "
		SETX SQLDEV_HOME !SQLDEV_HOME! /M 2>&1 | FOR /F "tokens=1" %%i IN ('more') DO @(
			IF NOT "%%i" == "ERROR:" (
				ECHO HKEY_LOCAL_MACHINE
			) ELSE (
				SETX SQLDEV_HOME !SQLDEV_HOME! /M > NUL 2>&1
				ECHO HKEY_CURRENT_USER
			)
		)
	)
)

SET PROPS=!SQLDEV_HOME!\sqldeveloper\bin\version.properties
CALL :getprop VER_FULL !PROPS!
CALL :getprop VER !PROPS!
SET CONF=%APPDATA%\sqldeveloper\!VER!\product.conf
CALL :getconf SetJavaHome !CONF!

IF "!JJFLAG!" == "" (
	IF "!UFLAG!" == "" (
		IF NOT "!SetJavaHome!" == "" (
			REM Overrides all JAVA_HOME settings unless -J specified
			SET JAVA_HOME=!SetJavaHome!
			SET _JAVA_HOME_SOURCE=!_C_CFG!
		)
	)
)
REM TODO - IF KRB5_CONFIG set in environment use it or allow to be overriden with -k (and -K)
IF NOT "%JAVA_HOME%" == "" (
	IF NOT EXIST "%JAVA_HOME%\bin\java.exe" (
		ECHO !_C_ERR!!PROG!!_C_OFF!: invalid JAVA_HOME %JAVA_HOME%>&2
		IF "!ERRFLAG!" == "" EXIT /B 1
	)
	SET KRB5_CONFIG=%JAVA_HOME%\conf\security\krb5.conf
) ELSE (
	SET KRB5_CONFIG=!SQLDEV_HOME!\jdk\jre\conf\security\krb5.conf
)

IF NOT "!WFLAG!" == "" (
	IF "!JJFLAG!" == "" SET ERRFLAG=Y
)
IF NOT "!UFLAG!" == "" (
	IF NOT "!JJFLAG!" == "" SET ERRFLAG=Y
)
IF NOT "!VFLAG!" == "" (
	ECHO !VER_FULL!
	EXIT /B 0
)
IF "%CFLAG%" == "" (
	REM This is the default cache unless overridden by specifying KRB5CCNAME
	REM JDK kinit uses %USERPROFILE%\krb5cc_%USERNAME%
	REM SET KRB5CCNAME=%LOCALAPPDATA%\krb5cc_%USERNAME%
	IF NOT "%PFLAG%" == "" (
		IF "!KRB5CCNAME!" == "" SET KRB5CCNAME=FILE:!LOCALAPPDATA!\krb5cc_!USERNAME!
		IF "!KRB5_KTNAME!" == "" SET KRB5_KTNAME=FILE:!LOCALAPPDATA!\krb5_!USERNAME!.keytab
	) ELSE IF NOT "!RFLAG!" == "" (
		IF "!KRB5CCNAME!" == "" SET KRB5CCNAME=FILE:!LOCALAPPDATA!\krb5cc_!USERNAME!
		IF "!KRB5_KTNAME!" == "" SET KRB5_KTNAME=FILE:!LOCALAPPDATA!\krb5_!USERNAME!.keytab
	) ELSE (
		IF "!KRB5CCNAME!" == "" SET KRB5CCNAME=FILE:%%{LOCAL_APPDATA}/krb5cc_%%{username}
		IF "!KRB5_KTNAME!" == "" SET KRB5_KTNAME=FILE:%%{LOCAL_APPDATA}/krb5_%%{username}.keytab
	)
)

IF NOT "!JAVA_HOME!" == "" (
	CALL :javaversion !JAVA_HOME! VERSION
) ELSE (
	CALL :javaversion !SQLDEV_HOME!\jdk\jre VERSION
)
IF NOT "!VVFLAG!" == "" (
	ECHO !VERSION!
	EXIT /B 0
)

REM Maximum Java version supported by IDE is 21.1
IF "!UFLAG!" == "" (
	CALL :versionpart !VERSION! MAJOR
	CALL :versionpart !VERSION! MINOR 2
	IF !MAJOR! GTR 21 (
		ECHO !_C_ARG!!PROG!!_C_OFF!: Java releases [!MAJOR!.!MINOR!] above 21.1 not supported by IDE>&2
		REM EXIT /B 1
	)
	IF !MAJOR! EQU 21 (
		IF !MINOR! GTR 1 (
			ECHO !_C_ARG!!PROG!!_C_OFF!: Java releases [!MAJOR!.!MINOR!] above 21.1 not supported by IDE>&2
			REM EXIT /B 1
		)
	)
)

IF NOT "!XFLAG!" == "" (
	SET DEBUG=true
) ELSE (
	SET DEBUG=false
)

IF NOT "!ERRFLAG!" == "" GOTO usage

IF NOT "!EFLAG!" == "" (
	ECHO kconf 
	EXIT /B 0
)

IF NOT "!TFLAG!" == "" (
	IF NOT EXIST !KRB5_CONFIG_TEMPLATE! (
		ECHO !_C_ERR!!PROG!!_C_OFF!: cannot open !KRB5_CONFIG_TEMPLATE!>&2
		EXIT /B 1
	)
	ECHO !_C_MSG!!PROG!!_C_OFF!: saving !KRB5_CONFIG_TEMPLATE! as !ETC!\krb5.conf
	IF NOT EXIST !ETC! (
		MKDIR !ETC! >NUL 2>&1
		IF %ERRORLEVEL% NEQ 0 (
			ECHO !_C_ERR!!PROG!!_C_OFF!: cannot create !ETC!>&2
			EXIT /B 1
		)
	) 
	COPY /Y !KRB5_CONFIG_TEMPLATE! !ETC!\krb5.conf
)

IF NOT EXIST !SQLDEV_HOME!\sqldeveloper\bin\kerberos.conf (
	ECHO. >> !SQLDEV_HOME!\sqldeveloper\bin\sqldeveloper-nondebug.conf
	ECHO !_C_MSG!!PROG!!_C_OFF!: including kerberos.conf in nondebug
	ECHO IncludeConfFile kerberos.conf>> !SQLDEV_HOME!\sqldeveloper\bin\sqldeveloper-nondebug.conf
)

REM Create startup script - use JAAS

ECHO|SET /p="!_C_MSG!!PROG!!_C_OFF!: creating startup scripts: "

ECHO|SET /p="krb_sqldeveloper.cmd "
ECHO @ECHO OFF> !SQLDEV_HOME!\krb_sqldeveloper.cmd
REM ECHO %~dp0krb_kinit -k ^> !SQLDEV_HOME!\krb_sqldeveloper.log 2^>^&1 ^&^& !SQLDEV_HOME!\sqldeveloper.exe>> !SQLDEV_HOME!\krb_sqldeveloper.cmd
ECHO !SQLDEV_HOME!\sqldeveloper.exe ^> !SQLDEV_HOME!\krb_sqldeveloper.log 2^>^&1 >> !SQLDEV_HOME!\krb_sqldeveloper.cmd

ECHO|SET /p="krb_sqlcl.cmd "
ECHO @ECHO OFF> !SQLDEV_HOME!\krb_sqlcl.cmd
REM ECHO %~dp0krb_kinit -k ^> !SQLDEV_HOME!\krb_sqlcl.log 2^>^&1 ^&^& CALL %~dp0krb_sql.cmd -K -p>> !SQLDEV_HOME!\krb_sqlcl.cmd
ECHO CALL %~dp0krb_sql.cmd -K -C -j -p>> !SQLDEV_HOME!\krb_sqlcl.cmd

ECHO.

REM If we have Git for Windows installed we can create the shortcut
REM Usage: create-shortcut [options] <source> <destination>
REM --work-dir ('Start in' field)
REM --arguments (tacked onto the end of the 'Target')
REM --show-cmd (I presume this is the 'Run' droplist, values 'Normal window', 'Minimised', 'Maximised')
REM --icon-file (allows specifying the path to an icon file for the shortcut)
REM --description ('Comment' field)
REM 
IF EXIST "C:\Program Files\Git\mingw64\bin\create-shortcut.exe" (
	ECHO|SET /p="!_C_MSG!!PROG!!_C_OFF!: creating Desktop shortcuts: "

	ECHO|SET /p="!SHORTCUT! "
	create-shortcut.exe --work-dir "!SQLDEV_HOME!" --icon-file "!SQLDEV_HOME!\sqldeveloper.exe" --description "Kerberos kinit for SQL Developer created by krb_conf" "!SQLDEV_HOME!\krb_sqldeveloper.cmd" "%USERPROFILE%\Desktop\!SHORTCUT!.lnk"

	ECHO|SET /p="!SHORTCUTSQL! "
	create-shortcut.exe --work-dir "!SQLDEV_HOME!" --icon-file "!SQLDEV_HOME!\sqldeveloper\bin\sql.exe" --description "Kerberos kinit for SQLcl created by krb_conf" "!SQLDEV_HOME!\krb_sqlcl.cmd" "%USERPROFILE%\Desktop\!SHORTCUTSQL!.lnk"

	ECHO.
)

SET KERBEROS_CACHE=!KRB5CCNAME:FILE:=!
SET KERBEROS_CONFIG=!KRB5_CONFIG!

IF NOT "!EEFLAG!" == "" (
	CALL :escape KERBEROS_CACHE
	CALL :escape KERBEROS_CONFIG
) ELSE (
	CALL :canon KERBEROS_CACHE
	CALL :canon KERBEROS_CONFIG
)

REM Relative path
ECHO !_C_MSG!!PROG!!_C_OFF!: writing properties to kerberos.conf
ECHO AddVMOption -Dsun.security.krb5.debug=true> !SQLDEV_HOME!\sqldeveloper\bin\kerberos.conf
REM Moot. SQL Developer looks for this anyway:
REM ECHO AddVMOption -Djava.security.krb5.conf=../../jdk/jre/conf/security/krb5.conf>> !SQLDEV_HOME!\sqldeveloper\bin\kerberos.conf
ECHO AddVMOption -Djava.security.krb5.conf=!KRB5_CONFIG!>> !SQLDEV_HOME!\sqldeveloper\bin\kerberos.conf
REM SQL Developer uses JAAS
REM ECHO AddVMOption -Djava.security.krb5.realm=!REALM!>> !SQLDEV_HOME!\sqldeveloper\bin\kerberos.conf
REM ECHO AddVMOption -Djava.security.krb5.kdc=!KDC!>> !SQLDEV_HOME!\sqldeveloper\bin\kerberos.conf
REM ECHO AddVMOption -Djava.security.auth.login.config=%HOMEPATH%/.java.login.config>> !SQLDEV_HOME!\sqldeveloper\bin\kerberos.conf
REM  https://openjdk.org/jeps/486 - warnings for use of security manager become errors
SET JAAS_CONFIG=%USERPROFILE%\.java.login.config
ECHO # Default location for JAAS login configuration file is taken from:>> !SQLDEV_HOME!\sqldeveloper\bin\kerberos.conf
ECHO #  !JAVA_HOME!/conf/security/java.security>> !SQLDEV_HOME!\sqldeveloper\bin\kerberos.conf
ECHO # and is:>> !SQLDEV_HOME!\sqldeveloper\bin\kerberos.conf
ECHO #  #login.config.url.1=file:${user.home}/.java.login.config>> !SQLDEV_HOME!\sqldeveloper\bin\kerberos.conf
ECHO # so we do not need to specify:>> !SQLDEV_HOME!\sqldeveloper\bin\kerberos.conf
ECHO # AddVMOption -Djava.security.auth.login.config=!JAAS_CONFIG!>> !SQLDEV_HOME!\sqldeveloper\bin\kerberos.conf
ECHO # However, we need to specify the module NAME in the config file that we create:>> !SQLDEV_HOME!\sqldeveloper\bin\kerberos.conf
ECHO AddVMOption -Doracle.net.KerberosJaasLoginModule=!NAME!>> !SQLDEV_HOME!\sqldeveloper\bin\kerberos.conf
IF !MAJOR! GTR 21 (
	ECHO !_C_MSG!!PROG!!_C_OFF!: disallowing security.manager in kerberos.conf version !MAJOR!
	ECHO AddVMOption -Djava.security.manager=disallow>> !SQLDEV_HOME!\sqldeveloper\bin\kerberos.conf
)

IF NOT "!PFLAG!" == "" (
	IF NOT EXIST "C:\Program Files\Git\usr\bin\sed.exe" (
		ECHO !_C_ERR!!PROG!!_C_OFF!: install Git for Windows to use -p option>&2
		EXIT /B 1
	)

	SET PREFS_FILE=%APPDATA%\SQL Developer\system!VER_FULL!\o.sqldeveloper\product-preferences.xml
	IF NOT EXIST "!PREFS_FILE!" (
		ECHO !_C_ERR!!PROG!!_C_OFF!: cannot open !PREFS_FILE!>&2
		EXIT /B 1
	)
	REM if not there add:
	REM       <value n="KERBEROS_CACHE" v="C:/Users/demo/AppData/Local/krb5cc_demo"/>
	REM       <value n="KERBEROS_CONFIG" v="C:/Oracle/jdk-25.0.1/conf/security/krb5.conf"/>
	ECHO !_C_MSG!!PROG!!_C_OFF!: updating preferences: !PREFS_FILE!
	ECHO  KERBEROS_CACHE = !KERBEROS_CACHE! | sed "s;\\\\\{1,\\};\\\;g"
	ECHO  KERBEROS_CONFIG = !KERBEROS_CONFIG! | sed "s;\\\\\{1,\\};\\\;g"

	sed --in-place=.bak '/KERBEROS_CACHE/ {s@v=".*"@v="'!KERBEROS_CACHE!'"@; } ; /KERBEROS_CONFIG/ {s@v=".*"@v="'!KERBEROS_CONFIG!'"@; }' "!PREFS_FILE!"
)

IF NOT "!WFLAG!" == "" (
	IF NOT EXIST "C:\Program Files\Git\usr\bin\sed.exe" (
		ECHO !_C_ERR!!PROG!!_C_OFF!: install Git for Windows to use -w option>&2
		EXIT /B 1
	)
	CALL :escape JAVA_HOME
	ECHO !_C_MSG!!PROG!!_C_OFF!: setting SetJavaHome in !CONF!
	sed --in-place=.bak '/^^#* *SetJavaHome / {s@.*@SetJavaHome '!JAVA_HOME!'@; }' "!CONF!"
)
IF NOT "!UFLAG!" == "" (
	IF NOT EXIST "C:\Program Files\Git\usr\bin\sed.exe" (
		ECHO !_C_ERR!!PROG!!_C_OFF!: install Git for Windows to use -u option>&2
		EXIT /B 1
	)
	ECHO !_C_MSG!!PROG!!_C_OFF!: unsetting SetJavaHome in !CONF!
	sed --in-place=.bak '/[^^#]* *SetJavaHome / { s@^^ *@# ^&@; }' "!CONF!"
)
ECHO !_C_MSG!!PROG!!_C_OFF!: creating JAAS login configuration !JAAS_CONFIG!
CALL :jaasconfig

IF EXIST !ETC!\krb5.conf (
	ECHO !_C_MSG!!PROG!!_C_OFF!: template krb5.conf copied to !KRB5_CONFIG!
	COPY /V !ETC!\krb5.conf !KRB5_CONFIG!
) ELSE (
	ECHO !_C_MSG!!PROG!!_C_OFF!: new krb5.conf created at !KRB5_CONFIG!
	CALL :createkrb5conf
)

ENDLOCAL
EXIT /B 0

:usage
	ECHO !_C_ERR!Usage!_C_OFF!: krb_conf !_C_OFF![!_C_ARG!-h !_C_OPT!sqldev_home!_C_OFF! [!_C_ARG!-H!_C_OFF!]] [!_C_ARG!-c !_C_OPT!krb5ccname!_C_OFF!!_C_OFF!] [!_C_ARG!-J !_C_OPT!java_home!_C_OFF! !_C_OFF![!_C_ARG!-w!_C_OFF!]]^|!_C_ARG!-u!_C_OFF!] [!_C_ARG!-p!_C_OFF!] [!_C_ARG!-r!_C_OFF!] [!_C_ARG!-E!_C_OFF!]!_C_OFF! [!_C_ARG!-t !_C_OPT!file!_C_OFF!!_C_OFF!] [!_C_ARG!-V!_C_OFF!]!_C_OFF!>&2
	ECHO   !_C_ARG!-h!_C_OFF! !_C_OPT!sqldev_home!_C_OFF!   Specify SQL Developer home to override !_C_ENV!SQLDEV_HOME!_C_OFF! (default: !_SQLDEV_HOME_SOURCE!!SQLDEV_HOME!!_C_OFF!^)>&2
	ECHO   !_C_ARG!-H!_C_OFF!               Set !_C_OPT!sqldev_home!_C_OFF! environment variable in the !_C_REG!registry!_C_OFF!, first>&2
	ECHO                     attempt HKEY_LOCAL_MACHINE and fallback to HKEY_CURRENT_USER>&2
	ECHO   !_C_ARG!-c!_C_OFF! !_C_OPT!krb5ccname!_C_OFF!    Specify !_C_ENV!KRB5CCNAME!_C_OFF! (default: !_KRB5CCNAME_SOURCE!!KRB5CCNAME!!_C_OFF!^)>&2
	ECHO   !_C_ARG!-p!_C_OFF!               Update KERBEROS_CACHE and KERBEROS_CONFIG in product-preferences>&2
	ECHO   !_C_ARG!-r!_C_OFF!               Resolve krb5.conf parameters>&2
	ECHO   !_C_ARG!-v!_C_OFF!               Print SQL Developer version and exit>&2
	ECHO   !_C_ARG!-E!_C_OFF!               Escape rather than canonicalize paths for preferences files>&2
	IF NOT "!JAVA_HOME!" == "" (
		ECHO   !_C_ARG!-J!_C_OFF! !_C_OPT!java_home!_C_OFF!     Specify !_C_ENV!JAVA_HOME!_C_OFF! (default: !_JAVA_HOME_SOURCE!!JAVA_HOME!!_C_OFF!^) if unset>&2
	) ELSE (
		ECHO   !_C_ARG!-J!_C_OFF! !_C_OPT!java_home!_C_OFF!     Specify !_C_ENV!JAVA_HOME!_C_OFF! (default: !_JAVA_HOME_SOURCE!!SQLDEV_HOME!\jdk\jre!_C_OFF!^) if unset>&2
	)
	ECHO                     use SetJavaHome from !_C_CFG!product.conf!_C_OFF! or SQL Developer built-in JDK>&2
	ECHO   !_C_ARG!-w!_C_OFF!               Write value of !_C_OPT!java_home!_C_OFF! to !_C_CFG!product.conf!_C_OFF!>&2
	ECHO   !_C_ARG!-u!_C_OFF!               Unset !_C_OPT!java_home!_C_OFF! in !_C_CFG!product.conf!_C_OFF!>&2
	ECHO   !_C_ARG!-t!_C_OFF! !_C_OPT!file!_C_OFF!          Install and use !_C_OPT!file!_C_OFF! as a template krb5.conf>&2
	ECHO   !_C_ARG!-V!_C_OFF!               Print Java version and exit
ENDLOCAL
EXIT /B 1

REM createkrb5conf: generate krb5.con
:createkrb5conf
	REM create a krb5.conf for SQL Developer
	ECHO # Generated by krb_conf> !KRB5_CONFIG!
	ECHO [domain_realm]>> !KRB5_CONFIG!
	ECHO         .!DOMAIN! = !REALM!>> !KRB5_CONFIG!
	ECHO         !DOMAIN! = !REALM!>> !KRB5_CONFIG!
	ECHO.>> !KRB5_CONFIG!
	ECHO [libdefaults]>> !KRB5_CONFIG!
	ECHO         default_realm = !REALM!>> !KRB5_CONFIG!
	ECHO         default_ccache_name = !KRB5CCNAME!>> !KRB5_CONFIG!
	ECHO         default_client_keytab_name = !KRB5_KTNAME!>> !KRB5_CONFIG!
	ECHO #        verify_ap_req_nofail = false>> !KRB5_CONFIG!
	ECHO #        dns_lookup_kdc = false>> !KRB5_CONFIG!
	ECHO.>> !KRB5_CONFIG!
	ECHO [realms]>> !KRB5_CONFIG!
	ECHO         !REALM! = {>> !KRB5_CONFIG!
	CALL :kdc KDCS

	FOR /F "tokens=1" %%i IN ("!KDCS!") DO (
		ECHO             admin_server = %%i>> !KRB5_CONFIG!
       	)
	FOR /F "delims= tokens=*" %%i IN ("!KDCS!") DO ( 
		FOR %%j IN (%%i) DO (
			ECHO             kdc = %%j>> !KRB5_CONFIG!
		)
	)
	ECHO             kpasswd_protocol = SET_CHANGE>> !KRB5_CONFIG!
	ECHO             # pkinit_anchors = DIR:/etc/certs/CA>> !KRB5_CONFIG!
	ECHO             pkinit_eku_checking = kpServerAuth>> !KRB5_CONFIG!
	FOR /F "tokens=1" %%i IN ("!KDCS!") DO (
		ECHO             pkinit_kdc_hostname = %%i>> !KRB5_CONFIG!
	)
	ECHO         }>> !KRB5_CONFIG!
EXIT /B

REM toUpper: set str to uppercase
:toUpper str
	FOR %%a IN ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I"
		"j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R"
		"s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z") DO (
		CALL SET %~1=%%%~1:%%~a%%
	)
EXIT /B 0

REM toLower: set str to lowercase
:toLower str
	FOR %%a IN ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i"
		"J=j" "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r"
		"S=s" "T=t" "U=u" "V=v" "W=w" "X=x" "Y=y" "Z=z") DO (
		CALL SET %~1=%%%~1:%%~a%%
	)
EXIT /B 0

@ECHO off

REM canon: canonicalize path URLs for Java
:canon str
	FOR %%a IN ("\=/") DO (
		CALL SET %~1=%%%~1:%%~a%%
	)
EXIT /B 0

REM escape: escape windows paths 
:escape str
	FOR %%a IN ("\=\\\\") DO (
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

REM createsqlnetora: for OCI clients, not used at present
:createsqlnetora
	REM okinit needs sqlnet.ora for configuration settings....

	ECHO # Generated by pkinit.cmd - Do NOT edit> !SQLNET_ORA!
	ECHO SQLNET.KERBEROS5_CONF_MIT = TRUE>> !SQLNET_ORA!
	ECHO SQLNET.KERBEROS5_CC_NAME = !KRB5CCNAME!>> !SQLNET_ORA!
	ECHO SQLNET.KERBEROS5_CONF = !KRB5_CONFIG!>> !SQLNET_ORA!
	ECHO SQLNET.KERBEROS5_CLOCKSKEW = 1200>> !SQLNET_ORA!
	ECHO.>> !SQLNET_ORA!
	ECHO SQLNET.AUTHENTICATION_SERVICES = (KERBEROS5)>> !SQLNET_ORA!
	ECHO SQLNET.AUTHENTICATION_KERBEROS5_SERVICE = oracle>> !SQLNET_ORA!
	ECHO # Do not fallback to password authentication if Kerberos fails>> !SQLNET_ORA!
	ECHO SQLNET.FALLBACK_AUTHENTICATION = FALSE>> !SQLNET_ORA!
	ECHO # SQLNET.AUTHENTICATION_REQUIRED = TRUE>> !SQLNET_ORA!
	ECHO.>> !SQLNET_ORA!
	ECHO SQLNET.ENCRYPTION_TYPES_CLIENT = (AES256, AES192)>> !SQLNET_ORA!
	ECHO NAMES.DIRECTORY_PATH = (TNSNAMES)>> !SQLNET_ORA!
	ECHO.>> !SQLNET_ORA!
	ECHO DISABLE_OOB = ON>> !SQLNET_ORA!
	ECHO DISABLE_OOB_AUTO = TRUE>> !SQLNET_ORA!
	ECHO.>> !SQLNET_ORA!
	ECHO DIAG_ADR_ENABLED = OFF>> !SQLNET_ORA!
	ECHO ADR_BASE = C:\temp>> !SQLNET_ORA!
	ECHO TRACE_LEVEL_CLIENT = OFF>> !SQLNET_ORA!
	ECHO TRACE_DIRECTORY_CLIENT = !TNS_ADMIN!>> !SQLNET_ORA!
EXIT /B

REM javaversion: print Java version
:javaversion java_home vers
	FOR /f "tokens=3" %%i IN ('%1\bin\java -version 2^>^&1^|findstr version') DO (CALL set %~2=%%~i%%)
EXIT /B 0

REM versionpart: extract nth part of version number n.n.n - n default 1
:versionpart version var n
	IF "%3" == "" (
		SET _part=1
	) ELSE (
		SET _part=%3
	)
	FOR /F "tokens=%_part% delims=." %%i IN ("%1") DO (CALL set %~2=%%~i%%)
EXIT /B 0

REM jaasconfig: create JAAS Config using keytab and cache
REM When multiple mechanisms to retrieve a ticket or key are provided, the preference order is:
REM    1. ticket cache
REM    2. keytab
REM    3. shared state
REM    4. user prompt
REM MB JAAS defaults for cache and keytab differ from MIT
:jaasconfig
	SET _KRB5_KTNAME=!KRB5_KTNAME:FILE:=!
	IF NOT "!RFLAG!" == "" (
		CALL :krb5exp _KRB5_KTNAME
	) ELSE (
		CALL :krb5exp _KRB5_KTNAME JAAS 
	)
	CALL :canon _KRB5_KTNAME
	ECHO !NAME! { > !JAAS_CONFIG!
  	ECHO   com.sun.security.auth.module.Krb5LoginModule required>> !JAAS_CONFIG!
  	ECHO   refreshKrb5Config=true>> !JAAS_CONFIG!
  	ECHO   doNotPrompt=true>> !JAAS_CONFIG!
  	ECHO   useTicketCache=true>> !JAAS_CONFIG!
  	REM There are many combinations of KRB5CCNAME or -krb5ccname and ticketCache
	IF NOT "!KRB5CCNAME!" == "" (
		REM If not specified default is {user.home}{file.separator}krb5cc_{user.name}
		SET _KRB5CCNAME=!KRB5CCNAME:FILE:=!
		IF NOT "!RFLAG!" == "" (
			CALL :krb5exp _KRB5CCNAME 
		) ELSE (
			CALL :krb5exp _KRB5CCNAME JAAS
		)
		CALL :canon _KRB5CCNAME
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

REM getuserprincipal: set user to userPrincipalName (from AD or keytab)
:getuserprincipal user
	powershell -NoLogo -NoProfile -NonInteractive -OutputFormat Text -Command Get-AdUser %USERNAME%> NUL 2>&1
	IF %ERRORLEVEL% EQU 0 (
		REM get from AD
		FOR /f "tokens=1" %%i IN ('powershell -NoLogo -NoProfile -NonInteractive -OutputFormat Text -Command ^(Get-AdUser %USERNAME% ^^^| Select-Object UserPrincipalName^).UserPrincipalName') DO (CALL set %~1=%%i%%)
	) ELSE (
		REM get from keytab
		REM since this batch file has set KRB5_KTNAME we may have to expand the variables
		SET _KTAB=!KRB5_KTNAME!
		CALL :krb5exp _KTAB
		FOR /F "usebackq tokens=4" %%i IN (`%BIN%\krb_klist -k !_KTAB! ^| find "[1] Service principal:"`) DO (CALL set %~1=%%i%%)
	)
EXIT /B 0

REM formatprincipal: format principal to standard Kerberos capitalization return value in var
:formatprincipal principal
	CALL SET _principal=%%%~1%%%
	FOR /f "delims=@" %%i IN ("%_principal%") DO (set _primary=%%i)
	FOR /f "tokens=2 delims=@" %%i IN ("%_principal%") DO (set _realm=%%i)
	CALL :toupper _realm
	CALL SET %~1=%%_primary%%@%%_realm%%
EXIT /B 0

REM kdc: get list of KDCs
:kdc str
	SET _file=%TEMP%\kdc%RANDOM%.out
	CMD /V:ON /C "FOR /F %%i IN ('nslookup -type^=srv _kerberos._tcp.%USERDNSDOMAIN% ^| findstr internet') DO @(ECHO %%i)" | SORT /UNIQUE /O %_file%
	set _a=
	FOR /F "tokens=1" %%i IN (%_file%) DO (call SET _a=%%i %%_a%%)
	CALL SET %~1=%%_a%%
	DEL %_file%
EXIT /B 0

REM krb5exp: kerberos parameter expansion of <str>
REM  %{TEMP}            Temporary directory                       
REM  %{uid}             Unix real UID or Windows SID              
REM  %{username}        (Unix) Username of effective user ID      
REM  %{APPDATA}         (Windows) Roaming application data for current user                              
REM  %{COMMON_APPDATA}  (Windows) Application data for all users  
REM  %{LOCAL_APPDATA}   (Windows) Local application data for current user                              
REM  If <jaasflag> is Y:
REM  Replace %{username} with:
REM  {user.name}        Java property - JAAS ${user.name} in properties files
REM  Replace %HOMEDRIVE%%HOMEPATH% or %USERPROFILE% with:
REM  {user.home}        Java property - JAAS ${user.home} in properties files
REM 
:krb5exp str jaasflag
	CALL SET _str=%%%~1%%%

	SET _up=%USERPROFILE%
	CALL :canon _up

	IF "%~2" == "JAAS" (
		SET _str=!_str:%%{username}=${user.name}!
	)

	SET _str=!_str:%%{username}=%USERNAME%!
	SET _str=!_str:%%{LOCAL_APPDATA}=%LOCALAPPDATA%!
	SET _str=!_str:%%{APPDATA}=%APPDATA%!

	IF "%~2" == "JAAS" (
		SET _str=!_str:%%HOMEDRIVE%%%%HOMEPATH%%=${user.home}!
		SET _str=!_str:%%USERPROFILE%%=${user.home}!
		SET _str=!_str:%USERPROFILE%=${user.home}!
		SET _str=!_str:%_up%=${user.home}!
	)

	CALL SET %~1=%%_str%%
EXIT /B 0
