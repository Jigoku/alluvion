# About Alluvion
Alluvion is a torrent search utility giving you direct access to magnet links, info hashes, and the torrent files themselves. It uses the [strike API](https://getstrike.net/api/) to return results based on your keywords. 

![screenshot](https://cloud.githubusercontent.com/assets/1535179/7192480/064044ee-e48e-11e4-8cce-7357edb18134.png)

## Features
Allows you to lookup and search torrent information indexed by http://getstrike.net/
* search for torrents
* filter search queries by category
* download *.torrent file
* copy info hash to clipboard
* launch magnet with torrent client (via `xdg-open')

## Downloads

Stable releases
* [v0.1](https://github.com/Jigoku/alluvion/releases/tag/0.1)

Obtain development branch
```
$ git clone https://github.com/Jigoku/alluvion.git
```


## Running Alluvion
Alluvion can be started by simply running the main script:
```
$ ./alluvion-gtk.pl
```

Available command line options:
```
 --debug (shows verbose information)
 --version (prints the version and exits)
```

Perl modules required:
* Gtk2
* JSON
* LWP::UserAgent
* URI::Escape

(these should be available on most linux distributions, it's likely they are already installed) 

If you cannot find them in your distributions package repository, try installing missing modules like so:
```
# perl -MCPAN -e 'install JSON'
```

### Why "Alluvion" ?
An Alluvion is "The flow of water against a shore or bank.", hence a torrent is "A stream of water which rapidly flows".

Alluvion brings the torrents directly to you.

## DISCLAIMER
The author does NOT endorse distribution of copyrighted works.
