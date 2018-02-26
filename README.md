# SuperAudioBoard
High quality, 24-bit audio codec board for Teensy 3.x

Files under SineTestCode are under MIT license.
Example Arduino sketches in the "ExampleSketches" directory are public domain.
All other files licensed under Creative Commons CC-BY-SA-NC v4.0 (see LICENSE.md file for details).

Not for commercial use.

A good place to start is the [User Guide](https://github.com/whollender/SuperAudioBoard/blob/master/SuperAudioBoardUserGuide.pdf) or the [Hackaday project page](https://hackaday.io/project/5912-teensy-super-audio-board).

I've added an in-depth [design guide](https://github.com/whollender/SuperAudioBoard/blob/master/SuperAudioBoardDesignGuide.pdf) that walks through the design of the board. 

The [forum thread](https://forum.pjrc.com/threads/27215-24-bit-audio-boards) is another good place for more information.

All design files are in this repo.  Here are a few quick links:
* the [schematic](https://github.com/whollender/SuperAudioBoard/blob/master/SuperAudioBoard_Schematic.pdf)
* the [BOM](https://github.com/whollender/SuperAudioBoard/blob/master/SuperAudioBoard_BOM.csv)
* the "SAB_To_RPi" directory contains the design files for a small board to interface between the SuperAudioBoard and the Raspberry Pi


The files under SineTestCode are example code to get the board up and running with a Teensy 3.x
[This file](https://github.com/whollender/SuperAudioBoard/blob/master/sine_test.hex) is the compiled test code that can be downloaded directly to a Teensy for testing.

I've started integrating the SuperAudioBoard with the Teensy Audio library.  The library currently only supports 16 bit modes, so the initial integration truncates the 24 bit audio samples from the codec to 16 bits for processing in the audio library.
There is a working fork of the audio library with added SuperAudioBoard support in the [github repo](https://github.com/whollender/Audio) in the "SuperAudioBoard" branch.
The files under the "ExampleSketches" directory are a couple of sketches that I've been using to test the board with the Audio library.
Note that all Audio Library objects assume a sample rate of 44.1kHz, while the SuperAudioBoard only supports 48kHz in the audio library (for now, 96/192kHz rates are also possible).  In order to account for the difference between the library sample rate and the actual sample rate, the frequencies used in a sketch should be modified for the actual sample rate.  See the example sketches for details.

The device tree overlay required to use the board with a Raspberry Pi is now included in the 'rpi-update' release, so no kernel building is required.  See the user guide for more details on setting up the Raspberry Pi for SuperAudioBoard support.
