#!/usr/local/bin/perl

use Data::Dumper;
use Path::Tiny;
use Test::More tests => 4;

require_ok( 'Compress::DAWG' );

## Dump of words from /usr/share/dict/words

my @wordlist = path( './words' )->lines( { chomp => 1 } );
my $compressedList = Compress::DAWG::compress( \@wordlist );
my @newcompressedList = path( './words.compressed' )->lines;

is_deeply( $compressedList, \@newcompressedList, 'Compress word list test.' );

BEGIN { use_ok( 'Compress::DAWG', ({ type => 'Mike' }) ) };

my $compressFile = Path::Tiny->tempfile;
$compressFile->spew( $compressedList );
my $decompressFile = Path::Tiny->tempfile;
Compress::DAWG::decompress( $compressFile->filehandle( "<" ), $decompressFile->filehandle( ">" ) );
my @decompressedList = $decompressFile->lines( { chomp => 1 } );

is_deeply( \@wordlist, \@decompressedList );
