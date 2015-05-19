
sub debug($) {
		if ($debug == 1) { print shift };
}


sub debug_proxy_address {
	if ($debug eq 1 && $settings{'proxy_enabled'} eq 1) {
		print "[ ~] checking end address...\n";
		my $response = $ua->get("http://checkip.dyndns.org/");
		if ($response->is_success) {
			if ($response->decoded_content =~ m/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/) {
				print "[ !] $1\n";	
			}
		} else {
			print "[ -] $!\n";
		}
		
	}
}

1;
