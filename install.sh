#!/usr/bin/env sh

./colorist.tcl produce st $1 > stcolors.h
mv stcolors.h ~/project/suckless/st
cd ~/project/suckless/st
make clean
make
sudo make install
cd -

./colorist.tcl produce dwm $1 > dwmcolors.h
mv dwmcolors.h ~/project/suckless/dwm
cd ~/project/suckless/dwm
make clean
make
sudo make install
cd -

./colorist.tcl produce dmenu $1 > dmenucolors.h
mv dmenucolors.h ~/project/suckless/dmenu
cd ~/project/suckless/dmenu
make clean
make
sudo make install
cd - 

./colorist.tcl produce xinit $1 > ~/.xinitrc
