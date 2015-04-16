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
use IO::Socket::Socks::Wrapper;
use IO::Socket::SSL;

my $host = "checkip.dyndns.com";
my $port = 80;
my $timeout = 5;

my $data;
my $header = <<MSG;
GET /api/v2/torrents/count/ HTTP/1.0
host:getstrike.net
accept: text/html
user-agent:Alluvion/0.1pre

MSG

$header = <<MSG;
GET / HTTP/1.1
host:checkip.dyndns.com
accept: text/html
user-agent:Alluvion/0.1pre

MSG



	IO::Socket::Socks::Wrapper->import( 
		IO::Socket:: => {
			ProxyAddr => '83.133.126.243',
			ProxyPort =>  8080,
			SocksDebug => 1,
			Timeout => 10
		}
	);



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
			) or return $!;
	
			$socket->autoflush(1);
			print $socket $header;
			
			while(<$socket>) {
				$data .= $_;
			}
			close $socket;

			my @response = split "\n", $data;
			
			#dump headers/content
			# print $data;
			
			if ($response[0] =~ m/200 OK/) {
				return $response[$#response];
			}
		}
	);

	while ($t->is_running) {
			print "[ ?] $t waiting...\n";
			sleep select(undef, undef, undef, 0.10);
	}
	
	print "[ !] $t finished...\n";
	return $t->join;

}


my ($status) = &spawn_socket();

print $status ."\n";

