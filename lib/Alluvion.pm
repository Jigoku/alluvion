package Alluvion;

use strict;
use warnings;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(convert_special_char xdgopen bytes2mb commify);


sub convert_special_char {
	# replaces any characters that complain
	# about being set with set_markup
	my $str = shift;
	# use markup safe ampersands
	$str =~ s/&/&amp;/g;
	# some titles have html tags? remove them...
	$str =~ s/<(\/|!)?[-.a-zA-Z0-9]*.*?>//g;
	return $str
}

sub xdgopen($) {
	system("xdg-open '". shift ."'");
}

sub bytes2mb($) {
	my $bytes = shift;
	return sprintf "%.0f",($bytes / (1024 * 1024));
}

# add commas to an integer
sub commify($) {
	local $_ = shift;
	1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
	return $_;
}



1;
