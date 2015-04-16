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

use strict;
use warnings;
use FindBin qw($Bin);
use JSON;
use threads;
use LWP::UserAgent;
use URI::Escape;
use Gtk2 qw(-threads-init -init);
use Glib qw(TRUE FALSE);

die "[ -] Glib::Object thread safety failed"
        unless Glib::Object->set_threadsafe (TRUE);
        
$|++;

my $VERSION = "0.1pre";
my $debug = 1;

my $ua = LWP::UserAgent->new;
	# provide user agent 
	# (cloudflare blocks libwww-perl/*.*)
	$ua->agent("Alluvion/".$VERSION." https://github.com/Jigoku/alluvion");
	$ua->timeout(3);
	print $ua->agent ."\n";

my $data = $Bin . "/data/";
my $xml = $data . "alluvion-gtk.xml";

my (
	$builder, 
	$window,
	$preferences,
	$filechooser,
	$filechooser_get,
	@threads,
);

my ($category_filter, $subcategory_filter) = ("","");

main();

sub main {
	# check libglade xml exists
	if ( ! -e $xml ) { die "Interface: '$xml' $!"; }

    $builder = Gtk2::Builder->new();

 	# load glade XML
	$builder->add_from_file( $xml );

	# get top level objects
	$window = $builder->get_object( 'window' );
	$preferences = $builder->get_object( 'preferences' );
	$filechooser = $builder->get_object( 'filechooserdialog' );
	
	$builder->connect_signals( undef );

	set_index_total();

	# draw the window
	$window->show();

	# main loop
	Gtk2->main_iteration while Gtk2->events_pending;
	Gtk2->main(); gtk_main_quit();
}

sub set_index_total {
	
	debug("[ !] set_index_total() thread #". (scalar(@threads)+1) ." started\n");
	
	my $label = $builder->get_object( 'label_indexed_total' );

	if (!($ua->is_online)) { $label->set_markup("No Connection."); return; }
	
	my $thread = threads->create({'void' => 1},
		sub {
			my $response = $ua->get("https://getstrike.net/api/v2/torrents/count/");
			
			if ($response->is_success) {
				my $json =  JSON->new;
				my $data = $json->decode($response->decoded_content);
		
				for ($data) {
					Gtk2::Gdk::Threads->enter();
					$label->set_markup("".commify($_->{message}) . " indexed torrents");
					Gtk2::Gdk::Threads->leave();	
				}
			} else {
				#if ($response->status_line =~ m/404 Not Found/) {
				Gtk2::Gdk::Threads->enter();
					spawn_error("Error", "Could not set index total");
				Gtk2::Gdk::Threads->leave();
				#}
			}
		}
	);
	
	push (@threads, $thread);
	my $tid = $thread->tid;
	
	while ($thread->is_running) {
		Gtk2->main_iteration while (Gtk2->events_pending);
	}
	
	$thread->join;
	
	debug( "[ !] set_index_total() thread #" .$tid ." finished\n");
}

sub on_button_hash_clicked {
	my $hash = $builder->get_object( 'entry_hash' )->get_text;

	# check for valid info hash before doing anything
	if ((length($hash) != 40) || ($hash =~ m/[^a-zA-Z0-9]/)) {
		spawn_error("Error", "Invalid info hash");
		return;
	}
	
	if (!($ua->is_online)) { spawn_error("Error", "No network connection\n $!"); return; }
	
	my $response = $ua->get("https://getstrike.net/api/v2/torrents/info/?hashes=".$hash);
		
	if ($response->is_success) {
		#parse json api result
		my $json =  JSON->new;
		my $data = $json->decode($response->decoded_content);

		# apply data to labels
		for (@{$data->{torrents}}) {
			$builder->get_object( 'label_torrent_hash' )->set_text($_->{torrent_hash});
			$builder->get_object( 'label_torrent_title' )->set_text($_->{torrent_title});
			$builder->get_object( 'label_sub_category' )->set_text($_->{sub_category});
			$builder->get_object( 'label_torrent_category' )->set_text($_->{torrent_category});
			$builder->get_object( 'label_seeds' )->set_markup("<span color='green'>".$_->{seeds}."</span>");
			$builder->get_object( 'label_leeches' )->set_markup("<span color='red'>".$_->{leeches}."</span>");
			$builder->get_object( 'label_file_count' )->set_text($_->{file_count});
			$builder->get_object( 'label_size' )->set_text(commify(bytes2mb(($_->{size})))."MB");
			$builder->get_object( 'label_uploader_username' )->set_text($_->{uploader_username});
			$builder->get_object( 'label_upload_date' )->set_text($_->{upload_date});
			$builder->get_object( 'label_magnet_uri' )->set_text($_->{magnet_uri});
		}
	
	} else {
		if ($response->status_line =~ m/404 Not Found/) {
			spawn_error("Error", "Info hash not found\n". $!);
		}
	}
	
}

sub destroy_children($) {
	# remove children from object
	my @children = shift->get_children();
	foreach my $child (@children) {
		$child->destroy;
	}
}

