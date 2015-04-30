#!/usr/bin/env perl
# --------------------------------------------------------------------
# Alluvion 0.2pre
# Perl/Gtk2 torrent search utility (strike API)
# --------------------------------------------------------------------
# Usage:
#    ./$0 <option>
# --------------------------------------------------------------------
# Options:
#   -d  | --debug          enable debug output
#   -v  | --version        print version
#   -h  | --help           show help
#   -r  | --reset          rewrite user config with default settings
#
# --------------------------------------------------------------------
# Strike API information   : https://getstrike.net/api/
# Alluvion @ GitHub        : https://github.com/Jigoku/alluvion
# --------------------------------------------------------------------
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

my $VERSION = "0.2pre";

use feature ":5.10";
use strict;
use warnings;
use FindBin qw($Bin);
use File::Basename; 
use JSON;
use threads;
use LWP::UserAgent;
#use LWP::Protocol::socks;
use URI::Escape;
use Gtk2 qw(-threads-init -init);
use Glib qw(TRUE FALSE);
$|++;

die "[ -] Glib::Object thread safety failed"
        unless Glib::Object->set_threadsafe (TRUE);

# default paths
my $data = $Bin . "/data/";
my $xml = $data . "alluvion.glade";
my $confdir = $ENV{ HOME } . "/.alluvion/";

# config files
my $conf = $confdir . "config";
my $bookmarks = $confdir . "bookmarks";

# default user settings
my 	%settings = (
	"timeout" 		 	=> "10",
	#"filesize_type"  	=> "",
	"proxy_enabled"  	=> 0,
	"http_proxy_addr"	=> "",
	"http_proxy_port" 	=> 8080,
	#"socks4_proxy_addr"	=> "",
	#"socks4_proxy_port" => 1080,
	#"socks5_proxy_addr"	=> "",
	#"socks5_proxy_port" => 1080,
	"statusbar"      	=> 1,
	"category_filter" 	=> 1
);

my ($category_filter, $subcategory_filter) = ("","");

my $debug = 0;

# global objects
my (
	$builder, 
	$window,
	$preferences,
	$ua,
	$filechooser,
	$filechooser_get,
	@threads,
	@bookmark,
);

# command line arguments
my $helpmsg = (
"Alluvion ".$VERSION." https://jigoku.github.io/alluvion/\n".
"Copyright (C) 2015, Ricky K. Thomson\n\n".
"Usage: ".$0." [-d|-h|-v]\n\n".
"Options:\t-d | --debug\t\t print verbose information\n".
"\t\t-h | --help\t\t show help\n".
"\t\t-v | --version\t\t show version\n"
);

foreach my $arg (@ARGV) {
		if ($arg =~ m/^(--version|-v)$/) { print $VERSION."\n"; exit(0); }
		if ($arg =~ m/^(--help|-h)$/) { print $helpmsg; exit(0); }
		if ($arg =~ m/^(--reset|-r)$/) { no warnings; write_config($conf); print "Wrote default settings to $conf\n"; exit(0); }
		if ($arg =~ m/^(--debug|-d)$/) { print "Alluvion ". $VERSION ."\n" . ("-"x50) ."\n"; $debug = 1; }
}

# sleeping thread, for some reason this stops segfaults at exit
# and several random GLib-GObject-CRITICAL errors, as long as a thread
# is started befor eth interface is visible, this seems to work.
# -- useful for showing momentary debug output too.
my $sleeper = threads->create({'void' => 1},
	sub {
		while (1) {
			if ($debug == 1) {
				# print mem usage
				chomp( my $size = `grep VmSize /proc/$$/status`);
				chomp( my $peak = `grep VmPeak /proc/$$/status`);
				chomp( my $threads = `grep Threads /proc/$$/status`);
				print "[ &] PID:\t".$$." | ".$size." | ".$peak." | ".$threads ."\n";
			}
			sleep 1;
		}		
	}
)->detach;


main();

