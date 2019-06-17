#!perl -w
use strict;
use Mac::InternetConfig qw(:DEFAULT $ICInstance);
use LWP::Simple;
use LWP::UserAgent;

ICGeneralFindConfigFile($ICInstance);
my $ua = new LWP::UserAgent;
my $req = new HTTP::Request GET => 'http://random.yahoo.com/bin/ryl';

print "\nStarting ...\n";

while (1) {
	my($url, $res);
	eval {
		local $SIG{ALRM} = sub { die "alarm\n" };
		alarm 5;   # give it 5 seconds to fail
		$res = $ua->simple_request($req);
		$url = $res->header('location') or die "bad url\n";

		# check that we can hit the server before asking Netscape
		# to do it.  It is extra overhead, but keeps Netscape
		# from hanging on a bad URL
		ICLaunchURL($ICInstance, 0, $url) if head $url;
	};

	alarm 0;	   # reset alarm

	unless ($@) {  # silently ignore bad URLs and move on
		print $url, "\n";
		sleep 10;  # pause for 10 seconds if eval success
	}
}

__END__
