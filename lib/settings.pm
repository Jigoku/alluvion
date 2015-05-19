sub write_config($) {
	# write the changed settings to ~/.alluvion/config
	my $file = shift;
	open FILE, ">$file" or die "$file: $!\n";
	print FILE "# alluvion $VERSION - user settings\n";
	print FILE "timeout=\"".$settings{"timeout"}."\"\n";
	print FILE "magnet_exec=\"".$settings{"magnet_exec"}."\"\n";
	#print FILE "filesize_type=\"".$settings{"filesize_type"}."\"\n";
	print FILE "proxy_enabled=\"".$settings{"proxy_enabled"}."\"\n";
	print FILE "proxy_type=\"".$settings{"proxy_type"}."\"\n";
	print FILE "http_proxy_addr=\"".$settings{"http_proxy_addr"}."\"\n";
	print FILE "http_proxy_port=\"".$settings{"http_proxy_port"}."\"\n";
	print FILE "socks4_proxy_addr=\"".$settings{"socks4_proxy_addr"}."\"\n";
	print FILE "socks4_proxy_port=\"".$settings{"socks4_proxy_port"}."\"\n";
	print FILE "socks5_proxy_addr=\"".$settings{"socks5_proxy_addr"}."\"\n";
	print FILE "socks5_proxy_port=\"".$settings{"socks5_proxy_port"}."\"\n";
	print FILE "statusbar=\"".$settings{"statusbar"}."\"\n";
	print FILE "category_filter=\"".$settings{"category_filter"}."\"\n";
	close FILE;
}

sub write_bookmarks($) {
	# write the bookmarks to ~/.alluvion/bookmarks
	my $file = shift;
	open FILE, ">$file" or die "$file: $!\n";
	for (@bookmark) {
		print FILE $_ . "\n";
	}
}

1;
