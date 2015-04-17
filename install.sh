#!/bin/sh
# prefix for package/install directory
PREFIX=${PREFIX:-/usr/local/}

mkdir -p $PREFIX/{share/alluvion,share/alluvion/lib,bin}

cp alluvion-gtk.pl alluvion-gtk
perl -pi -e's,\ \$Bin\ .\ \"/data/\",\"\'$PREFIX'\/share\/alluvion\/\",' alluvion-gtk
perl -pi -e's,\ \$Bin\ .\ \"/lib/\",\"\'$PREFIX'\/share\/alluvion\/lib\/\",' alluvion-gtk

install -Dm644 lib/Alluvion.pm $PREFIX/share/alluvion/lib/Alluvion.pm
install -Dm644 data/alluvion.glade $PREFIX/share/alluvion/alluvion.glade
install -Dm644 data/alluvion_48.png $PREFIX/share/alluvion/alluvion_48.png
install -Dm644 data/alluvion_128.png $PREFIX/share/alluvion/alluvion_128.png
install -Dm755 alluvion-gtk $PREFIX/bin/alluvion-gtk

rm -f alluvion-gtk
