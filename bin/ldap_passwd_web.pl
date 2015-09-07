#!/usr/bin/env perl

# PERL5LIB
use FindBin;use lib "$FindBin::Bin/../lib";use lib "$FindBin::Bin/../thirdparty/lib/perl5"; # LIBDIR

# having a non-C locale for number will wreck all sorts of havoc
# when things get converted to string and back
use POSIX qw(locale_h);
setlocale(LC_NUMERIC, "C");

use Mojolicious::Lite;
use Net::LDAP;
use Net::LDAP::Extension::SetPassword;
use Crypt::SmbHash  qw(ntlmgen);

die "LDAPPASSWD_LDAP_HOST environment variable is not defined\n"
    unless $ENV{LDAPPASSWD_LDAP_HOST};

die "LDAPPASSWD_LDAP_BASEDN environment variable is not defined\n"
        unless $ENV{LDAPPASSWD_LDAP_BASEDN};

# Make signed cookies secure
app->secrets(['dontneedsecurecookies in this app']);

my $errors = {
    size => sub {
        my ($value,$min,$max) = @_;
        return "Size is $value (must be between $min and $max)";
    },
    equal_to => sub {
        my ($value,$key) = @_;
        return "must be equal to '$key'";
    },
    required => sub {
        "entry is mandatory"
    }
};

helper(
    errtext => sub {
        my $c = shift;
        my $err = shift;
        my ($check, $result, @args) = @$err;
        return $errors->{$check}->($result,@args);
    }
);

# Main login action
any '/' => sub {
    my $c = shift;
    my $validation = $c->validation;
    return $c->render unless $validation->has_data;

    $validation->required('user')->size(1, 20);
    $validation->required('pass')->size(1, 80);
    $validation->required('newpass')->size(8, 50);
    $validation->required('newpass_again')->equal_to('newpass');

    return $c->render if $validation->has_error;

    my $user = $c->param('user');
    my $pass = $c->param('pass');
    my $newpass = $c->param('newpass');


    eval {
        my $ldap = Net::LDAP->new ( $ENV{LDAPPASSWD_LDAP_HOST}, onerror=>'die', version=>3 ) or die "$@";
        $ldap->start_tls( verify => 'none', sslversion=> 'tlsv1');
        my $dn = "uid=$user,ou=users,$ENV{LDAPPASSWD_LDAP_BASEDN}";
        $ldap->bind( $dn, password => $pass);
        if ($ENV{LDAPPASSWD_ENABLE_SAMBA}){
            my ($sambaLMPassword,$sambaNTPassword) = ntlmgen $newpass;
            $ldap->modify( $dn, replace => {
                    sambaNTPassword => $sambaNTPassword,
                    sambaLMPassword => $sambaLMPassword,
                    sambaPwdLastSet => time,
            });
        }
        $ldap->set_password(oldpassword=>$pass,newpasswd=>$newpass);
    };
    if (my $error = $@){
        $error =~ s/ at \S+ line.*//;
        $c->flash(message=>$error);
        return $c->render;
    }

    $c->render('thanks');

} => 'index';


app->start;
__DATA__

@@ layouts/default.html.ep
<!DOCTYPE html>
<html lang="en" >
  <head>
    <!-- Latest compiled and minified CSS -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">
  </head>
  <body>
  <title><%= title %></title>
</head>
<body>
<div class="container">
  <div class="row">
      <%= content %>
  </div>
</div>
</body>
</html>

@@ index.html.ep
% layout 'default';
% title 'LDAP Password Setter';

<div class="col-md-4 col-md-offset-4 col-sm-6 col-sm-offset-3">
<h1>Password Reset</h1>

<div>
% my @fields = qw(user pass newpass newpass_again);
% my %fields = ( user => 'Username', pass => 'Password', newpass => 'New Password', newpass_again => 'New Password Again');
% my $msg = flash('message');

%= form_for current => method=> 'post' => begin
  <fieldset>
%  for my $field (@fields){
%      my $err = validation->error($field);
  <div class="form-group <%= $err ? 'has-error' : '' %>">
%=   label_for $field => $fields{$field} => class => 'control-label'
%      if ($field =~ /pass/){
%=         input_tag $field => class=>'form-control', type => 'password';
%      }
%      else {
%=         text_field $field => class=>'form-control'
%      }
%      if ($err) {
        <span class="help-block"><%= errtext($err) %></span>
%      }
%      if ($field eq 'pass' and $msg and $msg =~ /invalid credential/){
%           $msg = undef;
        <span class="help-block">Password Invalid</span>
%      }
  </div>
%  }
  </fieldset>
  % if ($msg) {
  <div class="panel panel-danger">
    <div class="panel-heading">PROBLEM!</div>
    <div class="panel-body">
    %= $msg
    </div>
  </div>
  % }

  %= submit_button 'Set Password' => class=>"btn btn-primary col-xs-12"
% end
</div>
</div>


@@ thanks.html.ep
% layout 'default';

<div class="col-sm-6 col-sm-offset-3">
<div class="jumbotron">
    <div class="container">
    <h1>Success!</h1>
    <p>
        The password of user <em><%= validation->param('user') %></em> has been updated.
    </p>
</div>
</div>
