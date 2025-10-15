# SQL Developer Kerberos Utiltities

These tools are for the special cases on Windows where it is not possible to use the LSA as a ticket cache for authentication.

> **_NOTE:_**  These tools specifically discuss using Kerberos within JDBC or JAAS (the *thin client*) and not Kerebros with OCI (or the *thick client*) from the Oracle Client or Instantclient.

The tools offer the possibility of simplified passwordless login to via Kerberos to databases and other services.

There are various defaults for cache location and type, configuration file location, sequences for authentication attempts and so on in-built to Windows Kerberos, MIT, Heimdal and the mechanisms within SQL Developer. This package aims to produce consistent behaviour when using an amalgam of these implemntations such that authentication is simplified and consistent.

## Overview

In general, there are two mechanisms possible to achieve this when the user has not been automatically authenticated to the realm upon login, for example, via PAM/sshd on UNIX/Linux systems or vi login to a Windows domain.

### PKINIT

This mechanism uses a *certifcate* and its private key to preauthenticate the session and obtain tickets for the ticket cache. This is the technique used also by smartcards. They private key may or may not have password or other protection.

### Keytab

In this scenario the user authenticates to the realm (domain) and creates a *keytab*. This keytab can subsequentally be used to obtain tickets for a ticket cache without being challenged for a password. The keytab file should, needless to say, be stored for each user where others are not able to access it.


### SQL Developer

These tools primarily make use of the JDK supplied with SQL Developer to afford login via the main GUI and its standalone SQL editor **SQLcl**.

The Kerberos utilities provided by the JDK are minimalist in nature and have idiosyncratic behaviour. So, these programs make allowances for this to ensure a reliable process to authenticateL ikewise the Java authentication conventions for Kerberos do not all apply to SQL Developer and so other methods must be used.


#### JDK

At the root of the SQL Developer installation, subsequently referred to as `SQLDEV_HOME` the shipped JDK is found:

<pre class=console><code>SQLDEV_HOME\jdk\
jre\     
 ├─bin\ 
 │  ├─<b>kinit</b>.exe 
 │  ├─<b>klist</b>.exe 
 │  └─<b>ktab</b>.exe 
 │
 ├─conf\ 
 │  ├─...
 │  ├─security 
 │  │  ├─<b>java.security</b>
 │  │  └─krb5.conf
 │  └─... 
 │
 ├─lib\ 
 └─...
</code></pre>

The three Kerberos utilities provided **kinit**, **klist** and **ktab** are to be found. These do have divergent operation from the MIT or Heimdal counterparts.

##### java.security

In addition the `java.security` file is to be found here. In this we might configure a default login configuration file for JAAS should we choose to use this mechanism.

The default (commented) is set as:
```shell output
#login.config.url.1=file:${user.home}/.java.login.config
```

##### krb5.conf

Although no default `krb5.conf` is distributed, this is the default location where SQL Developer will search should you choose to create one here.


## Creating a Credentials Cache

We shall consider the two mechanisms: PKINIT and the use of a keytab. Of the two, PKINIT is the more complex as we shall need an external implementation of **kinit** with PKINIT support compiled in. Neither **kinit** from the SQL Developer JDK nor **okinit** supplied with the Oracle client have this feature.

As the simplet proposition, the use of a keytab is therefore discussed first.

### Method 1 - Keytab

The first step in creating a passwordles login is to create a keytab. This
file should be placed in a safe location where no other users are able to read
it.

<pre class=console><code>> <b>krb_keytab -p</b>
Password for demo@EXAMPLE.COM:<b>*********</b>
Done!
Service key for demo@EXAMPLE.COM is saved in C:\Users\demo\AppData\Local\krb5_demo.keytab
</code></pre>

> **_NOTE:_**  It is stronly recommended to use the **-p** option to validate the password otherwise a keytab will be generated using an incorrect password - such a keytab can still be used but will fail any attempts to use it for authentication (with **kinit** or JAAS).

A prompt will be made for the password (whether specifying **-p** or not) and the subsequent typing will not be masked: so be careful that no-one else is watching the screen.

The *default* location for the keytab is `%LOCALAPPDATA%\krb5_%USERNAME%.keytab`.

Having created a keytab we can view its contents, using the **-k** option to **ktab_klist** to display the default keytab:

