EESchema Schematic File Version 2
LIBS:power
LIBS:device
LIBS:transistors
LIBS:conn
LIBS:linear
LIBS:regul
LIBS:74xx
LIBS:cmos4000
LIBS:adc-dac
LIBS:memory
LIBS:xilinx
LIBS:special
LIBS:microcontrollers
LIBS:dsp
LIBS:microchip
LIBS:analog_switches
LIBS:motorola
LIBS:texas
LIBS:intel
LIBS:audio
LIBS:interface
LIBS:digital-audio
LIBS:philips
LIBS:display
LIBS:cypress
LIBS:siliconi
LIBS:opto
LIBS:atmel
LIBS:contrib
LIBS:valves
LIBS:AudioBoardLib
LIBS:SuperAudioBoard-cache
EELAYER 27 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 8
Title "24 bit audio board for Teensy 3.x"
Date "10 may 2015"
Rev "0.1a"
Comp "RF William Hollender"
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Sheet
S 7700 5200 1650 1550
U 5438B6CB
F0 "TeensyAndDigital" 50
F1 "TeensyAndDigital.sch" 50
F2 "SCL" B L 7700 5350 60 
F3 "SDA" B L 7700 5500 60 
F4 "ADC_DATA" I L 7700 5650 60 
F5 "DAC_DATA" O L 7700 6250 60 
F6 "RSTN" O L 7700 6400 60 
F7 "LRCLK" B L 7700 5800 60 
F8 "BCLK" B L 7700 5950 60 
F9 "SCLK" B L 7700 6100 60 
F10 "VUSB" O R 9350 5350 60 
$EndSheet
$Sheet
S 4800 5200 1550 1550
U 5438C479
F0 "CodecAndAnalog" 50
F1 "CodecAndAnalog.sch" 50
F2 "SCLK" B R 6350 6100 60 
F3 "LRCLK" B R 6350 5800 60 
F4 "BCLK" B R 6350 5950 60 
F5 "ADC_DATA" O R 6350 5650 60 
F6 "DAC_DATA" I R 6350 6250 60 
F7 "SDA" B R 6350 5500 60 
F8 "SCL" B R 6350 5350 60 
F9 "RST_N" I R 6350 6400 60 
$EndSheet
$Sheet
S 4600 3250 1550 1450
U 54459109
F0 "PowerSupply" 50
F1 "PowerSupply.sch" 50
F2 "VUSBIN" I R 6150 3450 60 
$EndSheet
Wire Wire Line
	6350 5350 7700 5350
Wire Wire Line
	6350 5500 7700 5500
Wire Wire Line
	6350 5650 7700 5650
Wire Wire Line
	6350 5800 7700 5800
Wire Wire Line
	6350 5950 7700 5950
Wire Wire Line
	6350 6100 7700 6100
Wire Wire Line
	6350 6250 7700 6250
Wire Wire Line
	6350 6400 7700 6400
Wire Wire Line
	9350 5350 9800 5350
Wire Wire Line
	9800 5350 9800 3450
Wire Wire Line
	9800 3450 6150 3450
Text Notes 3650 1050 0    100  ~ 0
(c) 2015 by RF William Hollender (whollender@gmail.com)\nLicensed under Creative Commons CC-BY-SA-NC v4.0\nNot for commercial use
$EndSCHEMATC
