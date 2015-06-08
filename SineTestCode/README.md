#SineTestCode
The files in this directory are example code for running the SuperAudioBoard with a Teensy 3.x.

This is actual code that was used to perform loopback performance testing (THD+N, etc).

Almost all of the infrastructure type code (MK20DX128 startup, usb serial, etc) is taken directly from the Teensy 3.x core directory in the Arduino tree.

The Makefile will need to be edited for your local build environment.  My libraries and toolchain are all located under "../tools", so any instances of that directory in the Makefile will need to be edited to point to your tools.

I believe that all files in this directory are licensed under the MIT license, if this in error, or there is improper attribution anywhere, please let me know.  The intent is for the files to be freely copied in whole or in part, or used as a guideline for working with the board.
