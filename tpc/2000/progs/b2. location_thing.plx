#!perl -wl
# set locations and adjust Hosts file appropriately
# pudge@pobox.com, 2000.05.25 - 2000.07.11

use File::Spec::Functions;
use Mac::Apps::Launch;
use Mac::Files;
use Mac::Glue ':all';
use Mac::InternetConfig;
use Symbol;
use enum qw(AWAY HOME WORK);
use strict;

# get and launch Location Manager
my $lm_path = catfile(
	FindFolder(kOnSystemDisk, kControlPanelFolderType),
	'Location Manager'
);
my $lm = new Mac::Glue 'Location Manager';
$lm->launch($lm_path);
$lm->activate;
END { $lm->quit }

# find all locations, display dialog
my $loc = get_location($lm, get_location_names($lm));

# adjust Hosts file
my $where =
	($loc =~ m|^Home / | && $loc ne "Home / Modem")
		? HOME
		: ($loc =~ m|^Andover / |)
			? WORK
			: AWAY;
set_hosts($where);

# set location
$lm->set(
	$lm->prop('current_location'),
	to => $lm->obj('location' => $loc)
);
warn $^E if $^E;


# get all locations
sub get_location_names {
	my($lm) = @_;
	my @locs;
	for (my $i = 0; $i <= $lm->count('each' => 'location'); $i++) {
		push @locs, $lm->get( $lm->prop(name => 'location' => $i) );
	}

	return @locs;
}

# location dialog
sub get_location {
	my($lm, @locs) = @_;
	my $len = @locs < 3 ? 3 : @locs > 15 ? 15 : @locs;
	my $size = 16.5 * $len;
	my $dialog = {
		size => [260, 95 + $size],
		contents => [
			{
				class		=> 'list box',
				bounds		=> [10, 36, 250, 36 + $size],
				contents	=> \@locs,
			}, {
				class		=> 'push button',
				bounds		=> [190, 65 + $size, 250, 85 + $size],
				name		=> 'OK',
			}, {
				class		=> 'push button',
				bounds		=> [110, 65 + $size, 170, 85 + $size],
				name		=> 'Cancel'
			}
		],
		timeout_after => 60,
	};

	my @results = $lm->dd_auto_dialog($dialog, grayscale => 1);
	die $^E if $^E;

	if ($results[1]) {
		return $locs[$results[0] - 1];
	} else {
		exit;
	}
}

# fix Hosts file
sub set_hosts {
	my($where) = @_;

	my $hosts = gensym;
	my $hostsfile = catfile(
		FindFolder(kOnSystemDisk, kPreferencesFolderType),
		"Hosts"
	);

	open $hosts, "< $hostsfile\0" or die "Can't open $hostsfile: $!";
	my @hosts = <$hosts>;
	for (grep { /; (?:HOME|AWAY)$/ } @hosts) {
		if ($where == HOME) {
			s/^;+//  if /; HOME$/;
			s/^(;+)?/;/ if /; AWAY$/;
			$InternetConfig{kICSMTPHost()} = 'smtp.ply.adelphia.net';
		} else {
			s/^;+//  if /; AWAY$/;
			s/^(;+)?/;/ if /; HOME$/;
			$InternetConfig{kICSMTPHost()} = 
				$where == WORK
					? 'relay1.shore.net'
					: 'pudge.static.cx';
		}
	}
	close $hosts or die "Can't close $hostsfile: $!";

	open $hosts, "> $hostsfile\0" or die "Can't open $hostsfile: $!";
	print $hosts @hosts;
	close $hosts or die "Can't close $hostsfile: $!";
}

__END__
