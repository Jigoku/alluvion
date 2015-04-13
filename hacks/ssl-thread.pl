#!/usr/bin/env perl


# experimenting with sockets
# may replace dependency on LWP::UserAgent
# seems easier to manage threads this way.

# all depends on whether gtk2 interface still 
# functions while waiting for threads...

use strict;
use warnings;
use POSIX;
use threads;
use IO::Socket::SSL;



my $host = "getstrike.net";
my $port = 80;
my $timeout = 5;

my $data;
my $header = <<MSG;
GET /api/v2/torrents/info/?hashes=B425907E5755031BDA4A8D1B6DCCACA97DA14C04 HTTP/1.0
host:getstrike.net
accept: text/html
user-agent:Alluvion/0.1pre

MSG




sub spawn_socket {
	print "[ !] thread started\n";
	
	my $t = threads->create(
		sub {
			my $socket = new IO::Socket::SSL (
				PeerAddr => $host,
				PeerPort => "https",
				SSL_verify_mode => SSL_VERIFY_PEER,
				#SSL_ca_path => '/etc/ssl/certs', # CA path (Linux)
				Proto    => 'tcp',
				Timeout => $timeout,
			) or die $!;
	
			$socket->autoflush(1);
			print $socket $header;
			
			while(<$socket>) {
				$data .= $_;
			}
			close $socket;

			my @response = split "\n", $data;
			
			if ($response[0] =~ m/200 OK/) {
				return $response[12];
			}
		}
	);

	while ($t->is_running) {
			print "[ ?] $t waiting...\n";
			sleep select(undef, undef, undef, 0.10);
	}
	print "[OK] $t finished...\n";
	return $t->join;

}


my $json = &spawn_socket();

print $json ."\n";