<pre class=console><code>> <b>krb_klist -k</b>

Key tab: C:\Users\demo\AppData\Local\krb5_demo.keytab, 4 entries found.

[1] Service principal: demo@EXAMPLE.COM
         KVNO: 1
         Key type: 18
         Key: 0x12886815a6cf1501b6306d9e672f034ff7a742f9800a7a1086a2b7c991e9dc62
         Time stamp: Oct 14, 2025 12:47:57
[2] Service principal: demo@EXAMPLE.COM
         KVNO: 1
         Key type: 17
         Key: 0x42cf1f44356f976a9d2b5a62d7019796
         Time stamp: Oct 14, 2025 12:47:57
[3] Service principal: demo@EXAMPLE.COM
         KVNO: 1
         Key type: 20
         Key: 0x07eb0fc6ba22bed9b3b2553c4385f5c80c93b2efb3c4156aa891b9f34029759a
         Time stamp: Oct 14, 2025 12:47:57
[4] Service principal: demo@EXAMPLE.COM
         KVNO: 1
         Key type: 19
         Key: 0xe53fad914e58f3735c794df63507c52c
         Time stamp: Oct 14, 2025 12:47:57
</code></pre>

The next step is to request a ticket (to store in our credentials cache.) We can do this with **krb_kinit** by specifiying the **-k** option to tell it to use a keytab (either specified or the default one):

<pre class=console><code>> <b>krb_kinit -k</b>
New ticket is stored in cache file C:\Users\demo\AppData\Local\krb5cc_demo
</code></pre>

Note the default credentials cache is `%LOCALAPPDATA%\krb5cc_%USERNAME%`. 


### Method 2 - PKINIT

We do not need to create a keytab for the user for this procedure.
 
Having obtained the certificate `%USERNAME%.crt`, key `%USERNAME%.key` and root certificate `ca.crt` files and placed them in `%USERPROFILE%\Certs`, run the following:

<pre class=console><code>> <b>krb_pkinit</b>
New ticket is stored in cache file C:\Users\demo\AppData\Local\krb5cc_demo
</code></pre>

### Listing the Contents of the Credentials Cache

We can list the contents of the default credentials cache thus:

<pre class=console><code>> <b>krb_klist</b>

Credentials cache: C:\Users\demo\AppData\Local\krb5cc_demo

Default principal: demo@EXAMPLE.COM, 1 entry found.

[1]  Service Principal:  krbtgt/EXAMPLE.COM@EXAMPLE.COM
     Valid starting:     Oct 14, 2025 13:12:13
     Expires:            Oct 14, 2025 23:12:13
     EType (skey, tkt):  AES256 CTS mode with HMAC SHA1-96, AES256 CTS mode with HMAC SHA1-96
     Flags:              INITIAL;PRE-AUTHENT
</code></pre>


## Using SQLcl

### JDBC

This is the default mode. The following command simply ensures that the settings are appropriate for the intended Kerberos authntication we have configured.

<pre class=console><code>> <b>krb_sql -k C:\Oracle\sqldeveloper\jdk\jre\conf\security\krb5.conf -t C:\Oracle\network\admin OMS</b>


SQLcl: Release 24.3 Production on Wed Oct 15 14:06:11 2025

Copyright (c) 1982, 2025, Oracle.  All rights reserved.

Connected to:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.27.0.0.0

SQL> 
</code></pre>

### Java Authentication and Authorization Service (JAAS)

JAAS authentication is performed in a pluggable fashion, so Java applications can remain independent from underlying authentication technologies. Configuration information such as the desired authentication technology is specified at runtime. 

