@ECHO off
REM krb_kinit: Create TGT from my keytab
REM vim: fileformat=dos:

SETLOCAL enabledelayedexpansion

SET PROG=krb_kinit

REM Note that %~dp0 will be C:\path\to\ and %~dpf0 will be C:\path\to\file.cmd
SET BIN=%~dp0
SET ETC=%BIN:\bin=%etc

CALL %BIN%\COLOURS.CMD

SET REALM=%USERDNSDOMAIN%
SET PRINCIPAL=

SET KINITOPTS=

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
IF "%KRB5_KTNAME%" == "" (
	REM JDK does not recognise KRB5_KTNAME
	SET KRB5_KTNAME=%LOCALAPPDATA%\krb5_%USERNAME%.keytab
	SET _KRB5_KTNAME_SOURCE=!_C_INT!
) ELSE (
	SET _KRB5_KTNAME_SOURCE=!_C_ENV!
)

IF "%JAVA_HOME%" == "" (
	SET _JAVA_HOME_SOURCE=!_C_INT!
) ELSE (
	SET _JAVA_HOME_SOURCE=!_C_ENV!
)

IF "%SQLDEV_HOME%" == "" (
	SET SQLDEV_HOME=!_C_ERR!SQLDEV_HOME!_C_OFF!
	IF "%~1" == "-?"  GOTO usage
	ECHO !_C_ERR!!PROG!!_C_OFF!: !_C_ENV!SQLDEV_HOME!_C_OFF! must be set in the environment>&2
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

IF "%option%" == "-c" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET KRB5CCNAME=%arg%
		SET _KRB5CCNAME_SOURCE=!_C_OPT!
		SHIFT
	) ELSE (
		SET ERRFLAG=Y
	)
	SET CFLAG=y
) ELSE IF "%option%" == "-C" (
	SHIFT
	SET KRB5CCNAME=
	SET CCFLAG=y
) ELSE IF "%option%" == "-k" (
	SHIFT 
	SET KFLAG=y
) ELSE IF "%option%" == "-t" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET KRB5_KTNAME=%arg%
		SET _KRB5_KTNAME_SOURCE=!_C_OPT!
		SHIFT
	)
	SET TFLAG=y
) ELSE IF "%option%" == "-K" (
	SHIFT
	SET KRB5_KTNAME=
	SET KKFLAG=y
) ELSE IF "%option%" == "-e" (
	SHIFT
	SET EFLAG=y
) ELSE IF "%option%" == "-x" (
	SHIFT
	SET XFLAG=y
) ELSE IF "%option%" == "-D" (
	SHIFT
	SET JAVA_TOOL_OPTIONS="-Dsun.security.krb5.debug=true"
	SET DDFLAG=y
) ELSE IF "%option%" == "-M" (
	SHIFT
	IF NOT "!JFLAG!" == "" SET ERRFLAG=Y
	SET KINITOPTS=!KINITOPTS! -C
	SET MMFLAG=y
) ELSE IF "%option%" == "-j" (
	SHIFT 
	IF NOT "!MMFLAG!" == "" SET ERRFLAG=Y
	IF NOT "%arg:~0,1%" == "-" (
		SET JAVA_HOME=%arg%
		SET _JAVA_HOME_SOURCE=!_C_OPT!
		SHIFT
	) ELSE (
		SET ERRFLAG=Y
	)
	SET JFLAG=y
) ELSE IF "%option%" == "-V" (
	SHIFT
	SET VVFLAG=y
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
IF NOT "!CFLAG!" == "" (
	IF NOT "!CCFLAG!" == "" (
		SET ERRFLAG=Y
	)
)
IF NOT "!TFLAG!" == "" (
	IF NOT "!KFLAG!" == "" (
		SET KINITOPTS=!KINITOPTS! -t !KRB5_KTNAME!
	) ELSE (
		SET ERRFLAG=Y
	)
)

IF NOT "!KFLAG!" == "" (
	IF NOT "!KKFLAG!" == "" (
		SET ERRFLAG=Y
	)
	SET KINITOPTS=!KINITOPTS! -k
)
IF "!MMFLAG!" == "" (
	IF NOT EXIST !SQLDEV_HOME!\sqldeveloper.exe (
		ECHO !_C_ERR!!PROG!!_C_OFF!: invalid SQL Developer home>&2
		EXIT /B 1
	)
	SET KRB5_BIN=!SQLDEV_HOME!\jdk\jre\bin
) ELSE (
	SET KRB5_BIN=C:\Program Files\MIT\Kerberos\bin
)

IF NOT "!KRB5CCNAME!" == "" (
	SET KINITOPTS=!KINITOPTS! -c !KRB5CCNAME!
)
IF NOT "!KRB5_KTNAME!" == "" (
	IF "!TFLAG!" == "" (
		IF NOT "!KFLAG!" == "" (
			SET KINITOPTS=!KINITOPTS! -t !KRB5_KTNAME!
		)
	)
)

IF NOT "!EFLAG!" == "" (
	ECHO kinit !KINITOPTS! !PRINCIPAL!
	EXIT /B 0
)

IF NOT "!XFLAG!" == "" (
	SET KRB5_TRACE=%TEMP%\krb5_trace.log
	ECHO. > !KRB5_TRACE!
)

IF NOT "!VVFLAG!" == "" (
	IF NOT "!JAVA_HOME!" == "" (
		CALL :javaversion !JAVA_HOME! VERSION
	) ELSE (
		CALL :javaversion !SQLDEV_HOME!\jdk\jre VERSION
	)
	ECHO !VERSION!
	EXIT /B 0
)

SET PROPS=!SQLDEV_HOME!\sqldeveloper\bin\version.properties
CALL :getprop VER_FULL !PROPS!
CALL :getprop VER !PROPS!
SET CONF=%APPDATA%\sqldeveloper\!VER!\product.conf
CALL :getconf SetJavaHome !CONF!

IF "!JFLAG!" == "" (
	IF NOT "!SetJavaHome!" == "" (
		REM Overrides all JAVA_HOME settings unless -j specified
		SET JAVA_HOME=!SetJavaHome!
	)
)

IF NOT "%JAVA_HOME%" == "" (
	IF NOT EXIST "%JAVA_HOME%\bin\java.exe" (
		ECHO !_C_ERR!!PROG!!_C_OFF!: invalid JAVA_HOME %JAVA_HOME%>&2
		IF "!ERRFLAG!" == "" EXIT /B 1
		SET ERRFLAG=Y
	)
	SET KRB5_BIN=%JAVA_HOME%\bin
) ELSE (
	SET KRB5_BIN=!SQLDEV_HOME!\jdk\jre\bin
)

IF NOT "!ERRFLAG!" == "" GOTO usage

SET PATH=!KRB5_BIN!;%PATH%

kinit !KINITOPTS! !PRINCIPAL!

ENDLOCAL
EXIT /B 0

:usage
	ECHO !_C_ERR!Usage!_C_OFF!: !_C_BLD!krb_kinit !_C_OFF![!_C_ARG!-e!_C_OFF!] [!_C_ARG!-D!_C_OFF!!_C_OFF!] [!_C_ARG!-V!_C_OFF!] [!_C_ARG!-M!_C_OFF!^|!_C_ARG!-j !_C_OPT!java_home!_C_OFF!] [!_C_ARG!-x!_C_OFF!] [!_C_ARG!-C!_C_OFF!^|!_C_ARG!-c !_C_OPT!krb5ccname!_C_OFF!] [!_C_ARG!-K!_C_OFF!^|!_C_ARG!-k !_C_OFF![!_C_ARG!-t !_C_OPT!krb5_ktname!_C_OFF!]] [!_C_OPT!principal_name!_C_OFF!]

	ECHO   !_C_ARG!-c!_C_OFF! !_C_OPT!krb5ccname!_C_OFF!    Specify !_C_ENV!KRB5CCNAME!_C_OFF! (default: !_KRB5CCNAME_SOURCE!!KRB5CCNAME!!_C_OFF!^)>&2
	ECHO   !_C_ARG!-C!_C_OFF!               Unset any default value of !_C_ENV!KRB5CCNAME!_C_OFF!>&2
	ECHO   !_C_ARG!-k!_C_OFF!               Use default keytab !_C_ENV!KRB5_KTNAME!_C_OFF! (default: !_KRB5_KTNAME_SOURCE!!KRB5_KTNAME!!_C_OFF!^)

	ECHO   !_C_ARG!-t!_C_OFF! !_C_OPT!krb5_ktname!_C_OFF!   Specify keytab with !_C_OPT!krb5_ktname!_C_OFF!

	ECHO   !_C_ARG!-K!_C_OFF!               Unset any default value of !_C_ENV!KRB5_KTNAME!_C_OFF!
	ECHO   !_C_ARG!-e!_C_OFF!               Echo the command only
	ECHO   !_C_ARG!-x!_C_OFF!               Produce trace (in %TEMP%\krb5_trace.log)
	ECHO   !_C_ARG!-D!_C_OFF!               Turn on krb5.debug
	ECHO   !_C_ARG!-M!_C_OFF!               Use MIT Kerberos
	IF NOT "!JAVA_HOME!" == "" (
		ECHO   !_C_ARG!-j!_C_OFF! !_C_OPT!java_home!_C_OFF!     Specify !_C_ENV!JAVA_HOME!_C_OFF! (default: !_JAVA_HOME_SOURCE!!JAVA_HOME!!_C_OFF!^) if unset>&2
	) ELSE (
		ECHO   !_C_ARG!-j!_C_OFF! !_C_OPT!java_home!_C_OFF!     Specify !_C_ENV!JAVA_HOME!_C_OFF! (default: !_JAVA_HOME_SOURCE!!SQLDEV_HOME!\jdk\jre!_C_OFF!^) if unset>&2
	)
	ECHO                     use SetJavaHome from !_C_CFG!product.conf!_C_OFF! or SQL Developer built-in JDK>&2
	ECHO   !_C_ARG!-V!_C_OFF!               Print Java version and exit
ENDLOCAL
EXIT /B 1

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

REM getprop: retrieve a setting from a .properties file
:getprop str file
        FOR /F "tokens=1,2 delims=^=" %%i IN (%2) DO (IF %%i == %1 CALL SET %~1=%%j%%)

EXIT /B 0

REM getconf: retrieve a setting from a .conf file
:getconf str file
	FOR /F "tokens=1,2" %%i IN (%2) DO (IF %%i == %1 CALL SET %~1=%%j%%)
EXIT /B 0

REM javaversion: print Java version
:javaversion java_home vers
	FOR /f "tokens=3" %%i IN ('%1\bin\java -version 2^>^&1^|findstr version') DO (CALL set %~2=%%~i%%)
EXIT /B 0