sub main {
	# create local config directory
	if ( ! -e $confdir ) { mkdir $confdir or die $!; };
	
	# read ~/.alluvion config
	if (-e $conf) {
		open FILE, "<$conf" or die "[ -] $conf: $!\n";
		for (<FILE>) {
			no warnings;
			# perl 5.10 experimental functions
			given($_) {
				when (m/^timeout=\"(\d+)\"/) { $settings{"timeout"} = $1; } 
				#when (m/^filesize_type=\"(.+)\"/) { $settings{"filesize_type"} = $1; } 
				when (m/^proxy_enabled=\"(\d+)\"/) { $settings{"proxy_enabled"} = $1; }
				when (m/^http_proxy_addr=\"(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\"/) { $settings{"http_proxy_addr"} = $1; }
				when (m/^http_proxy_port=\"(\d+)\"/) { $settings{"http_proxy_port"} = $1; }
				#when (m/^socks4_proxy_addr=\"(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\"/) { $settings{"socks4_proxy_addr"} = $1; }
				#when (m/^socks4_proxy_port=\"(\d+)\"/) { $settings{"socks4_proxy_port"} = $1; }
				#when (m/^socks5_proxy_addr=\"(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\"/) { $settings{"socks5_proxy_addr"} = $1; }
				#when (m/^socks5_proxy_port=\"(\d+)\"/) { $settings{"socks5_proxy_port"} = $1; }
				when (m/^statusbar=\"(.+)\"/) { $settings{"statusbar"} = $1; }
				when (m/^category_filter=\"(.+)\"/) { $settings{"category_filter"} = $1; }
			}
		}
	}
	
	if (-e $bookmarks) {
		open FILE, "<$bookmarks" or die "[ -] $bookmarks: $!\n";
		for (<FILE>) {
			push @bookmark, $_;
		}
	}
	
	# check gtkbuilder interface exists
	if ( ! -e $xml ) { die "Interface: '$xml' $!"; }


	$builder = Gtk2::Builder->new();

 	# load gtkbuilder interface
	$builder->add_from_file( $xml );

	# get top level objects
	$window = $builder->get_object( 'window' );
	$filechooser = $builder->get_object( 'filechooserdialog' );
	
	$builder->connect_signals( undef );

	# adjust user settings for interface
	$builder->get_object( 'view_statusbar' )->set_active($settings{"statusbar"});
	$builder->get_object( 'view_category' )->set_active($settings{"category_filter"});
	
	# draw the window
	$window->show();
	
	# initialize LWP::UserAgent with some default settings
	ua_init();
	
	# proxy settings
	if ($settings{"proxy_enabled"} eq 1) {
		$ua->proxy([ 'http', 'https' ], "http://".$settings{"http_proxy_addr"}.":".$settings{"http_proxy_port"});
		
		if ($debug == 1) {
			# make sure we are routed correctly, show real endpoint address
			my $ip = $ua->get("http://checkip.dyndns.org")->decoded_content;
		
			if ($ip =~ m/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/) { 
					debug("[ *] proxy connection established (" . $1 . ":".$settings{"http_proxy_port"}.")\n");  
			}
		}
	}
	
	# start thread for statusbar display
	set_index_total();
	
	# restore saved bookmarks
	populate_bookmarks();
	
	# main loop
	Gtk2->main(); gtk_main_quit();
}

sub file_request($) {
	# file to fetch
	my $file_uri = shift;
	
	# start a new thread
	my $thread = threads->create(
		sub {
			debug("[ !] thread #". threads->self->tid ." started\n");
			
			# check if we have a connection to network
			if (!($ua->is_online)) {  return 3; }
			
			# get the file
			my $request = HTTP::Request->new( GET => $file_uri );
			my $response = $ua->request($request);

			if ($response->is_success) {
				return $response->content;
			
			} else {
					return 2; # error code
			}
		}
	);
		
	# track the thread
	push (@threads, $thread);
	my $tid = $thread->tid;
	
	# continue to  update the interface while thread is alive
	while ($thread->is_running) {
		Gtk2->main_iteration while (Gtk2->events_pending);
	}
	
	# thread has finished
	debug( "[ !] thread #" .$tid ." finished\n");
	
	# stop tracking the thread
	splice_thread($thread);
	
	return $thread->join;
}
	
	
sub json_request($) {
	# api uri twhich should contain json output
	my $api_uri = shift;
	
	# start a new thread
	my $thread = threads->create(
		sub {
			debug("[ !] thread #". threads->self->tid ." started\n");
			
			# check if we have a connection to network
			if (!($ua->is_online)) {  return 3; }
	
			my $response = $ua->get($api_uri);
			
			if ($debug == 1 && 	$settings{"proxy_enabled"} eq 1) { 
				print "[ *] requested via proxy (". $response->request->{proxy} . ")\n";
			}
				
			if ($response->is_success) {
				# the json text as a string
				return $response->decoded_content;
			} else {	
				return 2; # error code
			}
		}
	);
		
	# track the thread
	push (@threads, $thread);
	my $tid = $thread->tid;
	
	# continue to  update the interface while thread is alive
	while ($thread->is_running) {
		Gtk2->main_iteration while (Gtk2->events_pending);
	}
	
	# thread has finished
	debug( "[ !] thread #" .$tid ." finished\n");
	
	# stop tracking the thread
	splice_thread($thread);
	
	my $data = $thread->join;

	# check for error from thread
	if ($data eq 2) { return "error"; }
	if ($data eq 3) { return "connection"; }
	
	# otherwise return api result as JSON object
	my $json = JSON->new;
	return $json->decode($data);

}

sub populate_bookmarks {
	my $vbox = $builder->get_object( 'vbox_bookmarks' );
	
	destroy_children($vbox);
	chomp(@bookmark);
	
	for my $item (@bookmark) {
		my $button = Gtk2::Button->new;
		$button->set_label($item);
		$button->signal_connect('clicked', 
			sub { 
				print $item . "\n";
				$builder->get_object( 'notebook' )->set_current_page(0);
				$builder->get_object( 'entry_query' )->set_text($item);
				on_button_query_clicked();
			}
		);
		$vbox->pack_start ($button, FALSE, FALSE, 0);
	}
	$vbox->show_all;
}

sub ua_init {
	# reinitialize when called
	$ua = LWP::UserAgent->new(
		keep_alive => 1,
	);
	
	# request timeout
	$ua->timeout($settings{"timeout"});
	
	# provide user agent 
	# (cloudflare blocks libwww-perl/*.*)
	$ua->agent("Alluvion/".$VERSION." https://jigoku.github.io/alluvion/");
	$ua->protocols_allowed( [ 'https', 'http' ] );	
}


sub set_index_total {
	
	my $index_total = $builder->get_object( 'label_indexed_total' );
	my $spinner = $builder->get_object( 'spinner' );
	
	$spinner->set_visible(1);
	$spinner->start;
	$index_total->set_text("Updating index total...");
	
	# threaded request
	my $data = json_request("https://getstrike.net/api/v2/torrents/count/");
	if ($data eq "error") { 
		$index_total->set_text("Could not set index total!");
		$spinner->set_visible(0);
		$spinner->stop;
		debug("[ -] Failed to parse json data\n");
		return; 
	}
	
	if ($data eq "connection") { 
		$index_total->set_text("Connection failed");
		$spinner->set_visible(0);
		$spinner->stop;
		debug("[ -] Failed to get a connection\n");
		return; 
	}
	
	# display the indexed total in statusbar
	for ($data) {
		$index_total->set_markup("".commify($_->{message}) . " indexed torrents");
	}
	
	$spinner->set_visible(0);
	$spinner->stop;
}

sub on_button_hash_clicked {
	my $hash = $builder->get_object( 'entry_hash' )->get_text;
	my $pending = $builder->get_object( 'label_pending' );
	my $spinner = $builder->get_object( 'spinner' );
	my $button = $builder->get_object( 'button_hash' );
	
	# check for valid info hash before doing anything
	if ((length($hash) != 40) || ($hash =~ m/[^a-zA-Z0-9]/)) {
		spawn_dialog("error", "close", "Error", "Invalid info hash");
		return;
	}
	
	$button->set_sensitive(0);
	$pending->set_text("Loading");
	$spinner->set_visible(1);
	$spinner->start;
	
	# returns data from threaded request
	my $data = json_request("https://getstrike.net/api/v2/torrents/info/?hashes=".$hash);
	
	$button->set_sensitive(1);
	$pending->set_text("");
	$spinner->set_visible(0);
	$spinner->stop;
	
	if ($data eq "error") { spawn_dialog("error", "close", "Error", "Failed to find info hash\n"); return; }
		
	if ($data eq "connection") { 
		spawn_dialog("error", "close", "Error", "Could not establish a connection\n");
		return; 
	}

			
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
	my $button_clear = $builder->get_object( 'button_query_clear' );
	my $spinner = $builder->get_object( 'spinner' );
	my $vbox_spinner = Gtk2::Spinner->new;
	my $pending = $builder->get_object( 'label_pending' );
	
	# get top level container ready for packing results
	my $vbox = $builder->get_object('vbox_query_results');
	
	# remove previous results
	destroy_children($vbox);
	
	# must be at least 4 characters for API
	if (length($query) < 4) { 
		my $label = Gtk2::Label->new;
		$label->set_markup("<span size='large'><b>Query must be at least 4 characters.</b></span>");
		$vbox->pack_start($label, FALSE, FALSE, 5);
		$vbox->show_all;	 
		return; 
	}
	
	# setup progress spinner for vbox
	$vbox->pack_start($vbox_spinner, TRUE, TRUE, 175);
	$vbox_spinner->start;
	$vbox_spinner->set_visible(TRUE);
	$vbox->show_all;
	
	$pending->set_text("Loading");
	$button->set_sensitive(FALSE);
	$button_clear->set_sensitive(FALSE);
	$spinner->start;
	$spinner->set_visible(TRUE);
	
	# retrusn data from threaded request	
	my $data = json_request("https://getstrike.net/api/v2/torrents/search/?phrase=".uri_escape($query)."&category=".$category_filter."&subcategory=".$subcategory_filter);
		
	$pending->set_text("");
	$button->set_sensitive(TRUE);
	$button_clear->set_sensitive(TRUE);
	$spinner->set_visible(FALSE);
	$spinner->stop;
	$vbox_spinner->destroy;
		
	if ($data eq "error") { 
		$vbox_spinner->destroy;
		my $label = Gtk2::Label->new;
		$label->set_markup("<span size='large'><b>0 torrents found</b></span>");
		$vbox->pack_start($label, FALSE, FALSE, 5);
		$vbox->show_all;	
		return;	
	}

		
	if ($data eq "connection") { 
		$vbox_spinner->destroy;
		my $label = Gtk2::Label->new;
		$label->set_markup("<span size='large'><b>Could not establish a connection</b></span>");
		$vbox->pack_start($label, FALSE, FALSE, 5);
		$vbox->show_all;	
		return;	
	}

	# results header "X torrent(s) found"
	for ($data) { 
		my $label = Gtk2::Label->new;
		my $results = $_->{results};
		if (not defined $results) { $results = 0; }
		
		$label->set_markup("<span size='large'><b>".($results == 1 ? "1 torrent" : $results . " torrents")." found</b></span>");
		$vbox->pack_start($label, FALSE, FALSE, 5);
	}

	my $n = 0;
				
	for (@{$data->{torrents}}) {
		$n++;
		add_separated_item(
			$vbox, # container to append result
			$n,	# number of item result
			$_->{torrent_title},
			"Seeders: <span color='green'><b>". commify($_->{seeds}) ."</b></span> | Leechers: <span color='red'><b>". commify($_->{leeches}) ."</b></span> | Size: <b>" . commify(bytes2mb($_->{size})) ."MB</b> | Uploaded: " . $_->{upload_date},
			$_->{magnet_uri},
			uc $_->{torrent_hash}
		);	
	}

}

sub on_button_query_clear_clicked {
	# clear the search results/entry
	my $query = $builder->get_object( 'entry_query' );
	$query->set_text("");
	
	my $vbox = $builder->get_object('vbox_query_results');
	destroy_children($vbox);
	
	my $label = Gtk2::Label->new;
	$label->set_markup("<span size='large'><b>Enter a search query</b></span>");
	$vbox->pack_start ($label, FALSE, FALSE, 5);
	$vbox->show_all;
}

sub splice_thread {
	# removes specified thread from @threads
	my $t = shift;
	my $i = 0;
	$i++ until $threads[$i] eq $t or $i > $#threads;
	splice @threads, $i, 1;
}

sub add_separated_item($$$$$$) {
	# adds a label with markup and separator to a vbox 
	# (For list of search results)
	my ($vbox, $n, $torrent_title, $torrent_info, $magnet_uri, $hash) = @_;
				
	my $eventbox = Gtk2::EventBox->new;
	#	$eventbox->signal_connect('enter-notify-event', 
	#		sub { 
	#			$eventbox->modify_bg(
	#				"normal",
	#				Gtk2::Gdk::Color->parse( "#662222" ) 
	#			);
	#		}
	#	 );
	#
	#	$eventbox->signal_connect('leave-notify-event', 
	#		sub { 
	#			$eventbox->modify_bg(
	#				"normal",
	#				Gtk2::Gdk::Color->parse( "#000000" ) 
	#			);
	#		}
	#	 );

	my $tooltip_title = Gtk2::Tooltips->new;
		$tooltip_title->set_tip( $eventbox, $torrent_title );

	my $hseparator = new Gtk2::HSeparator();
		
	
	my $hbox = Gtk2::HBox->new;
		$hbox->set_homogeneous(FALSE);
		
	# item number of result
	my $number = Gtk2::Label->new;
	$number->set_markup("<span size='large'>".$n.".</span>");
	$number->set_alignment(0,.5);
	$number->set_width_chars(3);

		
	my $vboxinfo = Gtk2::VBox->new;
		$hbox->set_homogeneous(0);
		
	# create new label for truncated title with tooltip
	my $label_title = Gtk2::Label->new;
	$label_title->set_markup("<span size='large'><b>".convert_special_char($torrent_title) ."</b></span>");
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
		$buttonbox->set_homogeneous(FALSE);
		
	# pack everything
	$vbox->pack_start($hseparator, FALSE, FALSE, 0);
	$hbox->pack_start($number, FALSE, FALSE, 5);
	$vboxinfo->pack_start($label_title, FALSE, FALSE, 0);
	$vboxinfo->pack_start ($label, FALSE, FALSE, 0);
		
	$buttonbox->pack_end ($button_magnet, FALSE, FALSE, 0);
	$buttonbox->pack_end ($button_torrent, FALSE, FALSE, 0);
	$buttonbox->pack_end ($button_hash, FALSE, FALSE, 0);
		
	$hbox->pack_start ($vboxinfo, FALSE, FALSE, 0);
	$hbox->pack_end ($buttonbox, FALSE, FALSE, 0);
	$eventbox->add ($hbox);
	$vbox->pack_start ($eventbox, FALSE, FALSE, 0);
	$vbox->set_homogeneous(FALSE);
	
	$vbox->show_all;
}

sub on_menu_edit_preferences_activate {
	# initialize the preferences dialog with currently stored settings
	my $preferences = $builder->get_object( 'preferences' );
	
	$builder->get_object( 'entry_timeout' )->set_value($settings{"timeout"});
	
	if ($settings{"proxy_enabled"} eq 1) {
		$builder->get_object( 'entry_http_proxy_addr' )->set_sensitive(1); 
		$builder->get_object( 'entry_http_proxy_port' )->set_sensitive(1); 
		$builder->get_object( 'checkbutton_proxy' )->set_active(1);
	} else {
		$builder->get_object( 'entry_http_proxy_addr' )->set_sensitive(0); 
		$builder->get_object( 'entry_http_proxy_port' )->set_sensitive(0); 
		$builder->get_object( 'checkbutton_proxy' )->set_active(0);
	}

	$builder->get_object( 'entry_http_proxy_addr' )->set_text($settings{"http_proxy_addr"});
	$builder->get_object( 'entry_http_proxy_port' )->set_value($settings{"http_proxy_port"});
	
	$preferences->run; # loops here
	$preferences->hide;
}

sub on_button_pref_ok_clicked {
	# update the changed settings within preferences
	
	$settings{"timeout"}    = $builder->get_object( 'entry_timeout' )->get_value();
	$settings{"http_proxy_addr"} = $builder->get_object( 'entry_http_proxy_addr' )->get_text();
	$settings{"http_proxy_port"} = $builder->get_object( 'entry_http_proxy_port' )->get_value();
	
	#### add support for environment proxy   EG:
	#if ($builder->get_object( 'checkbutton_env_proxy' )->get_active() == TRUE) {	
	#	$ua->proxy( ['http'], $ENV{HTTP_PROXY} ) if exists $ENV{HTTP_PROXY};
	#}
	
	# check if we enabled/disabled the HTTP/HTTPS proxy option
	if ($builder->get_object( 'checkbutton_proxy' )->get_active() == TRUE) {
		$settings{"proxy_enabled"} = 1;
		
		# reinitialize with proxy
		ua_init();
		$ua->proxy([ 'http', 'https' ], "http://".$settings{"http_proxy_addr"}.":".$settings{"http_proxy_port"});
	
		
	} else {
		$settings{"proxy_enabled"} = 0;
		
		# reinitialize without proxy
		ua_init();
	}
	
	# update the config on disk now, if application crashes
	# before shutdown, updated  settings won't be lost.
	write_config($conf);
}

sub on_checkbutton_proxy_toggled {
	# filter input when proxy toggle state changed
	if ($builder->get_object( 'checkbutton_proxy' )->get_active() == TRUE) {
		$builder->get_object( 'entry_http_proxy_addr' )->set_sensitive(1); 
		$builder->get_object( 'entry_http_proxy_port' )->set_sensitive(1); 
	} else {
		$builder->get_object( 'entry_http_proxy_addr' )->set_sensitive(0); 
		$builder->get_object( 'entry_http_proxy_port' )->set_sensitive(0); 
	}
}

sub on_button_pref_cancel_clicked {
	# close the preferences dialog
	$builder->get_object( 'preferences' )->hide;
}


sub on_about_clicked {
	# launch about dialog
	my $about = $builder->get_object( 'aboutdialog' );
	$about->run;
	# make sure it goes away when destroyed
	$about->hide;
}

sub on_menu_file_create_bookmark_activate {
	my $query = $builder->get_object( 'entry_query' )->get_text;
	if (length($query) < 4) {
		spawn_dialog("error", "close", "Error", "Query must be at least 4 characters\n".$!);
		return;
	}
	push @bookmark, $query;
}

sub on_notebook_switch_page {
		my $notebook = $builder->get_object( 'notebook' );
		
		if ($notebook->get_current_page eq 1) {
			my $vbox = $builder->get_object( 'vbox_bookmarks' );
			populate_bookmarks();
		}
}

sub on_button_file_save_clicked {
	$filechooser->hide;
	
	# save the torrent to disk
	my $data = file_request($filechooser_get);
		
	if ($data eq 2) {
		spawn_dialog("error", "close", "Error", "Failed to fetch torrent\n".$!);
		return;
	}
	
	# write the torrent file to disk in specified path
	open FILE, ">", $filechooser->get_filename or die $!;
	binmode FILE;
	print FILE $data;
	close FILE;

	spawn_dialog("info", "ok", "Torrent Saved", $filechooser->get_filename. "\n");

}

sub on_button_file_cancel_clicked {
	$filechooser->hide;
}


sub on_combobox_category_changed {
	# check if the category was changed
	my $combobox = $builder->get_object( 'combobox_category' );
	my $combobox2 = $builder->get_object( 'combobox_subcategory' );
	my $category = $combobox->get_active_text;
	if ($category =~ m/N\/A/) { 
		$category_filter = ""; 
		$combobox2->set_visible(FALSE);
		$subcategory_filter = "";
		return; 
		
	} else {
		$combobox2->set_visible(1);
	}
	$category_filter = $category;
}

sub on_combobox_subcategory_changed {
	# check if the subcategory was changed
	my $combobox = $builder->get_object( 'combobox_subcategory' );
	my $subcategory = $combobox->get_active_text;
	if ($subcategory =~ m/N\/A/) { $subcategory_filter = ""; return; }
	$subcategory_filter = $subcategory;
}


sub on_view_statusbar_toggled {
	# toggle the visibility of the statusbar
	# and update user settings to reflect that
	my $check 	  = $builder->get_object( 'view_statusbar' );
	my $statusbar = $builder->get_object( 'statusbar' );
	
	if ($check->get_active == TRUE) {
		$statusbar->set_visible(TRUE);
		$settings{"statusbar"} = 1;
	} else {
		$statusbar->set_visible(FALSE);
		$settings{"statusbar"} = 0;
	}
}

sub on_view_category_toggled {
	# toggle the visibility of the category filter
	# and update user settings to reflect that
	my $check = $builder->get_object( 'view_category' );
	my $hbox = $builder->get_object( 'hbox_category' );
	
	if ($check->get_active == TRUE) {
		$hbox->set_visible(TRUE);
		$settings{"category_filter"} = 1;
	} else {
		$hbox->set_visible(FALSE);
		$settings{"category_filter"} = 0;
		my $combobox = $builder->get_object( 'combobox_category' );
		my $combobox2 = $builder->get_object( 'combobox_subcategory' );
		$combobox->set_active(0);
		$combobox2->set_active(0);
		$category_filter = ""; 
		$subcategory_filter = "";
	}
}

sub on_view_bookmarks_activate    { populate_bookmarks(); $builder->get_object( 'notebook' )->set_current_page(2); }
sub on_view_hash_lookup_activate  { $builder->get_object( 'notebook' )->set_current_page(1); }
sub on_view_search_query_activate { $builder->get_object( 'notebook' )->set_current_page(0); }


sub apply_filefilter($$$) {
	#create a file filter
	my ($pattern, $name, $object) = @_;
	
	my $filter = Gtk2::FileFilter->new();
	$filter->add_pattern($pattern);
	$filter->set_name($name);
	$object->add_filter($filter);
}


sub spawn_dialog {
	# creates a dialog for errors/info
	my ($type, $button, $title, $message) = @_;

	# $type   can be for example; error, info
	# $button can be for example; ok, cancel, close
	 my $dialog = Gtk2::MessageDialog->new (
		$window,
		'destroy-with-parent',
		$type,
		$button,
		$title
	);
	
	# the error message
	$dialog->format_secondary_text($message);
	
	my $response = $dialog->run;
	$dialog->destroy;
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

sub bytes2mb($) {
	# convert bytes to megabytes
	my $bytes = shift;
	return sprintf "%.0f",($bytes / (1024 * 1024));
}


sub commify($) {
	# add commas to an integer
	local $_ = shift;
	1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
	return $_;
}

sub debug($) {
		if ($debug == 1) { print shift };
}


sub write_config($) {
	# write the changed settings to ~/.alluvion/config
	my $file = shift;
	open FILE, ">$file" or die "$file: $!\n";
	print FILE "# alluvion $VERSION - user settings\n";
	print FILE "timeout=\"".$settings{"timeout"}."\"\n";
	#print FILE "filesize_type=\"".$settings{"filesize_type"}."\"\n";
	print FILE "proxy_enabled=\"".$settings{"proxy_enabled"}."\"\n";
	print FILE "http_proxy_addr=\"".$settings{"http_proxy_addr"}."\"\n";
	print FILE "http_proxy_port=\"".$settings{"http_proxy_port"}."\"\n";
	#print FILE "socks4_proxy_addr=\"".$settings{"socks4_proxy_addr"}."\"\n";
	#print FILE "socks4_proxy_port=\"".$settings{"socks4_proxy_port"}."\"\n";
	#print FILE "socks5_proxy_addr=\"".$settings{"socks5_proxy_addr"}."\"\n";
	#print FILE "socks5_proxy_port=\"".$settings{"socks5_proxy_port"}."\"\n";
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
			
sub gtk_main_quit {
	
	for (@threads) {
		# show any threads that are still alive
		debug( $_."\n");
	}
	
	# detach all remaining threads ( if any)
	$_->detach for threads->list;

	# update stored preferences
	write_config($conf);	
	
	# update bookmarks
	write_bookmarks($bookmarks);	
	
	# cleanup gtk2
	Gtk2->main_quit();
	
	#exit
	exit(0);
}

#EOF#
