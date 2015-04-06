# Alluvion
Unofficial Perl/Gtk2 frontend for [strike API](https://getstrike.net/api/)

## Features
Allows you to lookup and search torrent information indexed by http://getstrike.net/
* lookup an info hash
* search for torrents
* download torrent file
* copy info hash to clipboard
* launch magnet with torrent client (via `xdg-open')

## Alpha preview
![screenshot1](https://cloud.githubusercontent.com/assets/1535179/7011654/e10e5672-dca2-11e4-8a6b-3538c3bd662b.png)

## NOTE
This is alpha software, features are missing and/or may not exist in the intial release.

## Modules required
* FindBin
* Gtk2
* JSON
* LWP::UserAgent
* LWP::Simple
* URI::Escape
(these should be available on most linux distributions, it's likely they are already installed) 
