#!/usr/bin/env perl
# alluvion
# A gtk2/perl frontend for the 'strike' API
#
# Copyright (C) 2015 Ricky K. Thomson
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# u should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

#NOTES
# API information url:
#    https://getstrike.net/api/

# Maybe consider using this wrapper? 
#    https://metacpan.org/pod/WebService::Strike

use strict;
use warnings;
use FindBin qw($Bin);
use Gtk2 qw(-init);
use JSON;
use LWP::UserAgent;
use URI::Escape;

my $ua = LWP::UserAgent->new;
$ua->timeout(4);

my $VERSION = "0.0.9000";

my $data = $Bin . "/data/";
my $xml = $data . "alluvion-gtk.xml";


my (
	$builder, 
	$window,
);

main();

sub main {
	# check libglade xml exists
	if ( ! -e $xml ) { die "Interface: '$xml' $!"; }

        $builder = Gtk2::Builder->new();

 	# load glade XML
	$builder->add_from_file( $xml );

	# get top level object
	$window = $builder->get_object( 'window' );
	$builder->connect_signals( undef );

	# draw the window
	$window->show();

	set_index_total();

	# main loop
	Gtk2->main(); gtk_main_quit();
}



sub set_index_total {
	my $label = $builder->get_object( 'label_indexed_total' );
	my $response = $ua->get("https://getstrike.net/api/v2/torrents/count/");
	
	my $json_text = $response->decoded_content;
	my $json =  JSON->new;
	my $data = $json->decode($json_text);
	
	if ($response->is_success) {
		for ($data) {
			$label->set_markup("".$_->{message} . " indexed torrents");
		}
	} else {
		if ($response->status_line =~ m/404 Not Found/) {
			spawn_error("Error", "Could not set index total\n(Error code 01)");
		}
	}
	
}

sub on_button_hash_clicked {
	my $hash = $builder->get_object( 'entry_hash' )->get_text;
	my $response = $ua->get("https://getstrike.net/api/v2/torrents/info/?hashes=".$hash);

	
	if ($response->is_success) {
		#parse json api result
		my $json_text = $response->decoded_content;
		my $json =  JSON->new;
		my $data = $json->decode($json_text);

		for (@{$data->{torrents}}) {
			$builder->get_object( 'label_torrent_hash' )->set_text($_->{torrent_hash});
			$builder->get_object( 'label_torrent_title' )->set_text($_->{torrent_title});
			$builder->get_object( 'label_sub_category' )->set_text($_->{sub_category});
			$builder->get_object( 'label_torrent_category' )->set_text($_->{torrent_category});
			$builder->get_object( 'label_seeds' )->set_markup("<span color='green'>".$_->{seeds}."</span>");
			$builder->get_object( 'label_leeches' )->set_markup("<span color='red'>".$_->{leeches}."</span>");
			$builder->get_object( 'label_file_count' )->set_text($_->{file_count});
			$builder->get_object( 'label_size' )->set_text(($_->{size})." bytes");
			$builder->get_object( 'label_uploader_username' )->set_text($_->{uploader_username});
			$builder->get_object( 'label_upload_date' )->set_text($_->{upload_date});
			$builder->get_object( 'label_magnet_uri' )->set_text($_->{magnet_uri});
		}
	
	} else {
		if ($response->status_line =~ m/404 Not Found/) {
			spawn_error("Error", "Info hash not found\n(Error code 02)");
		}
	}
}



sub on_button_query_clicked {
	my $query = $builder->get_object( 'entry_query' )->get_text;#
	my $response = $ua->get("https://getstrike.net/api/v2/torrents/search/?phrase=".uri_escape($query));
	
	my $json_text = $response->decoded_content;
	my $json =  JSON->new;
	my $data = $json->decode($json_text);
	
	if ($response->is_success) {
		for ($data) { print "Results: " . $_->{results} . "\n"; }
		
		for (@{$data->{torrents}}) {
			print $_->{torrent_title} . "\n";
			print "seeds: " . $_->{seeds} . " | leechers: " . $_->{leeches} . " | size: " . $_->{size}  . " | uploaded: " . $_->{upload_date} ."\n\n";
		}
	} else {
		if ($response->status_line =~ m/404 Not Found/) {
			spawn_error("Error", "No torrents found\n(Error code 03)");
		}
	}
	
}

sub on_about_clicked {
	# launch about dialog
	my $about = $builder->get_object( 'aboutdialog' );
	$about->run;
	# make sure it goes away when destroyed
	$about->hide;
}


# create an error dialog
sub spawn_error {
	my ($title, $message) = @_;
	 my $dialog = Gtk2::MessageDialog->new (
		$window,
		'destroy-with-parent',
		'error',
		'close',
		$title
	);
	
	$dialog->format_secondary_text($message);
	
	my $response = $dialog->run;
	$dialog->destroy;
}

sub gtk_main_quit {
	# cleanup and exit
	$window->destroy;

	# bye bye
	Gtk2->main_quit();
	exit(0);
}

#EOF#
