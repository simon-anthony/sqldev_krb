@ECHO off
REM krb_pkinit: Get TGT from certificate
REM vim: fileformat=dos:

SETLOCAL enabledelayedexpansion

REM realm in upper case
SET REALM=%USERDNSDOMAIN%
CALL :toUpper REALM
REM domain in lower case
SET DOMAIN=%USERDNSDOMAIN%
CALL :toLower DOMAIN

SET SHORTCUT=sqldeveloper

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
) ELSE IF "%option%" == "-h" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET SQLDEV_HOME=%arg%
		SHIFT
	) ELSE (
		GOTO usage
	)
	SET HFLAG=y
) ELSE IF "%option%" == "-J" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET JAVA_HOME=%arg%
		SHIFT
	) ELSE (
		GOTO usage
	)
	SET JJFLAG=y
) ELSE IF "%option%" == "-e" (
	SHIFT
	SET EFLAG=y
) ELSE IF "%option%" == "-p" (
	SHIFT
	SET PFLAG=y
) ELSE IF "%option%" == "-v" (
	SHIFT
	SET VFLAG=y
) ELSE IF "%option%" == "-r" (
	SHIFT
	SET RFLAG=y
) ELSE IF "%option%" == "-E" (
	SHIFT
	SET EEFLAG=y
) ELSE (
	GOTO usage
)

GOTO parse
:endparse

IF "%SQLDEV_HOME%" == "" (
	ECHO SQLDEV_HOME must be set in the environment or set with -h
	EXIT /B 1
)
IF NOT EXIST !SQLDEV_HOME!\sqldeveloper.exe (
	ECHO Invalid SQL Developer home
	EXIT /B 1
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
	SET KRB5_CONFIG=%JAVA_HOME%\conf\security\krb5.conf
) ELSE (
	SET KRB5_CONFIG=!SQLDEV_HOME!\jdk\jre\conf\security\krb5.conf
)

IF NOT "!VFLAG!" == "" (
	ECHO !VER_FULL!
	EXIT /B 0
)
IF "%CFLAG%" == "" (
	REM This is the default cache unless overridden by specifying KRB5CCNAME
	REM JDK kinit uses %HOMEPATH%\krb5cc_%USERNAME%
	REM SET KRB5CCNAME=%LOCALAPPDATA%\krb5cc_%USERNAME%
	IF NOT "%PFLAG%" == "" (
		SET KRB5CCNAME=FILE:!LOCALAPPDATA!\krb5cc_!USERNAME!
		SET KRB5_KTNAME=FILE:!LOCALAPPDATA!\krb5_!USERNAME!.keytab
	) ELSE IF "!RFLAG!" == "" (
		SET KRB5CCNAME=FILE:%%{LOCAL_APPDATA}\krb5cc_%%{username}
		SET KRB5_KTNAME=FILE:%%{LOCAL_APPDATA}\krb5_%%{username}.keytab
	) ELSE (
		SET KRB5CCNAME=FILE:!LOCALAPPDATA!\krb5cc_!USERNAME!
		SET KRB5_KTNAME=FILE:!LOCALAPPDATA!\krb5_!USERNAME!.keytab
	)
)
IF NOT "!EFLAG!" == "" (
	ECHO kconf 
	EXIT /B 0
)

SET BIN=%~dp0
SET ETC=%bin:\bin=%etc

IF EXIST !ETC!\krb5.conf (
	ECHO Template krb5.conf copied to !KRB5_CONFIG!
	COPY /V !ETC!\krb5.conf !KRB5_CONFIG!
) ELSE (
	ECHO New krb5.conf created at !KRB5_CONFIG!
	CALL :createkrb5conf
)

IF NOT EXIST !SQLDEV_HOME!\sqldeveloper\bin\kerberos.conf (
	ECHO. >> !SQLDEV_HOME!\sqldeveloper\bin\sqldeveloper-nondebug.conf
	ECHO IncludeConfFile kerberos.conf>> !SQLDEV_HOME!\sqldeveloper\bin\sqldeveloper-nondebug.conf
)


REM Create startup script

