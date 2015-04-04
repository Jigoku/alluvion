#!/usr/bin/env perl
use strict;
use warnings;
use Gtk2 qw(-init);
use FindBin qw($Bin);

my $VERSION = "0.0.9000";

my $data = $Bin . "/data/";
my $xml = $data . "alluvion-gtk.xml";

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
