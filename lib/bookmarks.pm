sub remove_bookmark($) {
	my $item = shift;
	my $i = 0;
	$i++ until $bookmark[$i] eq $item or $i > $#bookmark;
	splice @bookmark, $i, 1;
}

sub populate_bookmarks {
	my $vbox = $builder->get_object( 'vbox_bookmarks' );
	
	destroy_children($vbox);
	chomp(@bookmark);
	
	for my $item (@bookmark) {
		my $hbox = Gtk2::HBox->new;
		my $label = Gtk2::Label->new;
		$label->set_markup("<span size='large'><b>".$item."</b></span>");
		
		my $button_search = Gtk2::Button->new;
		#$button_search->set_label("search");
		$button_search->set_image(Gtk2::Image->new_from_stock("gtk-apply", 'button'));
		$button_search->signal_connect('clicked', 
			sub { 
				$builder->get_object( 'notebook' )->set_current_page(0);
				$builder->get_object( 'entry_query' )->set_text($item);
				on_button_query_clicked();
			}
		);
		
		my $button_remove = Gtk2::Button->new;
		#$button_remove->set_label("remove");
		$button_remove->set_image(Gtk2::Image->new_from_stock("gtk-clear", 'button'));
		$button_remove->signal_connect('clicked', 
			sub { 
				remove_bookmark($item);

				populate_bookmarks();
			}
		);
		
		my $hseparator = new Gtk2::HSeparator();
		
		$hbox->pack_start($label, FALSE,FALSE,0);
		$hbox->pack_end($button_remove, FALSE,FALSE,0);
		$hbox->pack_end($button_search, FALSE,FALSE,0);
		$vbox->pack_start ($hbox, FALSE, FALSE, 0);
		$vbox->pack_start($hseparator, FALSE,FALSE,5);
	}
	$vbox->show_all;
}

1;
