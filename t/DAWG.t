#!/usr/local/bin/perl

use Data::Dumper;
use Path::Tiny;
use Test::More tests => 2;

require_ok( 'Compress::DAWG' );

## Dump of words from /usr/share/dict/words

my @wordlist = path( './words' )->lines( { chomp => 1 } );
my $compressed = Compress::DAWG::compress( \@wordlist );
my @newcompressed = path( './words.compressed' )->lines;

is_deeply( $compressed, \@newcompressed, 'Compress word list test.' );

