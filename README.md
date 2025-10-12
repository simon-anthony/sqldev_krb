# SQL Developer Kerberos Utiltities
These tools are for the special cases where it is not possible to use the LSA.

## Program Synopses

### krb5\_ktab 
```
Usage: krb_ktab [-e] [-x] [-a] [-K|-k <krb5_ktname>] [-p] [-x] [<principal_name>
  -k <krb5_ktname> specify keytab KRB5_KTNAME (default: C:\Users\demo\AppData\Local\krb5cc_demo.keytab)
  -K               unset any default value KRB5_KTNAME
  -a               new keys are appended to keytab
  -e               echo the command only
  -p               verify password before creating keytab
  -v               verbose messages
  -x               produce trace (in C:\Users\demo\AppData\Local\Temp\1\krb5_trace.log)
```

### krb\_kinit 
```
Usage: krb_kinit [-e] [-x] [-C|-c <krb5ccname>] [-K|-k [-t <krb5_ktname>]]
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
```
Usage: krb_klist [-M] [-c|-k] [<name>]
  -c               specifies credential cache KRB5CCNAME (default: C:\Users\demo\AppData\Local\krb5cc_demo )
  -k               specifies keytab KRB5_KTNAME (default: C:\Users\demo\AppData\Local\krb5cc_demo.keytab)
  -e               echo the command only
  -x               produce trace (in C:\Users\demo\AppData\Local\Temp\1\krb5_trace.log)
  -M               use MIT Kerberos
```

### krb\_kdestroy 
```
Usage: krb_kdestroy [-c] [-k]
  -c               specifies credential cache KRB5CCNAME (default: C:\Users\demo\AppData\Local\krb5cc_demo)
                   this is the default action if neither -c nor -k are specified
  -k               specifies keytab KRB5_KTNAME (default: C:\Users\demo\AppData\Local\krb5cc_demo.keytab)
  -e               echo the command only
```

### krb\_ksql 
```
Usage: krb_sql [-e] [-K|-k <krb5_config>] [-T|-t <tns_admin>] <tns_alias>
  -k <krb5_config> specify KRB5_CONFIG (default: C:\Users\demo\AppData\Roaming\krb5.conf)
  -K               unset any default value KRB5_CONFIG
  -t <tns_admin>   specify TNS_ADMIN (default: C:\Oracle\network\admin)
  -T               unset any default value TNS_ADMIN
  -c <krb5ccname>  specify KRB5CCNAME (default: C:\Users\demo\AppData\Local\krb5cc_demo )
  -C               unset any default value KRB5CCNAME
  -e               echo the command only
  -i               install a template startup.sql
  -j               use JAAS
Usage: krb_sql -a
  -a               print aliases
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

