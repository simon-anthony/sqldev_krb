@ECHO off
REM krb_kinit: Create TGT from my keytab
REM vim: fileformat=dos:

SETLOCAL enabledelayedexpansion

SET REALM=%USERDNSDOMAIN%
SET PRINCIPAL=

IF "%SQLDEV_HOME%" == "" (
	SET SQLDEV_HOME=C:\Oracle\sqldeveloper
)

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
)
IF "%KRB5_KTNAME%" == "" (
	REM JDK does not recognise KRB5_KTNAME
	SET KRB5_KTNAME=%LOCALAPPDATA%\krb5_%USERNAME%.keytab
)

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
	SET KINITOPTS=!KINITOPTS! -C
	SET MMFLAG=y
) ELSE IF NOT "%option:~0,1%" == "-" (
	SET arg=%option%
	REM SHIFT
	GOTO endparse
) ELSE (
	GOTO usage
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
	echo here
	SET PRINCIPAL=!PRIMARY!@!REALM!
)
IF NOT "!CFLAG!" == "" (
	IF NOT "!CCFLAG!" == "" (
		GOTO usage
	)
)
IF NOT "!TFLAG!" == "" (
	IF NOT "!KFLAG!" == "" (
		SET KINITOPTS=!KINITOPTS! -t !KRB5_KTNAME!
	) ELSE (
		GOTO usage
	)
)

IF NOT "!KFLAG!" == "" (
	IF NOT "!KKFLAG!" == "" (
		GOTO usage
	)
	SET KINITOPTS=!KINITOPTS! -k
)
IF "!MMFLAG!" == "" (
	IF NOT EXIST !SQLDEV_HOME!\sqldeveloper.exe (
		ECHO Invalid SQL Developer home
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
	IF NOT "!KFLAG!" == "" (
		SET KINITOPTS=!KINITOPTS! -t !KRB5_KTNAME!
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

SET PATH=!KRB5_BIN!;%PATH%

kinit !KINITOPTS! !PRINCIPAL!

ENDLOCAL
EXIT /B 0

:usage
	ECHO Usage: krb_kinit [-e] [-D] [-x] [-C^|-c ^<krb5ccname^>] [-K^|-k [-t ^<krb5_ktname^>]] [^<principal_name^>]
	ECHO   -c ^<krb5ccname^>  specify KRB5CCNAME (default: !KRB5CCNAME!^)
	ECHO   -C               unset any default value of KRB5CCNAME
	ECHO   -k               use default keytab KRB5_KTNAME (default: !KRB5_KTNAME!^)
	ECHO   -t ^<krb5_ktname^> specify keytab with ^<krb5_ktname^>
	ECHO   -K               unset any default value KRB5_KTNAME
	ECHO   -e               echo the command only
	ECHO   -x               produce trace (in %TEMP%\krb5_trace.log)
	ECHO   -D               turn on krb5.debug
	ECHO   -M               use MIT Kerberos
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
