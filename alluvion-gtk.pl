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
	
	if (!($ua->is_online)) { $label->set_markup("No Connection."); return; }
	
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

	# check for valid info hash before doing anything
	if ((length($hash) != 40) || ($hash =~ m/[^a-zA-Z0-9]/)) {
		spawn_error("Error", "Invalid info hash\n(Error code 02)");
		return;
	}
	
	if (!($ua->is_online)) { spawn_error("Error", "No network connection\n(Error code 03)"); return; }
	
	my $response = $ua->get("https://getstrike.net/api/v2/torrents/info/?hashes=".$hash);
		
	if ($response->is_success) {
		#parse json api result
		my $json_text = $response->decoded_content;
		my $json =  JSON->new;
		my $data = $json->decode($json_text);

		# apply data to labels
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
			spawn_error("Error", "Info hash not found\n(Error code 04)");
		}
	}
}



sub on_button_query_clicked {
	my $query = $builder->get_object( 'entry_query' )->get_text;
	
	if (!($ua->is_online)) { spawn_error("Error", "No network connection\n(Error code 03)"); return; }
	my $response = $ua->get("https://getstrike.net/api/v2/torrents/search/?phrase=".uri_escape($query));
	
	my $json_text = $response->decoded_content;
	my $json =  JSON->new;
	my $data = $json->decode($json_text);
		
	# get top level container
	my $vbox = $builder->get_object('vbox_query_results');
	
	# remove previous results
	my @children = $vbox->get_children();
	foreach my $child (@children) {
		$child->destroy;
	}
	
	if ($response->is_success) {
		for ($data) { 
			my $label = Gtk2::Label->new;
			$label->set_markup("<span size='large'><b>".$_->{results}." torrents found</b></span>");
			$vbox->add($label);
		}
		
		my $n = 0;
		for (@{$data->{torrents}}) {
			$n++;
			add_separated_item(
				$vbox, 
				$n,
				"<b>".convert_special_char($_->{torrent_title})."</b>\nSeeders: <span color='green'>". $_->{seeds} ."</span> | Leechers: <span color='red'>". $_->{leeches} ."</span> | Size: " . $_->{size} ." | Uploaded: " . $_->{upload_date},
				$_->{magnet_uri},
				$_->{torrent_hash}
			);
		}
		
	} else {
		if ($response->status_line =~ m/404 Not Found/) {
			spawn_error("Error", "No torrents found\n(Error code 05)");
		}
	
	}
}

sub convert_special_char {
	# replaces any characters that complain
	# about being set with set_markup
	my $str = shift;
	$str =~ s/&/&amp;/g;
	return $str
}

sub xdgopen {
	system("xdg-open '". shift ."'");
}

# adds a label with markup and separator to a vbox (For list of items)
sub add_separated_item($$$$$) {
	my ($vbox, $n, $markup, $link, $hash) = @_;

	# make label clickable
	#my $eventbox = Gtk2::EventBox->new;
	
	my $hseparator = new Gtk2::HSeparator();
		$vbox->add($hseparator);
	
	my $hbox = Gtk2::HBox->new;
		
		
	my $number = Gtk2::Label->new;
	$number->set_markup("<span size='large'><b>".$n."</b></span>");
	$number->set_alignment(0,.5);
		$hbox->pack_start ($number, 0, 0, 5);
		$hbox->set_homogeneous(0);
	# create new label for result
	my $label = Gtk2::Label->new;
	$label->set_markup($markup);
	$label->set_alignment(0,.5);	
		$hbox->pack_start ($label, 0, 1, 5);

	my $button_magnet = Gtk2::Button->new;
		$button_magnet->set_label("open magnet");
		$button_magnet->signal_connect('clicked', sub { xdgopen($link); });
		
	my $button_torrent = Gtk2::Button->new;
		$button_torrent->set_label("save torrent");
		$button_torrent->signal_connect('clicked', sub { print "DEBUG https://getstrike.net/torrents/api/download/".$hash .".torrent\n"; });
		
	my $button_hash = Gtk2::Button->new;
		$button_hash->set_label("copy hash");
		$button_hash->signal_connect('clicked', sub { print "DEBUG " .$hash ."\n"; });
		
	my $buttonbox = Gtk2::HBox->new;
		$buttonbox->set_homogeneous(0);
		$buttonbox->pack_end ($button_magnet, 0, 0, 5);
		$buttonbox->pack_end ($button_torrent, 0, 0, 5);
		$buttonbox->pack_end ($button_hash, 0, 0, 5);
		
	$hbox->add($buttonbox);
	$vbox->add($hbox);

	
	
	
	
	# open manget_uri with xdg-open
	#$eventbox->signal_connect('button-press-event', sub { xdgopen($link) });
	
	# pack result
	
	#$eventbox->add($label);
	#$hbox->add($eventbox);
	
	
	

	$vbox->show_all;
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
