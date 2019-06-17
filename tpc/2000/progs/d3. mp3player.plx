#!perl

=pod

=head1 NAME

mp3player.plx


=head1 DESCRIPTION

Plays MP3 files.  Requires QuickTime 4.0 (currently in beta) and
MPEG::MP3Info module (on CPAN).  This may be developed into a larger
program by the author, or perhaps someone else will take it and run
with it instead (someone more suited to doing GUI work :).

So far there are no keyboard controls, and a playlist should
be added, and all that good stuff.  Maybe skins, different appearances.
Who knows?  If you are inclined to, go crazy, and provide us with
the changes.

Also, this might not perform as well as other MP3 players, but it seems
to perform as well as the QuickTime Player that comes with QuickTime
4.0.  So the hope is that when 4.0 is no longer beta, it will be
perform better.


=head1 COMMANDS

=over 4

=item arrow key left

Go to beginning of song

=item arrow key righ

Go to end of song (window will close)

=item spacebar

Toggle play / pause

=item arrow keys up / down

Supposedly would do volume, but function seems not to work properly

=back


=head1 HISTORY

=over 4

=item v0.16, Friday, April 23, 1999

Cosmetic changes.  Added genre to display.

Fixed problem where windows are created and not removed when non-MP3
files are found.

=item v0.15, Friday, April 23, 1999

Cosmetic changes.

Reorganized and cleaned up some code.

Added menu stuff (Quentin Smith E<lt>macmania@bit-net.comE<gt>).

Added keys and made it into a droplet, accepting folders or
multiple files.  Dialog pops up if no files dropped.  MP3s start
automatically.

MP3s will load into RAM if you set the C<$loadintoram> variable.

Having crashes sometimes ... not sure if it is me, Mac::Movies,
or QT 4.  :)


=item v0.10, Friday, April 23, 1999

First release.

=back


=head1 AUTHOR AND COPYRIGHT

Chris Nandor E<lt>pudge@pobox.comE<gt>, http://pudge.net/

Copyright (c) 1999 Chris Nandor.

This program is free and open software. You may use, modify,
distribute, and sell this program (and any modified variants) in any
way you wish, provided you do not restrict others from doing the same.


=head1 VERSION

v0.16, Friday, April 23, 1999

=cut

use strict;
use File::Basename;
use File::Find;
use Mac::Events qw(:DEFAULT @Event $CurrentEvent);
use Mac::Files;
use Mac::Fonts;
use Mac::Menus;
use Mac::Movies;
use Mac::QuickDraw;
use Mac::Windows;
use MPEG::MP3Info;
use Mac::StandardFile;
use vars qw($win $file $movie $mc $x $x1 $x2 $y1 $y2 $front $back
    $genre $title $curr @str $tottime $loadintoram $QUIT $CLOSE);

$loadintoram = 0;  # switch to 0 to not load, 1 to load
MacPerl::Quit(1);   # quit on exit if runtime
use_winamp_genres;
$| = 1;

{
    do_menus();
    EnterMovies() or die $^E;
    if (@ARGV) {
        find(\&load_movies, @ARGV);
    } else {
        load_movies();
    }
    ExitMovies();
}

sub load_movies {
    next if $_ eq "Icon\n";
    $file = $File::Find::name || ask_for_movie();
    return if $QUIT || ! -f $file;
    do_movie_info($file) or return;
    make_window();
    start_movie();
    WaitNextEvent while check_stuff();
}

sub check_stuff {
    if ($CLOSE) {
#        print $win->window->stdState->top, ":";
#        print $win->window->stdState->left, "\n";
        $win->dispose if defined $win;
        $CLOSE = 0;
    }

    if (IsMovieDone($movie) || !$win->window || $QUIT) {
        DisposeMovie($movie) if defined $movie;
        $mc->dispose if defined $mc;
        $win->dispose if defined $win;
        return;
    }

    draw_time();
}

sub start_movie {
    if (get_movie($file)) {
        $mc = $win->new_movie($movie, Rect->new(-1, 108, $x2 + 1, $y2));
        MCDoAction($mc->movie, mcActionPlay(), 1);
    }
}

sub make_window {
    return if $QUIT;
    ($front, $back) = (GetForeColor(),
        bless(\pack('SSS', 56797, 56797, 56797), 'RGBColor'));

    $x1 ||= 100;
    $y1 ||= 100;
    $x2 = 300;
    $y2 = 100 + 15;

    my $bounds = Rect->new($x1, $y1, $x1 + $x2, $y1 + $y2);
    $win = MacWindow->new(
        NewCWindow($bounds, $title, 1, noGrowDocProc, 1)
    );
    SetPort($win->window);
    RGBBackColor($back);

    $win->sethook( redraw => \&draw_window );
    $win->sethook( drawgrowicon => sub {1} );
    $win->sethook( key => \&handle_keys );

}

sub get_movie {
    my $resfile = OpenMovieFile($file) or die $^E;
    $movie = NewMovieFromFile($resfile, 0, newMovieActive) or die $^E;
    CloseMovieFile($resfile);
    LoadMovieIntoRam($movie, 0, GetMovieDuration($movie), 0)
        if $loadintoram;

    $movie;
}

sub draw_window {
    $x = 15;
    TextFont(geneva());
    TextSize(9);
    TextFace(bold());
    MoveTo(10, 15);
    DrawString($title);
    if ($genre ne '') {
        MoveTo(18 + StringWidth($title), 15);
        TextFace(italic());
        DrawString($genre);
    }
    TextFace(normal());

    for (0 .. $#str) {
        $x += 15;
        MoveTo(10, $x);
        DrawString($str[$_]);
    }

    draw_time();
    1;
}

