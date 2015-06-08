/******************************************************************************
* Sine loopback test for SuperAudioBoard
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

/////////////////////////////////////////////////////////////////////////////////
// i2s.c
//
// Implementation of I2S interface sections.  
// William Hollender, 4/28/14
/////////////////////////////////////////////////////////////////////////////////


#include "mk20dx128.h"
#include "i2s.h"

void i2s_init()
{
	SIM_SCGC6 |= SIM_SCGC6_I2S;
	
	// Using external MCLK, so just effectively shut this off
	I2S0_MCR = I2S_MCR_MICS(0);
	I2S0_MDR = 0;

	///////////////////////
	// Setup TX side
	///////////////////////
	

	I2S0_TMR = 0; // Don't mask any words
	I2S0_TCR1 = I2S_TCR1_TFW(2); // Set watermark to one word
	// TODO: need to research watermark positioning a bit better
	
	// Setup for 24 bit left justified
	// Set sync off (TX is master),
	// Bit clock selected for active low (drive on falling edge, sample on rising edge)
	// Bit clock generated externally (slave mode)
	I2S0_TCR2 = I2S_TCR2_SYNC(0) | I2S_TCR2_BCP;

	I2S0_TCR3 = I2S_TCR3_TCE; // Only enable ch 0

	// Frame size is 2 (L + R), sync width is 32 (LR clock is active for first word),
	// MSB first, LR clock asserted with first bit
	// LR clock is active low, and LR clock generated externally.
	I2S0_TCR4 = I2S_TCR4_FRSZ(1) | I2S_TCR4_SYWD(31) | I2S_TCR4_MF 
		| I2S_TCR4_FSP;

	// Set up all word widths to 31, then right shift after reading
	// to get 24 bit data.
	// Could probably set the first word width to 31, remaining widths
	// to 23, and set the first bit to 23, but not sure if that would work
	I2S0_TCR5 = I2S_TCR5_WNW(31) | I2S_TCR5_W0W(31) | I2S_TCR5_FBT(31);


	//////////////////////////////
	// Setup Rx side
	// (pretty much the same as tx
	// but set sync to tx clocks)
	//////////////////////////////
	
	I2S0_RMR = 0; // Don't mask any words

	I2S0_RCR1 = I2S_RCR1_RFW(2); // Set watermark to one word

	// Same settings as tx, but sync to tx
	I2S0_RCR2 = I2S_RCR2_SYNC(1) | I2S_TCR2_BCP;

	I2S0_RCR3 = I2S_RCR3_RCE; // Enable ch 0

	// two words per frame, sync width 16 bit clocks, MSB first, sync early,
	// LR clock(sync) active low, sync generated internally
	I2S0_RCR4 = I2S_RCR4_FRSZ(1) | I2S_RCR4_SYWD(31) | I2S_RCR4_MF
		| I2S_RCR4_FSP;

	// See TX word width discussion above
	I2S0_RCR5 = I2S_RCR5_WNW(31) | I2S_RCR5_W0W(31) | I2S_RCR5_FBT(31);

	// Setup pins
	PORTC_PCR1 = PORT_PCR_MUX(6); // TX
	PORTC_PCR2 = PORT_PCR_MUX(6); // LRCLK
	PORTC_PCR3 = PORT_PCR_MUX(6); // Bit clock
	PORTC_PCR5 = PORT_PCR_MUX(4); // RX
	PORTC_PCR6 = PORT_PCR_MUX(6); // MCLK
	
}


void i2s_start()
{
	// Enable RX first as per Ref manual (I2S chapter, section 4.3.1)
	__disable_irq();
	
	// Updated 5/22/14 to disable receiver interrupts and do
	// all processing in i2s tx interrupt
	// -- RFWH
	
	// RX: enable, reset fifo, and interrupt on fifo request
	//I2S0_RCSR |= I2S_RCSR_RE | I2S_RCSR_FR | I2S_RCSR_FRIE;
	I2S0_RCSR |= I2S_RCSR_RE | I2S_RCSR_FR;

	// TX: enable, bit clock enable, reset fifo, and interrupt on fifo req
	//
	// Not sure if need bit clock enable for slave setup
	I2S0_TCSR |= I2S_TCSR_TE | I2S_TCSR_BCE | I2S_TCSR_FR | I2S_TCSR_FRIE;

	// Load up TX FIFO so that the ISR isn't called immediately (with no
	// data available in RX fifo).  Four writes required to get data past
	// watermark value (2) and still use correct channel (L/R).
	I2S0_TDR0 = 0;
	I2S0_TDR0 = 0;
	I2S0_TDR0 = 0;
	I2S0_TDR0 = 0;


	// enable IRQs
	//NVIC_ENABLE_IRQ(IRQ_I2S0_RX);
	NVIC_ENABLE_IRQ(IRQ_I2S0_TX);
	__enable_irq();
}

void i2s_stop()
{
	__disable_irq();

	NVIC_DISABLE_IRQ(IRQ_I2S0_TX);
	//NVIC_DISABLE_IRQ(IRQ_I2S0_RX);

	I2S0_TCSR &= ~I2S_TCSR_TE;
	I2S0_RCSR &= ~I2S_RCSR_RE;

	__enable_irq();
}

