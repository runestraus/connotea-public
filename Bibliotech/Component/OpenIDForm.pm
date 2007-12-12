# Copyright 2007 Nature Publishing Group
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# The Bibliotech::Component::OpenIDForm class provides a login form
# that uses OpenID third party authentication.

package Bibliotech::Component::OpenIDForm;
use strict;
use base 'Bibliotech::Component';
use Bibliotech::OpenID;

sub last_updated_basis {
  ('NOW');
}

sub html_content {
  my ($self, $class, $verbose, $main) = @_;

  my $bibliotech = $self->bibliotech;
  my $cgi        = $bibliotech->cgi;
  my $memcache   = $bibliotech->memcache;
  my $location   = $bibliotech->location;

  my $openid 	 = $cgi->param('openid');
  my $button 	 = $cgi->param('button');
  my $ret    	 = $cgi->param('ret');
  my $sid    	 = $cgi->param('cssid');

  my $validationmsg;

  if ($button or $ret) {
    my $myopenid = Bibliotech::OpenID->new($sid, $location, $memcache);
    my $url = eval {
      if ($button and $button =~ /^login$/i) {
	return $myopenid->start_and_get_url
	    ($openid,
	     sub { Bibliotech::User->by_openid(shift) });
      }
      if ($ret) {
	return $myopenid->login
	    ({map {$_ => $cgi->param($_)} $cgi->param},
	     sub { my ($openid, $sreg_sub) = @_;
		   $bibliotech->allow_login_openid($openid, $sreg_sub); },
	     sub { my $user = shift;
		   my $login = Bibliotech::Component::LoginForm->new({bibliotech => $bibliotech});
		   $login->do_login_and_return_location($user, $bibliotech); });
      }
    };
    if (my $e = $@) {
      die $e if $e =~ / at .* line /;
      $validationmsg = $self->validation_exception('openid', $e);
    }
    else {
      die "Location: $url\n" if $url;
    }
  }

  my $o = $self->tt('compopenid', undef, $validationmsg);

  my $javascript_first_empty = $self->firstempty($cgi, 'openid', qw/openid/);

  return Bibliotech::Page::HTML_Content->new({html_parts => {main => $o},
					      javascript_onload => ($main ? $javascript_first_empty : undef)});
}

1;
__END__