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
![screenshot1](https://cloud.githubusercontent.com/assets/1535179/7005419/bcfc0690-dc6f-11e4-8c61-176e1119f4b4.png)

## NOTE
This is alpha software, features are missing and/or may not exist in the intial release.

## Modules required
FindBin, Gtk2, JSON, LWP::UserAgent, URI::Escape
