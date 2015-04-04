#!/usr/bin/env perl
# lookup information about a specified hash
use strict;
use warnings;
use Data::Dumper;
require JSON;

require LWP::UserAgent;
###############################
my $ua = LWP::UserAgent->new;
$ua->timeout(4);

my $api_url_hash = 'https://getstrike.net/api/v2/torrents/info/?hashes=';
my $hash = $ARGV[0];

print "using hash: $hash\n\n";

my $response = $ua->get($api_url_hash.$hash);

if ($response->is_success) {
	#parse json api result
	my $json_text = $response->decoded_content;
	print "json content:\n $json_text\n\n";
	
	my $json =  JSON->new;
	my $data = $json->decode($json_text);

	#print Dumper($data);
	print "\n\n##### begin json parsing #####\n\n";
	for (@{$data->{torrents}}) {
		print "torrent_title:\n" . $_->{torrent_title} . "\n";
		print "\nseeds:\n" . $_->{seeds} . "\n";
		print "\nleeches:\n".$_->{leeches} . "\n";
		print "\nmagnet_uri:\n" .$_->{magnet_uri} . "\n";
		print "\nuploader_username:\n" . $_->{uploader_username} . "\n";
		print "\nupload_date:\n" . $_->{upload_date} . "\n";
		print "\ntorrent_hash:\n" . $_->{torrent_hash} . "\n";
		print "\nfile_count:\n" . $_->{file_count} . "\n";
		print "\nsize:\n" . $_->{size} . "\n";
		print "\nsub_category:\n" . $_->{sub_category} . "\n";
		print "\ntorrent_category:\n" . $_->{torrent_category} . "\n\n";
	}
	
	for (@{$data->{torrents}}) {
		print $_->{file_info}->{file_names} . "\n";
		print $_->{file_info}->{file_lengths} . "\n";
	}
	
} else {
		die $response->status_line;
}
	

