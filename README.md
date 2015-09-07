LdapPasswdWeb
=============
Version: #VERSION#
Date: #DATE#

LdapPasswdWeb is a little webapplication letting users change their password
in an ldap managed environment.

Setup
-----

```
./configure --prefix=/opt/ldap_passwd_web
 make
```
 
Configure will check if the necessary items are in place and give
hints on how to fix the situation if something is missing.

Configuration
-------------

LdapPasswdWeb expects its configuration to be present in Environment
variables:

* `LDAPPASSWD_LDAP_HOST` - the ldap host. eg. `ds1.mycompany.xxx`

* `LDAPPASSWD_LDAP_BASEDN` - the base DN of your user accounts. eg
  `dc=mycompany,dc=xxx`. User accounts are expected to reside unter
  `uid=$user,ou=users,$basedn`

* `LDAPPASSWD_ENABLE_SAMBA` set to 1 enables the changing the samba password of the
  user. To make this work, the users need permission to write their own
  sambaNTPassword, sambaLMPassword and sambaPwdLastSet properties.

Installation
------------

To install the application, just run

```
make install
```

You can now run LdapPasswdWeb.pl in reverse proxy mode.

```
./ldap_passwd_web.pl prefork
```

On an upstart system you could easily run this standalone:

```
start on stopped rc RUNLEVEL=[2345]

stop on runlevel [!2345]

env LDAPPASSWD_LDAP_HOST=ds1.mycompany.xxx
env LDAPPASSWD_LDAP_BASEDN=dc=mycompany,dc=xxx
env LDAPPASSWD_ENABLE_SAMBA=1

respawn
exec /opt/ldappasswdweb/bin/ldap_passwd_web.pl prefork -l 'https://*:443'
```

Packaging
---------

If you want to release your own version of this tool make sure to update
CHANGES, VERSION and run ./bootstrap

You can also package the application as a nice tar.gz file, it will contain
a mini copy of cpan, so that all perl modules can be rebuilt at the
destination.  If you want to make sure that your project builds with perl
5.10.1, make sure to set PERL to a perl 5.10.1 interpreter, remove your
thirdparty directory and configure again.  Now all modules to make your
project fly with an old perl will be included in the distribution.

   make dist

Enjoy!

Tobias Oetiker <tobi@oetiker.ch>
