#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($Bin);
use Gtk2 qw(-init);
use JSON;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new;
$ua->timeout(4);

my $VERSION = "0.0.9000";

my $data = $Bin . "/data/";
my $xml = $data . "alluvion-gtk.xml";

my $api_hash = 'https://getstrike.net/api/v2/torrents/info/?hashes=';

my (
	$builder, 
	$window 

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

	# main loop
	Gtk2->main(); gtk_main_quit();
}

sub on_button_hash_clicked {
	my $hash = $builder->get_object( 'entry_hash' )->get_text;
	my $response = $ua->get($api_hash.$hash);
	
	if ($response->is_success) {
		#parse json api result
		my $json_text = $response->decoded_content;
		my $json =  JSON->new;
		my $data = $json->decode($json_text);
	
		for (@{$data->{torrents}}) {
			$builder->get_object( 'label_torrent_hash' )->set_markup("<b>Info Hash:</b>\n".$_->{torrent_hash});
			$builder->get_object( 'label_torrent_title' )->set_markup("<b>Torrent Title:</b>\n".$_->{torrent_title});
			$builder->get_object( 'label_sub_category' )->set_markup("<b>Sub Category:</b>\n".$_->{sub_category});
			$builder->get_object( 'label_torrent_category' )->set_markup("<b>Torrent Category:</b>\n".$_->{torrent_category});
			$builder->get_object( 'label_seeds' )->set_markup("<b>Seeders:</b>\n".$_->{seeds});
			$builder->get_object( 'label_leeches' )->set_markup("<b>Leechers:</b>\n".$_->{leeches});
			$builder->get_object( 'label_file_count' )->set_markup("<b>File Count:</b>\n".$_->{file_count});
			$builder->get_object( 'label_size' )->set_markup("<b>Filesize:</b>\n".($_->{size})." bytes");
			$builder->get_object( 'label_uploader_username' )->set_markup("<b>Uploader:</b>\n".$_->{uploader_username});
			$builder->get_object( 'label_upload_date' )->set_markup("<b>Upload Date:</b>\n".$_->{upload_date});
			$builder->get_object( 'label_magnet_uri' )->set_markup("<b>Magnet URI:</b>\n".$_->{magnet_uri});
		}
	
	} else {
		die $response->status_line;
}
}

sub on_about_clicked {
	# launch about dialog
	my $about = $builder->get_object( 'aboutdialog' );
	$about->run;
	# make sure it goes away when destroyed
	$about->hide;
}

sub gtk_main_quit {
	# cleanup and exit
	$window->destroy;

	# bye bye
	Gtk2->main_quit();
	exit(0);
}

#EOF#
