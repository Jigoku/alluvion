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
			my $response = $ua->get($file_uri);
			
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
				
			if ($response->is_success) {
				# the json text as a string
				debug($response->decoded_content);
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

1;
