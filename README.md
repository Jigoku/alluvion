# Alluvion
Unofficial Perl/Gtk2 frontend for [strike API](https://getstrike.net/api/)

## Features
Allows you to lookup and search torrent information indexed by http://getstrike.net/
* lookup an info hash
* search for torrents
* filter search queries by category
* download *.torrent file
* copy info hash to clipboard
* launch magnet with torrent client (via `xdg-open')

## Alpha preview
![screenshot1](https://cloud.githubusercontent.com/assets/1535179/7045128/e34d9942-ddf2-11e4-87ff-20daf1185a39.png)

## NOTE
This is alpha software, features are missing and/or may not exist in the intial release.

## Modules required
* FindBin
* Gtk2
* JSON
* LWP::UserAgent
* URI::Escape

(these should be available on most linux distributions, it's likely they are already installed) 