sub on_button_query_clicked {
	
	my $query = $builder->get_object( 'entry_query' )->get_text;
	my $button = $builder->get_object( 'button_query' );
	my $spinner = $builder->get_object( 'spinner' );

	# get top level container ready for packing results
	my $vbox = $builder->get_object('vbox_query_results');
	
	# remove previous results
	destroy_children($vbox);
	
	# must be at least 4 characters for API
	if (length($query) < 4) { spawn_error("Error", "Query must be at least 4 characters\n"); return; }
	
	debug("[ !] on_button_query_clicked() thread #". (scalar(@threads)+1) ." started\n");
	
	$button->set_sensitive(0);
	$spinner->start;
	$spinner->set_visible(1);
		
	my $thread = threads->create(
		sub {

			# check for connection
			if (!($ua->is_online)) { spawn_error("Error", "No network connection\n".$!); return; }

			# send request
			my $response = $ua->get(
				"https://getstrike.net/api/v2/torrents/search/?phrase=".uri_escape($query)."&category=".$category_filter."&subcategory=".$subcategory_filter
			);

			if ($response->is_success) {
				return $response->decoded_content;
				
			} else {
				Gtk2::Gdk::Threads->enter();
				my $label = Gtk2::Label->new;
				$label->set_markup("<span size='large'><b>0 torrents found</b></span>");
				$vbox->pack_start($label, 0, 0, 5);
				$vbox->show_all;
				Gtk2::Gdk::Threads->leave();
				return $response->decoded_content;
			}
	
		}
	);
	
	push (@threads, $thread);
	my $tid = $thread->tid;
	

	while ($thread->is_running) {
		Gtk2->main_iteration while (Gtk2->events_pending);
	}
	

	debug( "[ !] on_button_query_clicked() thread #" .$tid ." finished\n");

	$button->set_sensitive(1);
	$spinner->set_visible(0);
	$spinner->stop;
	
	my $json =  JSON->new;
	# should check if it is json data before trying to parse...
	my $data = $json->decode($thread->join);

	for ($data) { 
		my $label = Gtk2::Label->new;
		$label->set_markup("<span size='large'><b>".($_->{results} == 1 ? "1 torrent" : $_->{results} . " torrents")." found</b></span>");
		$vbox->pack_start($label, 0, 0, 5);
	}

	my $n = 0;
				
	for (@{$data->{torrents}}) {
		$n++;

		add_separated_item(
			$vbox, #container to append
			$n,	# number of item
			$_->{torrent_title},
			"Seeders: <span color='green'><b>". commify($_->{seeds}) ."</b></span> | Leechers: <span color='red'><b>". commify($_->{leeches}) ."</b></span> | Size: <b>" . commify(bytes2mb($_->{size})) ."MB</b> | Uploaded: " . $_->{upload_date},
			$_->{magnet_uri},
			uc $_->{torrent_hash}
		);	
	}
}


sub on_button_query_clear_clicked {
	my $query = $builder->get_object( 'entry_query' );
	$query->set_text("");
	
	my $vbox = $builder->get_object('vbox_query_results');
	destroy_children($vbox);
}