ECHO %~dp0krb_kinit -k ^> !SQLDEV_HOME!\krb_sqldeveloper.log 2^>^&1 ^&^& !SQLDEV_HOME!\sqldeveloper.exe >!SQLDEV_HOME!\krb_sqldeveloper.cmd
REM If we have Git for Windows installed we can create the shortcut
REM Usage: create-shortcut [options] <source> <destination>
REM --work-dir ('Start in' field)
REM --arguments (tacked onto the end of the 'Target')
REM --show-cmd (I presume this is the 'Run' droplist, values 'Normal window', 'Minimised', 'Maximised')
REM --icon-file (allows specifying the path to an icon file for the shortcut)
REM --description ('Comment' field)
REM 
IF EXIST "C:\Program Files\Git\mingw64\bin\create-shortcut.exe" (
	ECHO Creating Desktop shortcut: !SHORTCUT!
	create-shortcut.exe --work-dir "!SQLDEV_HOME!" --icon-file "!SQLDEV_HOME!\sqldeveloper.exe" --description "Kerberos kinit for SQL Developer created by krb_conf" "!SQLDEV_HOME!\krb_sqldeveloper.cmd" "%USERPROFILE%\Desktop\!SHORTCUT!.lnk"
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
ECHO AddVMOption -Dsun.security.krb5.debug=true> !SQLDEV_HOME!\sqldeveloper\bin\kerberos.conf
REM Moot. SQL Developer looks for this anyway:
ECHO AddVMOption -Djava.security.krb5.conf=../../jdk/jre/conf/security/krb5.conf>> !SQLDEV_HOME!\sqldeveloper\bin\kerberos.conf
REM Usually these work - but SQL Developer loads too late in startup to have an effect:
REM ECHO AddVMOption -Djava.security.krb5.realm=!REALM!>> !SQLDEV_HOME!\sqldeveloper\bin\kerberos.conf
REM ECHO AddVMOption -Djava.security.krb5.kdc=!KDC!>> !SQLDEV_HOME!\sqldeveloper\bin\kerberos.conf
REM ECHO AddVMOption -Djava.security.auth.login.config=%HOMEPATH%/.java.login.config>> !SQLDEV_HOME!\sqldeveloper\bin\kerberos.conf

IF NOT "!PFLAG!" == "" (
	IF NOT EXIST "C:\Program Files\Git\usr\bin\sed.exe" (
		ECHO Install Git for Windows to use this option
		exit /B 1
	)

	SET PREFS_FILE=%APPDATA%\SQL Developer\system!VER_FULL!\o.sqldeveloper\product-preferences.xml
	IF NOT EXIST "!PREFS_FILE!" (
		ECHO cannot open !PREFS_FILE!
		EXIT /B 1
	)
	ECHO Updating preferences: !PREFS_FILE!
	ECHO  KERBEROS_CACHE = !KERBEROS_CACHE! | sed "s;\\\\\{1,\\};\\\;g"
	ECHO  KERBEROS_CONFIG = !KERBEROS_CONFIG! | sed "s;\\\\\{1,\\};\\\;g"

	sed --in-place=.bak '/KERBEROS_CACHE/ {s@v=".*"@v="'!KERBEROS_CACHE!'"@; } ; /KERBEROS_CONFIG/ {s@v=".*"@v="'!KERBEROS_CONFIG!'"@; }' "!PREFS_FILE!"
)

ENDLOCAL
EXIT /B 0

:usage
	IF EXIST !SQLDEV_HOME!\sqldeveloper.exe (
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
	)
	ECHO Usage: krb_conf [-h ^<sqldev_home^>] [-c ^<krb5ccname^>] [-J ^<java_home^>] [-p] [-r] [-E]
	ECHO   -h ^<sqldev_home^> specify SQL Developer home (default: !SQLDEV_HOME!^)
	ECHO   -c ^<krb5ccname^>  specify KRB5CCNAME (default: !KRB5CCNAME!^)
	ECHO   -p               update KERBEROS_CACHE and KERBEROS_CONFIG in product.preferences 
	ECHO   -r               resolve krb5.conf parameters
	ECHO   -v               print SQL Developer version and exit
	ECHO   -E               escape rather than canonicalize paths for preferences files
	ECHO   -J ^<java_home^>   specify JAVA_HOME (default: !JAVA_HOME!^) if unset use 
	ECHO                    SetJavaHome from product.conf or SQL Developer built-in JDK
ENDLOCAL
EXIT /B 1

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
	ECHO             admin_server = win-bts6cdsef76.example.com>> !KRB5_CONFIG!
	ECHO             kdc = win-bts6cdsef76.example.com>> !KRB5_CONFIG!
	ECHO             kpasswd_protocol = SET_CHANGE>> !KRB5_CONFIG!
	ECHO             # pkinit_anchors = DIR:/etc/certs/CA>> !KRB5_CONFIG!
	ECHO             pkinit_eku_checking = kpServerAuth>> !KRB5_CONFIG!
	ECHO             pkinit_kdc_hostname = win-bts6cdsef76.example.com>> !KRB5_CONFIG!
	ECHO         }>> !KRB5_CONFIG!
EXIT /B

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

@ECHO off

REM canonicalize path URLs for Java
:canon str
	FOR %%a IN ("\=/") DO (
		CALL SET %~1=%%%~1:%%~a%%
	)
EXIT /B 0

REM escape windows paths 
:escape str
	FOR %%a IN ("\=\\\\") DO (
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
