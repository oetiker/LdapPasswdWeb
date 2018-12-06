SMBPasswdWeb
=============
Version: #VERSION#
Date: #DATE#

SMBPasswdWeb is a little web application letting users change their
password in a Samba environment.  The app relies solely on perl modules todo its work. No external utilities are
required, and all missing, non-core perl modules will be built and installed alongside the app as required.

![screenshot](https://cloud.githubusercontent.com/assets/429279/9728323/55e6fee4-5607-11e5-8e39-2b83e303cff8.png)

Setup
-----

Download the latest release from https://github.com/moetiker/SMBPasswdWeb/releases/latest

```
./configure --prefix=/opt/smb_passwd_web
 make
```
 
Configure will check if the necessary items are in place and give
hints on how to fix the situation if something is missing.

Configuration
-------------

SmbPasswdWeb expects its configuration to be present in Environment
variables:

* `SMBPASSWD_SMB_HOST` - the samba host. eg. `hostname.mycompany.xxx`

Installation
------------

To install the application, just run

```
make install
```

You can now run SMBPasswdWeb.pl in reverse proxy mode.

```
./smb_passwd_web.pl prefork --listen=http://127.0.0.1:9688
```

On an systemd you could easily run this standalone by creating
`/etc/systemd/system/smbpasswdweb.service`:

```
[Unit]
Description=SMB Password Change Web Application

[Service]
Type=simple
User=smbpasswdweb
Group=smbpasswdweb
Restart=always
Environment=SMBPASSWD_SMB_HOST=hostname.domain.com
ExecStart=/opt/smb_passwd_web/bin/smb_passwd_web.pl prefork --listen http://127.0.0.1:6879
ExecStop=/usr/bin/pkill -f 'smb_passwd_web.+6879
Restart=always
[Install]
WantedBy=multi-user.target
```

Packaging
---------

If you want to release your own version of this tool make sure to update
CHANGES, VERSION and run ./bootstrap

You can also package the application as a nice tar.gz file, it will contain
a mini copy of cpan, so that all perl modules can be rebuilt at the
destination.  If you want to make sure that your project builds with perl
5.22.1, make sure to set PERL to a perl 5.22.1 interpreter, remove your
thirdparty directory and configure again.  Now all modules to make your
project fly with an old perl will be included in the distribution.

   make dist

Enjoy!

Manuel Oetiker <manuel@oetiker.ch>
