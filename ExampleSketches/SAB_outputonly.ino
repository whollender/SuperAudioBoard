// Example Sketch using the SuperAudioBoard with the Teensy Audio library
// RF William Hollender (2015)

// This file is public domain

#include <Audio.h>
#include <Wire.h>
#include <SPI.h>
#include <SD.h>

// GUItool: begin automatically generated code
AudioSynthWaveformSine   sine1;          //xy=185.09091186523438,194.09091186523438
//AudioSynthWaveformSine   sine2;          //xy=189.09091186523438,245.09091186523438
AudioOutputI2S32bitslave           i2s1;           //xy=376.0909118652344,219.09091186523438
AudioConnection          patchCord1(sine1, 0, i2s1, 0);
//AudioConnection          patchCord2(sine2, 0, i2s1, 1);
AudioControlCS4272       AudioBoard;
// GUItool: end automatically generated code


#define CS4272_ADDR 0x10


void setup() {
  // put your setup code here, to run once:
  AudioMemory(20);
  AudioBoard.enable();
  sine1.amplitude(0.5);
  sine1.frequency(1000);

  //sine2.amplitude(0.5);
  //sine2.frequency(1000);

}

void loop() {
  // put your main code here, to run repeatedly:
// Read back audioboard settings
//  for(unsigned int i = 1; i < 9; i++)
//  {
//    Wire.beginTransmission(CS4272_ADDR);
//    Wire.write(i);
//    int ii = Wire.endTransmission();
//    if(ii != 0)
//    {
//      Serial.println("Error in end transmission:");
//      Serial.println(ii);
//      break;
//    }
//    if(Wire.requestFrom(CS4272_ADDR,1) < 1)
//    {
//      Serial.println("Error in request from");
//      break;
//    }
//    Serial.println(Wire.read());
//  }
  
  delay(10000);
}
