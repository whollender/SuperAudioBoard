// Example Sketch using the SuperAudioBoard with the Teensy Audio library
// RF William Hollender (2015)

// This file is public domain


#include <Audio.h>
#include <Wire.h>
#include <SPI.h>
#include <SD.h>

// GUItool: begin automatically generated code
AudioInputI2S32bitslave  i2s1;           //xy=163,159
AudioAnalyzeFFT256       fft;      //xy=318,157
AudioSynthWaveformSine   sine1;          //xy=384,224
AudioOutputI2S32bitslave i2s2;           //xy=530,231
AudioConnection          patchCord1(i2s1, 1, fft, 0);
AudioConnection          patchCord2(sine1, 0, i2s2, 1);
AudioControlCS4272       AudioBoard;     //xy=365,320
// GUItool: end automatically generated code

#define CS4272_ADDR 0x10

// This is the actual sample rate with the SuperAudioBoard
#define ACTUAL_SAMPLE_RATE 48000

void setup()
{
  AudioMemory(10);
  AudioBoard.enable();

  // Want to set a frequency of 1kHz, but need to account for the difference
  // between the sample rate assumed by the library object (AUDIO_SAMPLE_RATE_EXACT)
  // and the actual sample rate.
  sine1.frequency(1000 * AUDIO_SAMPLE_RATE_EXACT / ACTUAL_SAMPLE_RATE);
  sine1.amplitude(0.5);

}

void loop()
{
  if(fft.available())
  {
    Serial.println("1kHz Amplitude (bin 6):");
    Serial.println(fft.read(0));
    Serial.println(fft.read(1));
    Serial.println(fft.read(2));
    Serial.println(fft.read(3));
    Serial.println(fft.read(4));
    Serial.println(fft.read(5));
    Serial.println(fft.read(6));
    Serial.println(fft.read(7));
    Serial.println(fft.read(8));
    Serial.println(fft.read(9));
    
  }
  else
  {
    Serial.println("FFT result not available");
  }


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
