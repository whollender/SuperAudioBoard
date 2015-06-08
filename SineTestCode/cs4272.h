/******************************************************************************
* Sine loopback test for SuperAudioBoard
*
* CS4272.h
*
* Register definitions for Cirrus Logic CS4272
*
* Copyright (c) 2015 RF William Hollender, whollender@gmail.com
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
********************************************************************************/


#ifndef CS4272_H
#define CS4272_H

#include <stdint.h>

void codec_write(uint8_t reg, uint8_t data);
uint8_t codec_read(uint8_t reg);

void codec_init();

// Section 8.1 Mode Control
#define CODEC_MODE_CONTROL							(uint8_t)0x01
#define CODEC_MC_FUNC_MODE(x)						(uint8_t)(((x) & 0x03) << 6)
#define CODEC_MC_RATIO_SEL(x)						(uint8_t)(((x) & 0x03) << 4)
#define CODEC_MC_MASTER_SLAVE						(uint8_t)0x08
#define CODEC_MC_SERIAL_FORMAT(x)					(uint8_t)(((x) & 0x07) << 0)

// Section 8.2 DAC Control
#define CODEC_DAC_CONTROL							(uint8_t)0x02
#define CODEC_DAC_CTRL_AUTO_MUTE					(uint8_t)0x80
#define CODEC_DAC_CTRL_FILTER_SEL					(uint8_t)0x40
#define CODEC_DAC_CTRL_DE_EMPHASIS					(uint8_t)(((x) & 0x03) << 4)
#define CODEC_DAC_CTRL_VOL_RAMP_UP					(uint8_t)0x08
#define CODEC_DAC_CTRL_VOL_RAMP_DN					(uint8_t)0x04
#define CODEC_DAC_CTRL_INV_POL						(uint8_t)(((x) & 0x03) << 0)

// Section 8.3 DAC Volume and Mixing
#define CODEC_DAC_VOL								(uint8_t)0x03
#define CODEC_DAC_VOL_CH_VOL_TRACKING				(uint8_t)0x40
#define CODEC_DAC_VOL_SOFT_RAMP						(uint8_t)(((x) & 0x03) << 4)
#define CODEC_DAC_VOL_ATAPI							(uint8_t)(((x) & 0x0F) << 0)

// Section 8.4 DAC Channel A volume
#define CODEC_DAC_CHA_VOL							(uint8_t)0x04
#define CODEC_DAC_CHA_VOL_MUTE						(uint8_t)0x80
#define CODEC_DAC_CHA_VOL_VOLUME					(uint8_t)(((x) & 0x7F) << 0)

// Section 8.5 DAC Channel B volume
#define CODEC_DAC_CHB_VOL							(uint8_t)0x05
#define CODEC_DAC_CHB_VOL_MUTE						(uint8_t)0x80
#define CODEC_DAC_CHB_VOL_VOLUME					(uint8_t)(((x) & 0x7F) << 0)

// Section 8.6 ADC Control
#define CODEC_ADC_CTRL								(uint8_t)0x06
#define CODEC_ADC_CTRL_DITHER						(uint8_t)0x20
#define CODEC_ADC_CTRL_SER_FORMAT					(uint8_t)0x10
#define CODEC_ADC_CTRL_MUTE							(uint8_t)(((x) & 0x03) << 2)
#define CODEC_ADC_CTRL_HPF							(uint8_t)(((x) & 0x03) << 0)

// Section 8.7 Mode Control 2
#define CODEC_MODE_CTRL2							(uint8_t)0x07
#define CODEC_MODE_CTRL2_LOOP						(uint8_t)0x10
#define CODEC_MODE_CTRL2_MUTE_TRACK					(uint8_t)0x08
#define CODEC_MODE_CTRL2_CTRL_FREEZE				(uint8_t)0x04
#define CODEC_MODE_CTRL2_CTRL_PORT_EN				(uint8_t)0x02
#define CODEC_MODE_CTRL2_POWER_DOWN					(uint8_t)0x01

// Section 8.8 Chip ID
#define CODEC_CHIP_ID								(uint8_t)0x08
#define CODEC_CHIP_ID_PART							(uint8_t)(((x) & 0x0F) << 4)
#define CODEC_CHIP_ID_REV							(uint8_t)(((x) & 0x0F) << 0)

#endif
