#!perl -w
# ninety-nine-bottles.plx
# pudge@pobox.com, 2000.05.30
# because i can
# thanks to David D. Seay <g-s@navix.net> for much of this code

# to stop playback, click and hold on the File menu until a verse ends
# (a WaitNextEvent after each verse ensures that the mouse event
# [should] work); then select Stop Script from the menu

use Lingua::EN::Syllable;
use Number::Spell;
use Mac::Events;
use Mac::Speech;
use Math::BigInt;
use strict;

local $SIG{__WARN__} = sub {
	warn @_ unless $_[0] =~ /Use of uninitialized value/;
};

my $euro = 0;
my $bottles = new Math::BigInt '99999999999999999999999999999999999999999999999999999999999999999999'; # '3'; #'1000000000';
my $tempo = .15;
my %notes = (
	c	=> 48,
	d	=> 50,
	e	=> 52,
	f	=> 53,
	g	=> 55,
	a	=> 57,
	b	=> 59,
	C	=> 60,
	D	=> 62,
	E	=> 64,
	F	=> 65,
	G	=> 67,
	A	=> 69,
	B	=> 71,
	C1	=> 72,
);

for (%notes) {
	$notes{$_} -= 20;
}

my %acc = (
	's'	=> 1,
	n	=> 0,
	f	=> -1,
);

my $song = <<'EOT';
.				c  n 1

$bottles			A  s 3
bottles of			F  n 3
beer on the wall		A  s 6

$bottles			C1 n 3
bottles of			G  n 3
beer				C1 n 3

.				c  n 3

take one down			A  n 6
pass it a round			A  n 6

$nbottles			F  n 3
bottles  of			F  n 3
beer on the wall		A  s 6
EOT

my $voice = $Voice{'Zarvox'} or die "No voice";
my $channel = NewSpeechChannel($voice) or die $^E;
SetSpeechRate($channel, 200);
END { DisposeSpeechChannel($channel) }

for (; $bottles > 0 ; $bottles = Math::BigInt->new($bottles->bsub(1))) {
	my $nbottles = Math::BigInt->new($bottles-1) || 'no more';
	my $bott_sp = spell_number($bottles, $euro ? (Format => 'eu') : ());
	my $nbott_sp = $nbottles eq 'no more'
		? 'no more'
		: spell_number($nbottles, $euro ? (Format => 'eu') : ());
	my $last;

	print "$bott_sp\n";

	for (split /\n/, $song) {
		my $wait;
		my($words, $note, $acc, $dur) = /^([^\t]+)\t+(\S+) +(\S+) +(\S+)$/
			or next;

		if ($words =~ s/\$bottles/$bott_sp/g) {
			$wait = syllable($bott_sp);
			$last = "b.$bott_sp";

		} elsif ($words =~ s/\$nbottles/$nbott_sp/g) {
			$wait = syllable($nbott_sp);
			$last = "n.$nbott_sp";
		}

		$words =~ s/bottles of/bottle of/  if $last eq 'b.one';
		$words =~ s/bottles  of/bottle of/ if $last eq 'n.one';

		$dur = $wait + 1 if $wait && $wait > 3;
		my $d = $tempo * $dur;

#		printf "%1.2f %2.0d %s\n\n", $d, $dur, $words;

		SetSpeechPitch($channel, $notes{$note} + $acc{$acc});
		SpeakText($channel, $words) or die $^E;

		select(undef, undef, undef, $d);

	}
	WaitNextEvent;
}

__END__
