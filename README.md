# Alluvion
Unofficial Perl/Gtk2 frontend for [strike API](https://getstrike.net/api/)

## Features
Allows you to lookup and search torrent information indexed by http://getstrike.net/
* search for torrents
* filter search queries by category
* download *.torrent file
* copy info hash to clipboard
* launch magnet with torrent client (via `xdg-open')

## Preview
![screenshot](https://cloud.githubusercontent.com/assets/1535179/7192480/064044ee-e48e-11e4-8cce-7357edb18134.png)

## Releases
[0.1](https://github.com/Jigoku/alluvion/releases/tag/0.1)

## Modules required
* Gtk2
* JSON
* LWP::UserAgent
* URI::Escape

(these should be available on most linux distributions, it's likely they are already installed) 

If you cannot find them in your distributions package repository, try installing missing modules like so:
```
# perl -MCPAN -e 'install JSON'
```