sub draw_time {
    return 1 if ! $win->window->visible;
    SetPort($win->window());
    my $ncurr = t_format(curr_time());    
    if (!$curr || !$ncurr || $curr ne $ncurr) {
        RGBForeColor($back);
        PaintRect(Rect->new(10, $x + 5, $x2, $x + 20));
        RGBForeColor($front);
    }
    MoveTo(10, $x + 15);
    DrawString(sprintf "%s / %s", $ncurr, $tottime);
    $curr = $ncurr;

    1;
}

sub handle_keys {
    my($my, $v) = @_;
#    print $v, "\n";
    if ($v == ord ' ') {
        playpause();
    } elsif ($v == 28) { # left key
        GoToBeginningOfMovie($movie);
    } elsif ($v == 29) { # right key
        GoToEndOfMovie($movie);
    } elsif ($v == 30) { # up key
        vol_change(1);
    } elsif ($v == 31) { # down key
        vol_change(-1);
    }
}

sub vol_change {
    return 1;   # SetVolume doesn't seem to work :/
    my $vol = MCDoAction($mc->movie, mcActionGetVolume());
    $vol += .001 * shift;
    $vol = 0 if $vol < 0;
    $vol = .008 if $vol > .008;
    MCDoAction($mc->movie, mcActionSetVolume(), $vol) or warn $^E;
}

sub playpause {
    my $playing = (MCGetControllerInfo($mc->movie) & mcInfoIsPlaying())
        == mcInfoIsPlaying;
    MCDoAction($mc->movie, mcActionPlay(), !$playing);
    1;
}

sub do_movie_info {
    my $lfile = shift;
    my($info, $tag) = (get_mp3info($lfile), get_mp3tag($lfile));
    return unless $info;
    undef @str;

    $title = $tag->{TITLE} = $tag->{TITLE} ne '' ? $tag->{TITLE} :
        (fileparse($lfile, '\..{1,3}$'))[0];

    $genre = $tag->{GENRE};

    for ($tag->{ARTIST},
        (join ", ",  grep {$_ ne ''} @{$tag}{qw(ALBUM YEAR)}),
        $tag->{COMMENT},
        (($info->{STEREO} ? "Stereo" : "Mono")
            . " @ $info->{FREQUENCY} kHz / "
            . "$info->{BITRATE} kbps layer $info->{LAYER}")) {
        push @str, $_ if $_ ne '';
    }

    $tottime = t_format(@{$info}{qw(MM SS)});
    1;
}

sub t_format {
    my($mm, $ss) = @_;
    return sprintf "%2.2d:%2.2d", $mm, $ss;
}

sub curr_time {
    my($scale, $time) = (
        GetMovieTimeScale($movie),
        GetMovieTime($movie)
    );
    my($mm, $ss);
    $time /= $scale;
    return (int($time / 60), ($time % 60));
}

sub ask_for_movie {
    my $lfile = StandardGetFile(sub {
        local $_ = $_[0]->ioNamePtr;
        return !/\.mp[23]$/;
    }, 0);
    return unless $lfile->sfGood;
    return $lfile->sfFile;
}

{   # menu stuff
    my($oldEdit, $oldFile, $oldEditor, $newMenu, $newEdit, $newFile);

    sub do_menus {
        $oldEdit   = GetMenuHandle(130);
        $oldFile   = GetMenuHandle(129);
        $oldEditor = GetMenuHandle(133);
        $newMenu   = new_menu();
        $newEdit   = $$newMenu[0]->{menu};
        $newFile   = $$newMenu[1]->{menu};
        change_menu_bar();
        DisableItem($newEdit, 1);
        DisableItem($newEdit, 2);
        DisableItem($newEdit, 3);
        DisableItem($newEdit, 4);
    }

    sub change_menu_bar {
        DeleteMenu(133);
        DeleteMenu(130);
        DeleteMenu(129);
        InsertMenu $newEdit, 133;
        InsertMenu $newFile, 2048;
        DrawMenuBar();
    }

    sub restore_menu_bar {
        DeleteMenu(2048);
        DeleteMenu(2049);
        InsertMenu($oldEdit,   133);
        InsertMenu($oldFile,   130);
        InsertMenu($oldEditor, 134);
        DrawMenuBar();
    }

    sub new_menu {
        my $newEdit = MacMenu->new (
            2048, 'Edit', (
                ['Cut',   \&edit_menu, 'X'],
                ['Copy',  \&edit_menu, 'C'],
                ['Paste', \&edit_menu, 'V'],
                ['Clear', \&edit_menu,  ''],
            )
        );

        my $newFile = MacMenu->new (
            2049, 'File', (
                ['OpenŠ', \&file_menu, 'O'],
                [],
                ['Close', \&file_menu, 'W'],
                [],
                ['Quit', \&file_menu, 'Q'],
            )
        );
        return [$newEdit, $newFile];
    }

    sub edit_menu {
        my ($menu, $item) = @_;
        1;
    }

    sub file_menu {
        my ($menu, $item) = @_;
        if ($menu == 2049) {
            if    ($item == 1)                { 0           }
            elsif ($item == 3)                { $CLOSE = 1  }
            elsif ($item == 5)                { $QUIT = 1   }
         }
    }
}

END {
    restore_menu_bar();
    DisposeMovie($movie) if defined $movie;
    $mc->dispose if defined $mc;
    $win->dispose if defined $win;
}

__END__
