package Compress::DAWG;

use strict;
use warnings;

our $VERSION = 1.007; # Git doesn't do this automatically, like RCS.

my %types = (
     DAWG => { header => "#!xdawg\n",
	       numarr => ['0'..'9','A'..'Z', 'a'..'z'],
	     },
     Mike => { header => '',
	       numarr => ['@','A'..'Z','[','\\',']','^','_','`','a'..'z'],
	     },
	    );

# Default to DAWG.
my $header =    $types{DAWG}{header};
my @numarr = @{ $types{DAWG}{numarr} };

# I copied this idea from the Acme::Time::Baby module by Abigail.
sub import {
  my $class  = shift;
  my $pkg    = __PACKAGE__;
  my $caller = caller;

  my %args   = @_;

  if ( $args{type} ) {
    if ( exists $types{$args{type}} ) {
      $header =    $types{$args{type}}{header};
      @numarr = @{ $types{$args{type}}{numarr} };
    }
    else {
      warn "There is no support for type `$args{type}'\n" if $^W;
    }
  }

  $header =    $args{header} if exists $args{header};
  @numarr = @{ $args{numarr} } if exists $args{numarr};

  no strict 'refs';
  *{$caller . '::compress'} = \&{__PACKAGE__ . '::compress'}
    unless $args{noimport};
  *{$caller . '::decompress'} = \&{__PACKAGE__ . '::decompress'}
    unless $args{noimport};
}

