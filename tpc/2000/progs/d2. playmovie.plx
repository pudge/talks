#!perl
use strict;
use Mac::Events;
use Mac::LowMem;
use Mac::Movies;
use Mac::QuickDraw;
use Mac::Windows;

my $movie = get_movie('Bird:Trailers:ChickenRun_7_480.mov');
my $win = get_window();
play_movie($win, $movie);

sub play_movie {
	my($win, $movie) = @_;

	my $mrect = get_rect($win->window->portRect, GetMovieBox($movie));
	$win->new_movie($movie, $mrect);
	SetMovieBox($movie, $mrect);
	SetMovieGWorld($movie, $win->window);

	StartMovie($movie);
	$win->sethook(redraw => sub { UpdateMovie($movie) });
	while ($win->window && !IsMovieDone($movie)) {
		WaitNextEvent;
		MoviesTask($movie, 5000);
	}
}

sub get_rect {
	my($wbox, $mbox) = @_;
	my($left, $top, $right, $bottom) = (0, 0, 0, 0);

	my $mh = $mbox->bottom - $mbox->top;
	my $mw = $mbox->right - $mbox->left;
	my $mr = $mh/$mw;

	my $wh = $wbox->bottom - $wbox->top;
	my $ww = $wbox->right - $wbox->left;
	my $wr = $wh/$ww;

	if ($mr < $wr) {	# movie too short
		$right = $ww;
		my $height = int($wh * $wr);
		$top = ($wh - $height) / 2;
		$bottom = $height + $top;

	} elsif ($mr > $wr) {	# movie too narrow
		$bottom = $wh;
		my $width = int($ww * $wr);
		$left = ($ww - $width) / 2;
		$right = $width + $left;

	} else {		# movie just right
		$bottom = $wh;
		$right  = $ww;
	}

	return Rect->new($left, $top, $right, $bottom);
}

sub get_window {
	my $bounds;
	my $win = new MacColorWindow (
		GetMainDevice->gdRect,
		'Fullscreen 0',
		1,
		dBoxProc,
		1,
	);

	END { $win->dispose }
	$win->sethook(drawgrowicon => sub {});
	SetPort $win->window;
	RGBBackColor(RGBColor->new(0, 0, 0));

	return $win;
}

sub get_movie {
	my($file) = @_;

	EnterMovies() or die $^E;
	END { ExitMovies() }

	my($resfile) = OpenMovieFile($file);
	die $^E unless $resfile;

	my($movie)   = NewMovieFromFile($resfile, 0, newMovieActive);
	die $^E unless $movie;
	END { DisposeMovie($movie) }

	CloseMovieFile($resfile);
	return $movie;
}
