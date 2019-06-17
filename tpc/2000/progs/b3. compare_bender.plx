#!perl -w
use strict;
use Date::Parse;
use File::Basename;
use File::Find;
use File::Spec::Functions qw(catfile catdir);
use Mac::Glue ':all';
use Symbol;
use Time::Local;

$| = 1;

my $anarchie	= new Mac::Glue 'Anarchie';
my $bbedit	= new Mac::Glue 'BBEdit';
my $a_window	= $anarchie->obj(window => 1);
my $b_window	= $bbedit->obj(window => 1);

my $tmp		= 'Bourque:Cleanup At Startup:';
my $local	= 'Bourque:Prog:src:Pudge:Work:andover:src:bender:slash:';
my $remote	= '/home/slash/';
my $user	= 'slash';
my $pass	= '';
my $host	= 'yaz.pudge.net';

my $tmpfile = catfile($tmp, 'bender listing');
my %dirs;

find(sub {
	my $file = $File::Find::name;
	return unless -f $file && $file =~ /\.p[lm]$/;
	my($name, $path) = fileparse($file);
	return unless $path =~ s/^$local//;
	$dirs{$path}{$name} = timelocal gmtime(time - ((-M $file) * 86400));
}, $local);

for my $dir (keys %dirs) {
	(my $rdir = $dir) =~ s|:|/|g;

	my $err = $anarchie->list($anarchie->obj(file => $tmpfile),
		host => $host, user => $user, password => $pass,
		parsing => 1, path => "$remote$rdir", SWITCH => 1);
		
	if ($err) {
		$anarchie->close($a_window);
		warn "Can't get listing of $remote$rdir\n";
	} else {
		my %ls;
		my $fh = gensym;
		open $fh, $tmpfile or warn "Can't open $tmpfile: $!\n" && next;
		while (<$fh>) {
			chomp;
			my @ls = reverse split /\t/;
			next unless exists $dirs{$dir}{$ls[0]} &&
				str2time("$ls[2] $ls[1]") > $dirs{$dir}{$ls[0]};

			edit_and_compare(
				"$remote$rdir$ls[0]",
				"$local$dir$ls[0]"
			);
		}

		close $fh;
		unlink $tmpfile;
	}

}

print "Done.\n";

sub edit_and_compare {
	my($rpath, $lpath) = @_;

	my $err = $anarchie->edit(path => $rpath, SWITCH => 1,
		host => $host, user => $user, password => $pass);

	if ($err) {
		$anarchie->close($a_window);
		warn "Can't get $rpath\n";
	} else {
		my $result = $bbedit->compare($b_window, against => $lpath);

		if ($^E) {
			$bbedit->close($b_window);
			warn "Compare error: $^E\n";
		} elsif ($result->{differences_found}) {
			print "Hit Return when done comparing:\n  $lpath";
			exit if <> =~ /^q/i;
		} else {
			$bbedit->close($b_window);
		}
	}
}

__END__
