sub launch_magnet($) {
	my $arg = shift;
	threads->create(
		sub {
			system($settings{"magnet_exec"}." '". $arg ."'");
		}
	)->detach;
}



sub bytes2mb($) {
	# convert bytes to megabytes
	my $bytes = shift;
	return sprintf "%.0f",($bytes / (1024 * 1024));
}

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

sub commify($) {
	# add commas to an integer
	local $_ = shift;
	1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
	return $_;
}

sub splice_thread($) {
	my $thread = shift;
	my $i = 0;
	$i++ until $threads[$i] eq $thread or $i > $#threads;
	splice @threads, $i, 1;
}


1;
