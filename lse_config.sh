#!/bin/sh

./configure -prefix /usr/local/angstrom/arm.bad/arm-angstrom-linux-gnueabi/usr -release -opensource -confirm-license -no-accessibility -no-xinput2 -no-xcb-xlib -no-cups -no-iconv -no-icu -no-xcb -no-eglfs -no-directfb -no-kms -qpa linuxfb -xplatform linux-arm-gnueabi-g++ -nomake examples -nomake tests -device beagleboard -device-option CROSS_COMPILE=/usr/local/angstrom/arm.angstrom/bin/arm-angstrom-linux-gnueabi-
