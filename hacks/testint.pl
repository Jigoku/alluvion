#!/usr/bin/env perl
use strict;
use warnings;

my $result;

$result = 1;
print format_amount($result) . "\n"; # should say "1 item"

$result = 4;
print format_amount($result) . "\n"; # should say "4 items"

sub format_amount {
    my $i = shift;
    return $i == 1 ? "1 item" : $i . " items";
}
