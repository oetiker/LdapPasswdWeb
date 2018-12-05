#!/usr/bin/env perl

use lib qw(); # PERL5LIB
use FindBin;use lib "$FindBin::Bin/../lib";use lib "$FindBin::Bin/../thirdparty/lib/perl5"; # LIBDIR

# having a non-C locale for number will wreck all sorts of havoc
# when things get converted to string and back
use POSIX qw(locale_h);
setlocale(LC_NUMERIC, "C");

use Mojolicious::Lite;
use Net::LDAP;
use Net::LDAP::Extension::SetPassword;
use Crypt::SmbHash  qw(ntlmgen);

#die "LDAPPASSWD_LDAP_HOST environment variable is not defined\n"
#   unless $ENV{LDAPPASSWD_LDAP_HOST};
#
#die "LDAPPASSWD_LDAP_BASEDN environment variable is not defined\n"
#    unless $ENV{LDAPPASSWD_LDAP_BASEDN};
#
#print STDERR "LDAPPASSWD_ENABLE_SAMBA environment variable is not defined\n"
#    unless exists $ENV{LDAPPASSWD_ENABLE_SAMBA};

# Make signed cookies secure
app->secrets(['dontneedsecurecookies in this app']);

my $errors = {
    size => sub {
        my ($value,$min,$max) = @_;
        return "Size is must be between $min and $max";
    },
    equal_to => sub {
        my ($value,$key) = @_;
        return "must be equal to '$key'";
    },
    required => sub {
        "entry is mandatory"
    },
    passwordQuality => sub {
        my ($value) = @_;
        return qq{$value expected. See <a href="https://uit.stanford.edu/service/accounts/passwords/quickguide" target="_blank">Help</a> for inspiration.};
    },
    errmsg => sub {
        shift;
    },
};

helper(
    errtext => sub {
        my $c = shift;
        my $err = shift;
        my ($check, $result, @args) = @$err;
        return $errors->{$check}->($result,@args);
    }
);

my $passwordQuality = sub {
    my ($validation, $name, $value) = @_;
    my $len = length $value;
    return "Lowercase letters" if $value !~ /[a-z]/;
    return undef if $len >= 20;
    return "Uppercase letters" if $value !~ /[A-Z]/;
    return undef if $len >= 16;
    return "Numbers" if $value !~ /[0-9]/;
    return undef if $len >= 12;
    return 'Symbols like $%#@.; ...' if $value !~ /[^\sa-zA-Z0-9]/;
    return undef if $len >= 8;
    return "At least 8 characters";
};

# Main login action
any '/' => sub {
    my $c = shift;
    my $validation = $c->validation;
    return $c->render unless $validation->has_data;

    $validation->validator->add_check(passwordQuality => $passwordQuality);

    $validation->required('user')->size(1, 20);
    $validation->required('pass')->size(1,80);
    $validation->required('newpass')->passwordQuality();
    $validation->required('newpass_again')->equal_to('newpass');

    return $c->render if $validation->has_error;

    my $user = $c->param('user');
    my $pass = $c->param('pass');
    my $newpass = $c->param('newpass');

    open my $FH, '-|',"/usr/bin/smbpasswd","-U",$user,"-r","aquarius.carbo-link.com","-s";
    print $FH "$pass\n$newpass\n$newpass\n";
    close $FH;
    if ($?){
        $c->flash(message=>"failed to set smb password $?");
        return $c->render;
    }
    $c->render("Password changed");
};


app->start;
__DATA__

@@ layouts/default.html.ep
<!DOCTYPE html>
<html lang="en" >
  <head>
    <!-- Latest compiled and minified CSS -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">
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
% title 'Samba Password Setter';

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
%      if ($field eq 'pass' and $msg and $msg =~ /invalid credential/i){
%           $err = [ errmsg => 'Invalid Credentials'];
%           $msg = undef;
%      }
  <div class="form-group <%= $err ? 'has-error' : '' %>">
%=   label_for $field => $fields{$field} => class => 'control-label'
%      if ($field =~ /pass/){
%=         input_tag $field => class=>'form-control', type => 'password';
%      }
%      else {
%=         text_field $field => class=>'form-control'
%      }
%      if ($err) {
        <span class="help-block"><%== errtext($err) %></span>
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
