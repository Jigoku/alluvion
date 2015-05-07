# What is Alluvion?

Alluvion is a GPLv3 licensed torrent search utility, giving you direct access to magnet links, info hashes, and the torrent files themselves. It uses the [strike API](https://getstrike.net/api/) to return results based on your keywords. 


Allows you to lookup and search torrent information indexed by http://getstrike.net/
* search for torrents
* filter search queries by category
* download *.torrent files directly
* view torrent information by supplying an info hash
* launch magnet with torrent client (via `xdg-open')
* bookmarks manager
* http/https proxy support
* socks4 proxy support
* socks5 proxy support

## Obtain development branch
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
 --reset (resets to default settings)
 --help (shows help)
```

Perl modules required:
* Gtk2
* JSON
* LWP::UserAgent
* LWP::Protocol::socks
* URI::Escape

(these should be available on most linux distributions, it's likely they are already installed) 

If you cannot find them in your distributions package repository, try installing missing modules like so:
```
# perl -MCPAN -e 'install JSON'
```

## Screenshots
![screenshot](https://cloud.githubusercontent.com/assets/1535179/7506729/a8541c4c-f45b-11e4-9d8b-0350284851f5.png)
![screenshot](https://cloud.githubusercontent.com/assets/1535179/7506730/ac7809e6-f45b-11e4-86bc-a1465cfe8f5d.png)
![sceeenshot](https://cloud.githubusercontent.com/assets/1535179/7506731/af112fe8-f45b-11e4-9afe-f6b39247b008.png)
![screenshot](https://cloud.githubusercontent.com/assets/1535179/7506732/b135b46a-f45b-11e4-9285-c6dbc7c03d62.png)


## DISCLAIMER
The author does NOT endorse distribution of copyrighted works.
