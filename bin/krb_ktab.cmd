@ECHO off
REM krb_ktab: Create keytab
REM vim: fileformat=dos:

SETLOCAL enabledelayedexpansion

SET REALM=%USERDNSDOMAIN%
SET PRINCIPAL=%USERNAME%@%REALM%

IF "%SQLDEV_HOME%" == "" (
	SET SQLDEV_HOME=C:\Oracle\sqldeveloper
)
IF NOT EXIST !SQLDEV_HOME!\sqldeveloper.exe (
	ECHO Invalid SQL Developer home
	EXIT /B 1
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

:parse
IF "%1" == "" GOTO endparse

SET option=%~1
SET arg=%~2

IF "%option%" == "-k" (
	SHIFT 
	IF NOT "%arg:~0,1%" == "-" (
		SET KRB5_KTNAME=%arg%
		SHIFT
	) ELSE (
		GOTO usage
	)
	SET KFLAG=y
) ELSE IF "%option%" == "-K" (
	SHIFT
	SET KRB5_KTNAME=
	SET KKFLAG=y
) ELSE IF "%option%" == "-a" (
	SHIFT
	SET AFLAG=y
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
	SET PRINCIPAL=!PRIMARY!@!REALM!
)

IF NOT "!KFLAG!" == "" (
	IF NOT "!KKFLAG!" == "" (
		GOTO usage
	)
)
IF NOT "!AFLAG!" == "" (
	SET KTABOPTS=!KTABOPTS! -append
)

IF NOT "!KRB5_KTNAME!" == "" (
	SET KTABOPTS=!KTABOPTS! -k !KRB5_KTNAME!
)

IF NOT "!EFLAG!" == "" (
	ECHO ktab !KTABOPTS! -a !PRINCIPAL! PASSWORD
	EXIT /B 0
)
IF NOT "!XFLAG!" == "" (
	SET KRB5_TRACE=%TEMP%\krb5_trace.log
	ECHO. > !KRB5_TRACE!
)

SET KRB5_BIN=!SQLDEV_HOME!\jdk\jre\bin
SET PATH=!KRB5_BIN!;%PATH%

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
			ECHO Bad password
		)
		EXIT /B 1
	)
)

ktab !KTABOPTS! -a !PRINCIPAL! !PASSWORD!

ENDLOCAL
EXIT /B 0

:usage
	ECHO Usage: krb_ktab [-e] [-x] [-a] [-K^|-k ^<krb5_ktname^>] [-p] [-x] [^<principal_name^>]
	ECHO   -k ^<krb5_ktname^> specify keytab KRB5_KTNAME (default: !KRB5_KTNAME!^)
	ECHO   -K               unset any default value of KRB5_KTNAME
	ECHO   -a               new keys are appended to keytab
	ECHO   -e               echo the command only
	ECHO   -p               verify password before creating keytab
	ECHO   -v               verbose messages
	ECHO   -x               produce trace (in %TEMP%\krb5_trace.log)
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
