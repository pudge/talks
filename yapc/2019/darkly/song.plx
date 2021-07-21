#!/usr/bin/perl
# Through a Terminal Darkly
use 5.010;
our $I;

verse1();
prechorus();
chorus(1);
verse2();
prechorus();
chorus(2);


sub verse1 {
    #D    Em7
    $I = !open BOOK;                    # I’m not an open book
    #G   A
    $I = not defined;                   # I am not defined
    #Bm7         G
    eval { $_ while $I = wait }         # eval it while I wait
    #Em7      A             G A
    until ('inf' == time);              # until the end of time
}

sub verse2 {
    #D      Em7
    if (our @love = split '') {         # if our love were split
        #G   A
        $_ = join '', @love;            # it would be joined again
    }
    #D       Em7
    if ($I = kill 4, our @love) {       # If I kill for our love
        #G   A
        $_ = sin;                       # it would be a sin
    }
}

sub prechorus { 0_0_0_0_0_0_0_0 }

sub chorus {
    my($end) = @_;
    for (1..4) {
        #Em7     G
        bless my $soul = {};                # bless my soul
        #Em7    G
        tell my $mind;                      # tell my mind
        #Em7    G       Bm7 (A last time)
        seek my $heart, 0, 0;               # seek my heart, oh oh
    }

    if ($end == 1) {
        #G
        for (times) {                       # for all times
            #A
            if ($I) { last }                # if I last
        }
    }
    elsif ($end == 2) {
        #G
        given (@_) {                        # given all that
            #A
            do $_ or break;                 # do it or break
        }
    }
}

__END__
