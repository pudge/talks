#!perl -wl
use DB_File;
use Mac::Files;
use strict;
my($file, $user, %db, $string);

$user = "Chris Nandor";

$string = quotemeta(MacPerl::Ask('Whatcha want?'));

$file = FindFolder(kOnSystemDisk, kPreferencesFolderType) .
    ":Netscape Users:$user:Netscape History";

tie %db, 'DB_File', $file, O_RDONLY, 0644 or die $!;

while (my($k, $v) = each %db) {
    print $k if $k =~ /$string/i;
}

print "Done.";
__END__