sub compress {
  if (not defined wantarray) { # void context -- use files.
    my $infh = shift;
    my $outfh = shift;
    print $outfh $header;
    my @prev;
    while (<$infh>) {
      chomp;
      my @curr = split '';
      my $num = 0;
      $num++ while defined $prev[$num] and defined $curr[$num] and 
	$prev[$num] eq $curr[$num] and $num < @numarr;
      my $temp = join '', @curr[$num .. $#curr];
      print $outfh "$numarr[$num]$temp\n";
      @prev = @curr;
    }
  } elsif (wantarray) { # array context -- use arrays.
    my @out;
    push @out, $header;
    my @prev;
    foreach (@_) {
      chomp;
      my @curr = split '';
      my $num = 0;
      $num++ while defined $prev[$num] and defined $curr[$num] and 
	$prev[$num] eq $curr[$num] and $num < @numarr;
      my $temp = join '', @curr[$num .. $#curr];
      push @out, "$numarr[$num]$temp\n";
      @prev = @curr;
    }
    return @out;
  } else { # scalar context -- use array references.
    my $in = shift;
    my @out;
    push @out, $header;
    my @prev;
    foreach (@{$in}) {
      chomp;
      my @curr = split '';
      my $num = 0;
      $num++ while defined $prev[$num] and defined $curr[$num] and 
	$prev[$num] eq $curr[$num] and $num < @numarr;
      my $temp = join '', @curr[$num .. $#curr];
      push @out, "$numarr[$num]$temp\n";
      @prev = @curr;
    }
    return \@out;
  }
}

sub decompress {
  if (not defined wantarray) { # void context -- use files.
    my $infh = shift;
    my $outfh = shift;
    my $numstr = join '', @numarr;
    my @prev;
    scalar <$infh> if $header;
    while (<$infh>) {
      chomp;
      my @curr = split '';
      my $num = index $numstr, shift @curr;  
      my $temp = join '', @prev[0..$num-1], @curr;
      print $outfh "$temp\n";
      @prev = split '', $temp;
    }
  } elsif (wantarray) { # array context -- use arrays.
    my @out;
    my $numstr = join '', @numarr;
    my @prev;
    shift @_ if $header;
    foreach (@_) {
      chomp;
      my @curr = split '';
      my $num = index $numstr, shift @curr;  
      my $temp = join '', @prev[0..$num-1], @curr;
      push @out, "$temp\n";
      @prev = split '', $temp;
    }
    return @out;
  } else { # scalar context -- use array references.
    my $in = shift;
    my @out;
    my $numstr = join '', @numarr;
    my @prev;
    shift @{$in} if $header;
    foreach (@{$in}) {
      chomp;
      my @curr = split '';
      my $num = index $numstr, shift @curr;  
      my $temp = join '', @prev[0..$num-1], @curr;
      push @out, "$temp\n";
      @prev = split '', $temp;
    }
    return \@out;
  }
}

1;

__END__

=pod

=head1 NAME

Compress::DAWG - compress and decompress according to the DAWG algorithm.

=head1 SYNOPSIS

    # Compress stdin.
    use Compress::DAWG;
    print compress <>;

    # Compress using references.
    use Compress::DAWG;
    @wordlist = <>;
    $aref = compress \@wordlist;
    print @{$aref};

    # Decompress Mike's way using files.
    use Compress::DAWG type => 'Mike';
    decompress(\*INFILE, \*OUTFILE);


=head1 DESCRIPTION

Use of this module gives you the functions C<compress> and
C<decompress>, which compress and decompress lists of words according to
the DAWG algorithm. I wrote this module after a friend of mine, Mike,
sent me his Fortran program for compressing the wordlists he uses to
solve puzzles. I thought it looked vaguely familiar, and sure enough, it
is more or less equivalent to the DAWG (Directed Acyclic Word Graph)
algorithm used by Crack (and others). This algorithm is described by
Alec Muffett in the Crack FAQ:

    1. sort the wordlist into normal Unix order. (beware localization!)

    2. for each word that the DAWG preprocessor reads...

    3. count how many leading characters it shares with the previous
    word that was read...

    4. encode that number as a character from the set [0-9A-Za-z] for
    values 0..61 (if the value is >61 then stop there)

    5. print said character (the encoded number) and the remaining stem
    of the word

    6. end-for-loop

    eg:

    foo
    foot
    footle
    fubar
    fub
    grunt

    compresses to:

    #!xdawg      magic header
    0foo         first word has no letters in common with anything
    3t           next has three letters in common, and a 't'
    4le          "foot" + "le"
    1ubar        "f" + "ubar"
    3            "fub" + "" => truncation
    0grunt        back to nothing in common

    Inspiration for using DAWG in Crack came from Paul Leyland back in
    the early 1990s, who mentioned something similar being used to
    encode dictionaries for crossword-puzzle solving programs; we
    continue to be astonished at how effective DAWG is on sorted inputs
    without materially impacting subsequent compression (ie: gzip); a
    gzipped-DAWG file is also typically about 50% of the size of the
    gzipped non-DAWGed file.

The description above was taken from 

    FAQ for Crack v5.0a
    Copyright (c) Alec Muffett, 1999, 2000, 2001
    Revised: Wed Mar 21 02:38:38 GMT 2001

    http://www.users.dircon.co.uk/~crypto/download/c50-faq.html

When I suggested to Mike that he had reinvented a scheme dating to at
least 1990, he said no, he first heard about it years ago at a talk
given by a Navy Admiral (Grace Hopper?). He wrote

    I first saw this wordlist scheme used in 1972.  I think it was about
    25 years old then.  I have used it to store wordlists on my Atari
    which had a wopping 48K bytes!

The functions in this module will either compress or decompress the
given data using either Mike's version or Crack's version, depending on
the options you give it. The following options can be passed:

=over 4

=item B<type>  STRING

The type of header and numarr to use. There are currently only two
choices: C<DAWG> and C<Mike>. The default is DAWG.

=item B<numarr> ARRAYREF

An array of characters to be used for numbers. This will override the
numarr implied by the type.

=item B<header> STRING

A string to be used as a header. This will override the header implied
by the type.

=item B<noimport> EXPR

By default, the subroutines C<compress> and C<decompress> will be
exported to the calling package. If for some reason the calling package
does not want to import these subroutines, there are two ways to prevent
this. Either use C<use Compress::DAWG ()>, which will prevent
C<Compress::DAWG::import> from being called, or pass C<noimport>
followed by a true value as arguments to the C<use> statement.

=back

As the synopsis implies, the behavior of the subroutines C<compress> and
C<decompress> depends on context. In array context, they expect a list
and they return a list. In scalar context, they expect a reference to an
array and they return a reference to an array. In void context, they
expect a pair of filehandles as arguments. They will read from the first
filehandle and write to the second. This might be needed if the word
list is too big to fit into memory.

Note the version of Crack that I have seems to use a numarr that matches
the ASCII table starting at '0', rather than the one documented
above. That is, to actually decode the dwg files that come with Crack, I
have to use the following:

    use Compress::DAWG numarr => ['0'..'9',':',';','<','=','>','?','@',
                                  'A'..'Z','[','\\',']','^','_','`',
                                  'a'..'z'];

although you probably do not need that many characters. I wonder if I
should make that the default? Hm. Since this is contiguous ASCII, as is
Mike's version, this whole module can be done in four one-liners!

    # Mike's compress.
    perl -ple '@c=split q//;$n=0;$n++ while $p[$n] eq $c[$n];$_=chr
    64+$n;$_.=join q//, @c[$n..$#c];@p=@c;' words > words.cpt

    # Mike's decompress.
    perl -ple '@c=split q//;$i=shift @c;$n=(ord $i)-64;$_=join q//,
    @p[0..$n-1], @c;@p=split q//' words.cpt > words

    # What Crack seems to actually use for compress.
    perl -ple '@c=split q//;$n=0;$n++ while $p[$n] eq $c[$n];$_=chr
    48+$n;$_.=join q//, @c[$n..$#c];@p=@c;' words > words.dwg

    # What Crack seems to actually use for decompress.
    perl -ple '@c=split q//;$i=shift @c;$n=(ord $i)-48;$_=join q//,
    @p[0..$n-1], @c;@p=split q//' words.dwg > words

Oh, except these will not handle header in the crack versions. Darn!

=head1 AUTHOR

Tim Heaney, I<oylensheegul@gmail.com>.

=head1 LICENSE

This program is copyright 2002-2010 by Tim Heaney.
 
Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:
     
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE. 

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

=cut
