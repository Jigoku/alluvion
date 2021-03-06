# Alluvion 0.3 (20/05/2015)

* implement file_lengths / file_names for hash lookup tool
* check for newer version of Alluvion (Help> Check for updates)
* add support for 'env HTTP_PROXY'
* reorganized preferences dialog
* fix lockup for slow torrent clients when issuing xdgopen()
* magnet_exec config option (path/program to torrent client)
* filesize_type config option (display size as bytes,kb,mb,gb)
* torrent title labels no longer dynamically truncate 
  (previous implementation caused segfaults)
* fixed proxy setting when "cancelling" preferences
* magnet_exec setting for choosing client (now threaded)
* hash lookup interface reworked 
* configurable API URI's (advanced)

# Alluvion 0.2 (07/05/2015)

* now requires perl >= 5.10 for experimental features
* user preferences dialog
* settings file stored to $HOME/.alluvion
* http/https proxy support
* socks4 proxy support
* socks5 proxy support
* configurable connection timeout
* search query labels for torrent titles now expand when window is resized
* bookmark manager
* hash lookup "clipboard" button changed to show more torrent information
* threaded file requests - file_request()
* threaded json requests - json_request()
* many bug fixes and UI improvements
* cleanup properly when exiting
* return key now activates text entry widgets for appropriate button action
* --debug (show debug/verbose output)
* --reset (reset local config with default settings)
* --help (shows help)
* --version (prints version)


# Alluvion v0.1 (16/04/2015)

* implement search query
* can copy info hash to clipboard
* save *.torrent to disk
* launch magnet via xdg-open
* threaded API requests
* progress spinner notification
* GtkBuilder format
* debug mode
