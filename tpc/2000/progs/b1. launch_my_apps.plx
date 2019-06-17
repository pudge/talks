#!perl -wl
use Mac::Apps::Launch;
use Mac::Glue ':all';

Mac::Glue->new('Keychain')->unlock;

my @apps = qw(
	R*ch CSOm Arch NIFt …uck MOSS
);

LaunchApps(\@apps, 1);
SetFront('MACS');
