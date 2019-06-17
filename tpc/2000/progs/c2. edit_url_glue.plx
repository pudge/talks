#!perl -w

=pod

=head1 NAME

edit_url_glue


=head1 SYNOPSIS

Edit URL of frontmost Netscape window in BBEdit via Anarchie Pro.

Tested with Netscape Communicator 3.0 and 4.5.1, Anarchie Pro 3.5,
BBEdit 5.1 and BBEdit Lite 4.1.

This version is the same as the other "edit_url", but uses the new
Mac::Glue stuff I am working on.  See http://pudge.net/macperl/
for more information.


=head1 DESCRIPTION

Set up accounts in your "$ENV{HOME}netrc" file, if you trust it
I have my $ENV{HOME} set to my prefs folder, so that's where I put
the netrc file.  Check L<Net::Netrc> for more info.

If you don't want to use Net::Netrc, you can change this:

      ($user, $pass) = get_info($url);

to something like:

      ($user, $pass) = ('me', 'pass');

or even skip them altogether.  If no password is present, Anarchie
Pro will prompt for it.  if no username is present, MacPerl will
prompt for it.  If none is given in the prompt, anonymous will be
assumed.

You will need to adjust the regexes in the "edit this part for your
sites" section to suit your needs.


=head1 AUTHOR

Chris Nandor E<lt>pudge@pobox.comE<gt>, http://pudge.net/

Copyright (c) 1999 Chris Nandor.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the terms
of the Artistic License, distributed with Perl.

Thanks for the idea from Vicki Brown.


=head1 VERSION

19990601

=cut

#-----------------------------------------------------------------#
# initialize program
#-----------------------------------------------------------------#
use Mac::Glue 0.21;
use Mac::Processes;
use strict;
use vars qw($VERSION);

$VERSION = '19990528';
my($user, $pass, $id, $url, $netscape, $anarchie);

$netscape = new Mac::Glue 'Netscape Communicator';
$anarchie = new Mac::Glue 'Anarchie';

$id  = $netscape->list_windows
    or die "No window available";
$url = $netscape->get_window_info($id)
    or die "No URL available";

#-----------------------------------------------------------------#
# edit this part for your site
#-----------------------------------------------------------------#

$url =~ s/\?.*$//;  # remove trailing query string

if ($url =~ m{^https?://(?:\w+.petersons.com|\w+)/f?cgi-bin/}i) {

    # cover URLs at petersons.com hosts that are in cgi-bin or fcgi-bin
    $url =~ s{^https?://(\w+.petersons.com|\w+)/(.*)$}
             {ftp://$1//web/ns-home/$2}xi;

} elsif ($url =~ m{^https?://(?:\w+.petersons.com|\w+)/mcgi-bin/}i) {

    # cover URLs at petersons.com hosts that are in mcgi-bin
    $url =~ s{^https?://(\w+.petersons.com|\w+)/mcgi-bin/(.*)$}
             {ftp://$1//web/ns-home/petersons-56/mck-cgi/$2}xi;

} elsif ($url =~ m{^https?://(?:\w+.petersons.com|\w+)/petersons-56/}i) {

    # cover URLs at petersons.com hosts that are in petersons-56
    $url =~ s{^https?://(\w+.petersons.com|\w+)/(.*)$}
             {ftp://$1//web/ns-home/$2}xi;

} elsif ($url =~ m{^https?://(?:\w+.petersons.com|\w+)/}i) {

    # cover other URLs at petersons.com hosts
    $url =~ s{^https?://(\w+.petersons.com|\w+)/(.*)$}
             {ftp://$1//web/ns-home/doc/$2}xi;

} elsif ($url =~ m{^https?://(?:pudge.net|boston.pm.org)/}i) {

    # cover boston.pm.org and pudge.net URLs
    $url =~ s|^https?|ftp|;

} elsif ($url =~ m{^https?://(?:www.)?news.perl.org/}i) {

    # basic perl.org
    $url =~ s{^https?://((?:www.)?news.perl.org)/(.*)$}
             {ftp://$1/www_docs/news/$2}xi;  # .perl.org

    $url =~ s|^https?|ftp|;

} elsif ($url =~ m{^https?://www.perl(?:mongers)?.org/news/}i) {

    # basic perl.org
    $url =~ s{^https?://(www.perl(?:mongers)?.org)/news/(.*)$}
             {ftp://$1/www_docs/news/$2}xi;

    $url =~ s|^https?|ftp|;

} else { # we don't recognize URL

    # set MacPerl to front for dialog box
    SetFrontProcess(GetCurrentProcess());

    MacPerl::Answer('Cannot edit URL, it is not recognized.');
    exit;
}

#  ($user, $pass) = get_info($url);  # non-Keychain
($user, $pass) = get_info($url);  # Keychain gets pass!

$url =~ s|/$|/index.html|;              # get index.html if ends in /

#-----------------------------------------------------------------#
# tell Anarchie to send the file to Netscape
#-----------------------------------------------------------------#

$user ||= get_user();

# Anarchie will prompt for password if not supplied
{
    my $err = $anarchie->edit(url => $url, user => $user,
        ($pass ? (password => $pass) : ()), SWITCH => 1);
    die($^E = $err) if $err;
}

#-----------------------------------------------------------------#
# get username / password from URL via netrc file (see POD above)
#-----------------------------------------------------------------#

sub get_info {
    my($url, $uri, $host, $netrc) = shift or return;

    # delay loading of modules until needed
    require Net::Netrc;
    die sprintf "%s version %s required--this is only version %s",
        qw(Net::Netrc 2.08), $Net::Netrc::VERSION
        if $Net::Netrc::VERSION < 2.08; # need 2.08 for Mac-specific code
    require URI;
    Net::Netrc->import;
    URI->import;

    # if any of these fail, return undef, and MacPerl and Anarchie
    # will prompt for username and password
    return unless $uri = URI->new($url);
    return unless $host = $uri->host;
    return unless $netrc = Net::Netrc->lookup($host);

    # return found username and password (or undef, if they are empty)
    return (($netrc->lpa)[0,1]);
}

#-----------------------------------------------------------------#
# get user input for user name
#-----------------------------------------------------------------#

sub get_user {
    # set MacPerl to front for dialog box
    SetFrontProcess(GetCurrentProcess());

    my $user = MacPerl::Ask('User name? (leave blank for anonymous)')
        || 'anonymous';
}

__END__