sub bytes2mb($) {
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

sub xdgopen($) {
	system("xdg-open '". shift ."'");
}

# adds a label with markup and separator to a vbox (For list of items)
sub add_separated_item {

	my ($vbox, $n, $torrent_title, $torrent_info, $magnet_uri, $hash) = @_;
				
	my $eventbox = Gtk2::EventBox->new;
	
	
	## TODO
	## iterate between shaded/non shaded if possible
	#if ($n % 2) { 
	#	$eventbox->modify_bg(
	#		"normal",
	#		Gtk2::Gdk::Color->parse( ...... ) ## get gtk2 style colours, make shaded
	#	);
	#}
	
	my $tooltip_title = Gtk2::Tooltips->new;
		$tooltip_title->set_tip( $eventbox, $torrent_title );

	my $hseparator = new Gtk2::HSeparator();
		
	
	my $hbox = Gtk2::HBox->new;
		$hbox->set_homogeneous(0);
		
	# item number of result
	my $number = Gtk2::Label->new;
	$number->set_markup("<span size='large'><b>".$n.".</b></span>");
	$number->set_alignment(0,.5);
	$number->set_width_chars(3);
		
	my $vboxinfo = Gtk2::VBox->new;
		$hbox->set_homogeneous(0);
		
	# create new label for truncated title with tooltip
	my $label_title = Gtk2::Label->new;
	$label_title->set_markup("<b>".convert_special_char($torrent_title) ."</b>");
	$label_title->set_width_chars(65); # label character limit before truncated
	$label_title->set_ellipsize("PANGO_ELLIPSIZE_END");
	$label_title->set_alignment(0,.5);	
		
		
	
	# create new label for aditional info
	my $label = Gtk2::Label->new;
	$label->set_markup($torrent_info);
	$label->set_alignment(0,.5);	
		
		
	# magnet uri
	my $button_magnet = Gtk2::Button->new_from_stock("gtk-execute");
		#$button_magnet->set_label("open magnet");
		$button_magnet->signal_connect('clicked', sub { xdgopen($magnet_uri); });
		
	my $tooltip_magnet = Gtk2::Tooltips->new;
		$tooltip_magnet->set_tip( $button_magnet, "Open magnet with xdg-open\n(your preffered torrent client)" );
		
		
	# *.torrent
	my $button_torrent = Gtk2::Button->new_from_stock("gtk-save");
		#$button_torrent->set_label("save torrent");
		$button_torrent->signal_connect('clicked', 
			sub { 
				apply_filefilter("*.torrent", "torrent files", $filechooser);
				apply_filefilter("*", "all files", $filechooser);
				$filechooser->set_current_name($torrent_title.".torrent");
				$filechooser_get = "https://getstrike.net/torrents/api/download/".$hash .".torrent";
				$filechooser->run; 
				$filechooser->hide; 
			}
		);
		
	my $tooltip_torrent = Gtk2::Tooltips->new;
		$tooltip_torrent->set_tip( $button_torrent, "Save *.torrent file as..." );
		
	# info hash
	my $button_hash = Gtk2::Button->new_from_stock("gtk-copy");
		#$button_hash->set_label("copy hash");
		$button_hash->signal_connect('clicked', 
			sub { 
				my $clipboard =  Gtk2::Clipboard->get(Gtk2::Gdk->SELECTION_CLIPBOARD);
				$clipboard->set_text($hash);
			}
		);
	my $tooltip_hash = Gtk2::Tooltips->new;
		$tooltip_hash->set_tip( $button_hash, "Copy info hash to clipboard" );
		
	# container for buttons
	my $buttonbox = Gtk2::HBox->new;
		$buttonbox->set_homogeneous(0);
		
	# add everything

	$vbox->pack_start($hseparator, 0, 0, 5);
	$hbox->pack_start($number, 0, 0, 10);
	$vboxinfo->pack_start($label_title, 0, 0, 0);
	$vboxinfo->pack_start ($label, 0, 0, 0);
		
	$buttonbox->pack_end ($button_magnet, 0, 0, 5);
	$buttonbox->pack_end ($button_torrent, 0, 0, 5);
	$buttonbox->pack_end ($button_hash, 0, 0, 5);
		
	$hbox->pack_start ($vboxinfo, 0, 0, 0);
	$hbox->pack_end ($buttonbox, 0, 0, 0);
	$eventbox->add ($hbox);
	$vbox->pack_start ($eventbox, 0, 0, 0);
	$vbox->set_homogeneous(0);
	
	$vbox->show_all;
	
	
}

sub on_menu_edit_preferences_activate {
	$preferences->show;
	
}

sub on_about_clicked {
	# launch about dialog
	my $about = $builder->get_object( 'aboutdialog' );
	$about->run;
	# make sure it goes away when destroyed
	$about->hide;
}

sub on_button_file_save_clicked {
	$filechooser->hide;
	
	if (!($ua->is_online)) { spawn_error("Error", "No network connection\n".$!); return; }
	
	# could add threading here 
	my $request = HTTP::Request->new( GET => $filechooser_get );
	my $response = $ua->request($request);

	if ($response->is_success) {

		open FILE, ">", $filechooser->get_filename or die $!;
		binmode FILE;
		print FILE $response->content;
		close FILE;
		
	} else {
		if ($response->status_line =~ m/404 Not Found/) {
			spawn_error("Error", "Torrent not found\n".$!);
		}
	}
}

sub on_button_file_cancel_clicked {
	$filechooser->hide;
}


sub on_combobox_category_changed {
	my $combobox = $builder->get_object( 'combobox_category' );
	my $combobox2 = $builder->get_object( 'combobox_subcategory' );
	my $category = $combobox->get_active_text;
	if ($category =~ m/N\/A/) { 
		$category_filter = ""; 
		$combobox2->set_visible(0);
		$subcategory_filter = "";
		return; 
		
	} else {
		$combobox2->set_visible(1);
	}
	$category_filter = $category;
}

sub on_combobox_subcategory_changed {
	my $combobox = $builder->get_object( 'combobox_subcategory' );
	my $subcategory = $combobox->get_active_text;
	if ($subcategory =~ m/N\/A/) { $subcategory_filter = ""; return; }
	$subcategory_filter = $subcategory;
}


sub apply_filefilter($$$) {
	#create a file filter
	my ($pattern, $name, $object) = @_;
	
	my $filter = Gtk2::FileFilter->new();
	$filter->add_pattern($pattern);
	$filter->set_name($name);
	$object->add_filter($filter);
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

# add commas to an integer
sub commify($) {
	local $_ = shift;
	1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
	return $_;
}

sub debug($) {
		if ($debug == 1) { print shift };
}
sub gtk_main_quit {
	
	$_->detach for threads->list;

	Gtk2->main_quit();
	exit(0);
}

#EOF#
