@ECHO off
REM krb_ktab: Create keytab
REM vim: fileformat=dos:
REM https://docs.oracle.com/en/java/javase/22/docs/specs/man/ktab.html
REM https://bugs.openjdk.org/browse/JDK-8279064
REM https://bugs.openjdk.org/browse/JDK-8279632
REM https://web.mit.edu/kerberos/krb5-1.5/krb5-1.5.4/doc/krb5-admin/Salts.html#Salts

SETLOCAL enabledelayedexpansion

SET PROG=krb_ktab

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

SET REALM=%USERDNSDOMAIN%
SET PRINCIPAL=%USERNAME%@%REALM%

IF "%KRB5_KTNAME%" == "" (
	SET _KRB5_KTNAME_SOURCE=!_C_INT!
) ELSE (
	SET _KRB5_KTNAME_SOURCE=!_C_ENV!
)

IF "%JAVA_HOME%" == "" (
	SET _JAVA_HOME_SOURCE=!_C_INT!
) ELSE (
	SET _JAVA_HOME_SOURCE=!_C_ENV!
)

SET KTABOPTS=

IF "%KRB5_CONFIG%" == "" (
	REM %PROGRAMDATA%\Kerberos\krb5.conf is system default for MIT Kerberos5
	REM %APPDATA%\krb5.conf is a fallback for MIT Kerberos5
	SET KRB5_CONFIG=%APPDATA%\krb5.conf
)
IF "%KRB5_KTNAME%" == "" (
	REM JDK does not recognise KRB5_KTNAME
	SET KRB5_KTNAME=%LOCALAPPDATA%\krb5_%USERNAME%.keytab
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

SET ERRFLAG=

:parse
IF "%1" == "" GOTO endparse

SET option=%~1
SET arg=%~2

IF "%option%" == "-k" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET KRB5_KTNAME=%arg%
		SET _KRB5_KTNAME_SOURCE=!_C_OPT!
		SHIFT
	) ELSE (
		SET ERRFLAG=Y
	)
	SET KFLAG=y
) ELSE IF "%option%" == "-K" (
	SHIFT
	SET KRB5_KTNAME=
	SET KKFLAG=y
) ELSE IF "%option%" == "-A" (
	SHIFT
	SET AAFLAG=y
) ELSE IF "%option%" == "-e" (
	SHIFT
	SET EFLAG=y
) ELSE IF "%option%" == "-x" (
	SHIFT
	SET XFLAG=y
) ELSE IF "%option%" == "-p" (
	SHIFT
	SET PFLAG=y
) ELSE IF "%option%" == "-v" (
	SHIFT
	SET VFLAG=y
) ELSE IF "%option%" == "-V" (
	SHIFT
	SET VVFLAG=y
) ELSE IF "%option%" == "-s" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET SALT=%arg%
		SHIFT
	) ELSE (
		SET ERRFLAG=Y
	)
	IF NOT "!FFLAG!" == "" GOTO usage
	SET KTABOPTS=!KTABOPTS! -s !SALT!
	SET SFLAG=y
) ELSE IF "%option%" == "-f" (
	SHIFT
	IF NOT "!SFLAG!" == "" GOTO usage
	SET KTABOPTS=!KTABOPTS! -f
	SET FFLAG=y
) ELSE IF "%option%" == "-D" (
	SHIFT
	SET JAVA_TOOL_OPTIONS="-Dsun.security.krb5.debug=true"
	SET DDFLAG=y
) ELSE IF "%option%" == "-J" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET JAVA_HOME=%arg%
		SET _JAVA_HOME_SOURCE=!_C_OPT!
		SHIFT
	) ELSE (
		SET ERRFLAG=Y
	)
	SET JJFLAG=y
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

REM Was a principal supplied?
SET p=%~1
FOR /f "delims=@" %%i IN ("%p%") DO (set _PRIMARY=%%i)
FOR /f "tokens=2 delims=@" %%i IN ("%p%") DO (set _REALM=%%i)

IF NOT "!_PRIMARY!" == "" (
	SET PRIMARY=!_PRIMARY!
	IF NOT "!_REALM!" == "" (
		REM realm must be uppercase
		CALL :toUpper _REALM
		SET REALM=!_REALM!
	)
	SET PRINCIPAL=!PRIMARY!@!REALM!
)
IF "!PRIMARY!" == "" (
	FOR /f "delims=@" %%i IN ("%PRINCIPAL%") DO (set PRIMARY=%%i)
)
REM Default salt should be:
REM SET SALT=!REALM!!PRIMARY!

IF NOT "!KFLAG!" == "" (
	IF NOT "!KKFLAG!" == "" (
		GOTO usage
	)
)
IF NOT "!AAFLAG!" == "" (
	SET KTABOPTS=!KTABOPTS! -append
)

IF NOT "!KRB5_KTNAME!" == "" (
	SET KTABOPTS=!KTABOPTS! -k !KRB5_KTNAME!
)

IF NOT "!XFLAG!" == "" (
	SET KRB5_TRACE=%TEMP%\krb5_trace.log
	ECHO. > !KRB5_TRACE!
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
	)
	SET KRB5_BIN=%JAVA_HOME%\bin
) ELSE (
	SET KRB5_BIN=!SQLDEV_HOME!\jdk\jre\bin
)
SET PATH=!KRB5_BIN!;%PATH%

IF NOT "!JAVA_HOME!" == "" (
	CALL :javaversion !JAVA_HOME! VERSION
) ELSE (
	CALL :javaversion !SQLDEV_HOME!\jdk\jre VERSION
)
IF NOT "!VVFLAG!" == "" (
	ECHO !VERSION!
	EXIT /B 0
)