The [configuration file](https://docs.oracle.com/en/java/javase/17/security/appendix-b-jaas-login-configuration-file.html#GUID-7EB80FA5-3C16-4016-AED6-0FC619F86F8E) consists of a number of entries defining the methods and options.

For example, suppose we have the following file `%HOMEPATH%\.java/login.config`:
```shell output
Oracle {
  com.sun.security.auth.module.Krb5LoginModule required
  refreshKrb5Config=true
  doNotPrompt=true
  useKeyTab=false
  useTicketCache=true
  storeKey=false
  renewTGT=false
  debug=true;
};
```
The following command shows login to SQLcl using JAAS (**-j**)

<pre class=console><code>> <b>krb_sql -j -x  -k C:\Oracle\sqldeveloper\jdk\jre\conf\security\krb5.conf -t C:\Oracle\network\admin OMS</b>

Picked up JAVA_TOOL_OPTIONS: -Djava.security.auth.login.config=C:\Users\demo\.java.login.config -Doracle.net.KerberosJaasLoginModule=Oracle


SQLcl: Release 24.3 Production on Wed Oct 15 13:47:27 2025

Copyright (c) 1982, 2025, Oracle.  All rights reserved.

Debug is  true storeKey false useTicketCache true useKeyTab false doNotPrompt true ticketCache is null isInitiator true KeyTab is null refreshKrb5Config is true principal is null tryFirstPass is false useFirstPass is false storePass is false clearPass is false
Refreshing Kerberos configuration
Acquire TGT from Cache
Principal is demo@EXAMPLE.COM
Commit Succeeded

Connected to:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.27.0.0.0

SQL>
</code></pre>

If the JAAS configuration file does not exist a basic template will be created. The **-x** option will generate the JAAS configuration with `Debug=true` as can be seen in the output from the command startup.

Note that appropriate Java properties have been set in the `JAVA_TOOL_OPTIONS` environment variable.

### Echo Mode

A useful way to check what wil be run is to use the *echo* mode to print the command and any factors affecting execution:


<pre class=console><code>> <b>krb_sql -e -j -x -k C:\Oracle\sqldeveloper\jdk\jre\conf\security\krb5.conf -t C:\Oracle\network\admin OMS</b>
KRB5_CONFIG=C:\Oracle\sqldeveloper\jdk\jre\conf\security\krb5.conf
KRB5CCNAME=C:\Users\demo\AppData\Local\krb5cc_demo
TNS_ADMIN=C:\Oracle\network\admin
JAVA_TOOL_OPTIONS: -Djava.security.auth.login.config=C:\Users\demo\.java.login.config -Doracle.net.KerberosJaasLoginModule=Oracle
sql -kerberos -thin -noupdates -tnsadmin C:\Oracle\network\admin -krb5_config C:\Oracle\sqldeveloper\jdk\jre\conf\security\krb5.conf -krb5ccname C:\Users\demo\AppData\Local\krb5cc_demo /@OMS
</code></pre>

Another example - this shows that without overriding the location of the kerberos configuration file setting from the command line (**-k**) the system configuration file has been picked up from the environment variable `KRB5_CONFIG`. This may not give us the login required.

<pre class=console><code>> <b>krb_sql -e -j -x -t C:\Oracle\network\admin OMS</b>
KRB5_CONFIG=C:\ProgramData\Kerberos\krb5.conf
KRB5CCNAME=C:\Users\demo\AppData\Local\krb5cc_demo
TNS_ADMIN=C:\Oracle\network\admin
JAVA_TOOL_OPTIONS: -Djava.security.auth.login.config=C:\Users\demo\.java.login.config -Doracle.net.KerberosJaasLoginModule=Oracle
sql -kerberos -thin -noupdates -tnsadmin C:\Oracle\network\admin -krb5_config C:\ProgramData\Kerberos\krb5.conf -krb5ccname C:\Users\demo\AppData\Local\krb5cc_demo /@OMS
</code></pre>

### Defaults

In common with the other programs in this package, type the [help](#krb_sql) option (-?) to see the defaults.

## Program Synopses

### krb\_ktab 
```shell output
Usage: krb_ktab [-e] [-x] [-a] [-K|-k <krb5_ktname>] [-p] [-x] [<principal_name>]
  -k <krb5_ktname> specify keytab KRB5_KTNAME (default: C:\Users\demo\AppData\Local\krb5cc_demo.keytab)
  -K               unset any default value KRB5_KTNAME
  -a               new keys are appended to keytab
  -e               echo the command only
  -p               verify password before creating keytab
  -v               verbose messages
  -x               produce trace (in C:\Users\demo\AppData\Local\Temp\1\krb5_trace.log)
```

### krb\_kinit 
```shell output
Usage: krb_kinit [-e] [-x] [-C|-c <krb5ccname>] [-K|-k [-t <krb5_ktname>]] [<principal_name>]
  -c <krb5ccname>  specify KRB5CCNAME (default: C:\Users\demo\AppData\Local\krb5cc_demo )
  -C               unset any default value KRB5CCNAME
  -k               use default keytab KRB5_KTNAME (default: C:\Users\demo\AppData\Local\krb5cc_demo.keytab)
  -t <krb5_ktname> specify keytab with <krb5_ktname>
  -K               unset any default value KRB5_KTNAME
  -e               echo the command only
  -x               produce trace (in C:\Users\demo\AppData\Local\Temp\1\krb5_trace.log)
  -M               use MIT Kerberos
```

### krb\_klist 
```shell output
Usage: krb_klist [-M] [-c|-k] [<name>]
  -c               specifies credential cache KRB5CCNAME (default: C:\Users\demo\AppData\Local\krb5cc_demo )
  -k               specifies keytab KRB5_KTNAME (default: C:\Users\demo\AppData\Local\krb5cc_demo.keytab)
  -e               echo the command only
  -x               produce trace (in C:\Users\demo\AppData\Local\Temp\1\krb5_trace.log)
  -M               use MIT Kerberos
```

### krb\_kdestroy 
```shell output
Usage: krb_kdestroy [-c] [-k]
  -c               specifies credential cache KRB5CCNAME (default: C:\Users\demo\AppData\Local\krb5cc_demo)
                   this is the default action if neither -c nor -k are specified
  -k               specifies keytab KRB5_KTNAME (default: C:\Users\demo\AppData\Local\krb5cc_demo.keytab)
  -e               echo the command only
```

### krb\_sql 
```shell output
Usage: krb_sql [-e] [-K|-k <krb5_config>] [-t <tns_admin>] [-i] [-j[-J]] [-x] <tns_alias>
  -k <krb5_config> specify KRB5_CONFIG (default: C:\Users\demo\AppData\Roaming\krb5.conf)
  -K               unset any default value of KRB5_CONFIG i.e. use DNS SRV lookup
  -t <tns_admin>   specify TNS_ADMIN (default: C:\Oracle\client_home\network\admin)
  -c <krb5ccname>  specify KRB5CCNAME (default: C:\Users\demo\AppData\Local\krb5cc_demo)
  -C               unset any default value of KRB5CCNAME
  -e               echo the command only
  -i               install a template startup.sql
  -j               use JAAS
  -J               overwrite C:\Users\demo\.java.login.config
  -x               produce trace (in C:\Users\demo\AppData\Local\Temp\1\krb5_trace.log)
Usage: krb_sql -a [-t <tns_admin>]
  -a               print aliases
  -t <tns_admin>   specify TNS_ADMIN (default: C:\Oracle\client_home\network\admin)
```

### krb\_pkinit
```shell output
Usage: krb_pkinit [-e] [-x] [-C|-c <krb5ccname>] [-d <dir>] [-D <dir>] [-A <dir>]
  -c <krb5ccname>    specify KRB5CCNAME (default: C:\Users\demo\AppData\Local\krb5cc_demo)
  -C                 unset any default value of KRB5CCNAME
  -d                 directory <dir> in which to find certificate (demo.crt)
  -D                 directory <dir> in which to find key (demo.key)
  -A                 directory <dir> in which to find anchor certificate (ca.crt)
  -e                 echo the command only
  -x                 produce trace (in C:\Users\demo\AppData\Local\Temp\1\krb5_trace.log)
 default <dir> is C:\Users\demo\Certs
```

## Notes on MIT Kerberos

The tools follow the conventions used by MIT's Kerberos for Windows.

The Kerberos 5 configuration file and credentials cache can be
controlled with environment variables and registry settings.

The environment variable for a particular setting always takes
precedence.

Next in precedence comes the setting in the registry under

    HKEY_CURRENT_USER\Software\MIT\Kerberos5

Then comes the registry setting under 

    HKEY_LOCAL_MACHINE\Software\MIT\Kerberos5

If none of those are found, a default value is used.

  Configuration File:
  - Environment: KRB5_CONFIG
  - Registry Value: config
  - Default: looks in the user's AppData directory, the machine's ProgramData
    directory, krb5_32.dll's dir and Windows directory

  Default Credentials Cache:
  - Environment: KRB5CCNAME
  - Registry Value: ccname
  - Default: API:

