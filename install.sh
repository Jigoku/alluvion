#!/bin/sh
# prefix for package/install directory
PREFIX=${PREFIX:-/usr/local/}

mkdir -p $PREFIX/{share/alluvion,bin}

cp alluvion-gtk.pl alluvion-gtk
perl -pi -e's,\ \$Bin\ .\ \"/data/\",\"\'$PREFIX'\/share\/alluvion\/\",' alluvion-gtk

install -Dm644 data/alluvion.glade $PREFIX/share/alluvion/alluvion.glade
install -Dm644 data/alluvion_48.png $PREFIX/share/alluvion/alluvion_48.png
install -Dm644 data/alluvion_128.png $PREFIX/share/alluvion/alluvion_128.png
install -Dm755 alluvion-gtk $PREFIX/bin/alluvion-gtk

rm -f alluvion-gtk

# If you want to 'uninstall' alluvion, simply delete these files;
#
# $PREFIX/share/alluvion/alluvion.glade
# $PREFIX/share/alluvion/alluvion_128.png
# $PREFIX/share/alluvion/alluvion_48.png
# $PREFIX/bin/alluvion-gtk