IF NOT "!SFLAG!" == "" (
	CALL :versionpart !VERSION! MAJOR
	IF NOT !MAJOR! GEQ 19 (
		ECHO !_C_ERR!!PROG!!_C_OFF!: Java release 19 or above required for -s>&2
		EXIT /B 1
	)
)
IF NOT "!FFLAG!" == "" (
	CALL :versionpart !VERSION! MAJOR
	IF NOT !MAJOR! GEQ 19 (
		ECHO !_C_ERR!!PROG!!_C_OFF!: Java release 19 or above required for -f>&2
		EXIT /B 1
	)
)
IF NOT "!EFLAG!" == "" (
	ECHO ktab !KTABOPTS! -a !PRINCIPAL! PASSWORD
	EXIT /B 0
)

IF NOT "!ERRFLAG!" == "" GOTO usage

IF NOT "!PFLAG!" == "" (
	REM verify the password
	SET /p PASSWORD="Password for !PRINCIPAL!:"
	SET KRB5CCNAME=%TEMP%\krb5cc_%RANDOM%

	REM ERRORLEVEL is always 0 for kinit, so check success of ccache reation ...
	kinit -c !KRB5CCNAME! !PRINCIPAL! !PASSWORD! > !KRB5CCNAME!.log 2>&1
	IF EXIST !KRB5CCNAME! (
		DEL !KRB5CCNAME!
	) ELSE (
		IF NOT "!VFLAG!" == "" (
			TYPE !KRB5CCNAME!.log
		) ELSE (
			ECHO !_C_ERR!!PROG!!_C_OFF!: Bad password
		)
		EXIT /B 1
	)
)

ktab !KTABOPTS! -a !PRINCIPAL! !PASSWORD!

ENDLOCAL
EXIT /B 0

:usage
	ECHO !_C_ERR!Usage!_C_OFF!: !_C_BLD!krb_ktab!_C_OFF! [!_C_ARG!-e!_C_OFF!] [!_C_ARG!-V!_C_OFF!] [!_C_ARG!-x!_C_OFF!] [!_C_ARG!-A!_C_OFF!] [!_C_ARG!-s !_C_OPT!salt!_C_OFF!^|!_C_ARG!-f!_C_OFF!] [!_C_ARG!-K!_C_OFF!^|!_C_OFF!!_C_ARG!-k !_C_OPT!krb5_ktname!_C_OFF!] [!_C_ARG!-J !_C_OPT!java_home!_C_OFF!] [!_C_ARG!-p!_C_OFF!] [!_C_ARG!-x!_C_OFF!] [!_C_OPT!principal_name!_C_OFF!]
	ECHO   !_C_ARG!-k!_C_OFF! !_C_OPT!krb5_ktname!_C_OFF!   Specify keytab !_C_ENV!KRB5_KTNAME!_C_OFF! (default: !_KRB5_KTNAME_SOURCE!!KRB5_KTNAME!!_C_OFF!^)
	ECHO   !_C_ARG!-K!_C_OFF!               Unset any default value of !_C_ENV!KRB5_KTNAME!_C_OFF!
	ECHO   !_C_ARG!-A!_C_OFF!               New keys are appended to keytab
	ECHO   !_C_ARG!-e!_C_OFF!               Echo the command only
	ECHO   !_C_ARG!-p!_C_OFF!               Verify password before creating keytab
	ECHO   !_C_ARG!-v!_C_OFF!               Verbose messages
	ECHO   !_C_ARG!-D!_C_OFF!               Turn on krb5.debug
	ECHO   !_C_ARG!-x!_C_OFF!               Produce trace (in %TEMP%\krb5_trace.log)
	ECHO   !_C_ARG!-s!_C_OFF! !_C_OPT!salt!_C_OFF!          Specify the salt to use e.g. if sAMAccountName does not match userPrincipalName
	ECHO   !_C_ARG!-f!_C_OFF!               Request salt from KDC
	ECHO   !_C_ARG!-V!_C_OFF!               Print Java version and exit
	IF NOT "!JAVA_HOME!" == "" (
		ECHO   !_C_ARG!-J!_C_OFF! !_C_OPT!java_home!_C_OFF!     Specify !_C_ENV!JAVA_HOME!_C_OFF! (default: !_JAVA_HOME_SOURCE!!JAVA_HOME!!_C_OFF!^) if unset>&2
	) ELSE (
		ECHO   !_C_ARG!-J!_C_OFF! !_C_OPT!java_home!_C_OFF!     Specify !_C_ENV!JAVA_HOME!_C_OFF! (default: !_JAVA_HOME_SOURCE!!SQLDEV_HOME!\jdk\jre!_C_OFF!^) if unset>&2
	)
	ECHO                     use SetJavaHome from !_C_CFG!product.conf!_C_OFF! or SQL Developer built-in JDK>&2

	ECHO   Options !_C_ARG!-s!_C_OFF! and !_C_ARG!-f!_C_OFF! only supported with Java ^>=19
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

REM javaversion: print Java version
:javaversion java_home vers
	FOR /f "tokens=3" %%i IN ('%1\bin\java -version 2^>^&1^|findstr version') DO (CALL set %~2=%%~i%%)
EXIT /B 0

REM getprop: retrieve a setting from a .properties file
:getprop str file
        FOR /F "tokens=1,2 delims=^=" %%i IN (%2) DO (IF %%i == %1 CALL SET %~1=%%j%%)

EXIT /B 0

REM getconf: retrieve a setting from a .conf file
:getconf str file
	FOR /F "tokens=1,2" %%i IN (%2) DO (IF %%i == %1 CALL SET %~1=%%j%%)
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
