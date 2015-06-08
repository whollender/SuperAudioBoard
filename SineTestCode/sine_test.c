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

#include "mk20dx128.h"
#include "usb_serial.h"
#include "usb_dev.h"
#include "core_pins.h"
#include <string.h>
#include "i2c.h"
#include "cs4272.h"
#include "avr_functions.h"
#include "i2s.h"
#include "delay.h"
#include "sine_samples.h"

#define NUM_AVGS 1024

#define NUM_SAMP 4080

#define NUM_RUNS 256

uint8_t serial_read_line(char* buf, uint8_t max_len);
void serial_write_string(const char *str);

volatile uint16_t tx_buf_idx;
volatile uint16_t rx_buf_idx;
volatile uint16_t curr_run;

//volatile int32_t recv_data_real[SIG_LENGTH];
//volatile int32_t recv_data_imag[SIG_LENGTH];

volatile int32_t recv_data_right[NUM_SAMP];
volatile int32_t recv_data_left[NUM_SAMP];

volatile uint8_t test_running = 0;
//volatile uint8_t output_real_part = 1;


char buffer[64];

int main(void)
{
	uint16_t i;
	char temp_char;
	uint8_t num_chars_ret;

	// For CS4272 (uC i2s interface in slave mode) not sure about
	// initialization sequence (i2s interface first, or setup cs4272 first)
	// For now, start with codec (get interface clocks started first)


	// Initialize USB
    usb_init();
	delay(100);

	// Initialize I2C subsystem
	i2c_init();
    delay(100);



	for(i = 0; i < 64; i++)
	{
		buffer[i] = 0;
	}
	
	// Wait to setup codec to make sure user has turned on audio board power
	while((buffer[0] != 'y') && (buffer[0] != 'Y'))
	{
		serial_write_string("Init codec? (y/n)\r\n>");
		
		// Wait for response
		num_chars_ret = serial_read_line(buffer,64);

		if(num_chars_ret < 1)
		{
			serial_write_string("Error reading line. Please try again.\r\n");
		}
	}

	for(i = 0; i < 64; i++)
	{
		buffer[i] = 0;
	}

	// Initialize CS4272
	codec_init();
	delay(100);



	// Initialize I2S subsystem 
	i2s_init();
	delay(10);

	serial_write_string("Codec Initialized\r\n");
	delay(10);


	// Test to see if i2c is working
	uint8_t reg_result;
	uint8_t ii;
	for(ii = 1; ii < 9; ii++)
	{
		itoa(ii,buffer,10);
		serial_write_string("Address ");
		serial_write_string(buffer);
		serial_write_string(": ");


		reg_result = codec_read(ii);
		itoa(reg_result,buffer,10);
		serial_write_string(buffer);
		serial_write_string("\r\n");
		delay(100);
	}

	for(i = 0; i < 64; i++)
	{
		buffer[i] = 0;
	}

	serial_write_string("Waiting 10 seconds for ADC high pass filter to stabilize\r\n");
	delay(10000);
	
	while(1)
	{
		
		// Initialize indices, etc
		tx_buf_idx = 0;
		rx_buf_idx = 0;
		curr_run = 0;

		for(i = 0; i < NUM_SAMP; i++)
		{
			//recv_data_real[i] = 0;
			//recv_data_imag[i] = 0;
			recv_data_right[i] = 0;
			//recv_data_left[i] = 0;
		}



		for(i = 0; i < 64; i++)
		{
			buffer[i] = 0;
		}


		while((buffer[0] != 'y') && (buffer[0] != 'Y'))
		{
			serial_write_string("Start test? (y/n)\r\n>");
			
			// Wait for response
			num_chars_ret = serial_read_line(buffer,64);

			if(num_chars_ret < 1)
			{
				serial_write_string("Error reading line. Please try again.\r\n");
			}
		}

		// Start test
		serial_write_string("Starting test.\r\n");
		//output_real_part = 1;
		test_running = 1;
		i2s_start();

		// Wait for real part to finish
		while(test_running)
		{
			//serial_write_string("Running real part.  Please wait .....\r\n");
			delay(1000);
		}

		// Test is now finished
//		serial_write_string("Real part is finished.  Starting imaginary part.\r\n");
//		
//		delay(1000);
//
//		// Start imaginary part
//		output_real_part = 0;
//		test_running = 1;
//		i2s_start();
//
//		// Wait for real part to finish
//		while(test_running)
//		{
//			//serial_write_string("Running imaginary part.  Please wait .....\r\n");
//			delay(1000);
//		}
//
//		// Test is now finished
//		serial_write_string("Imaginary part is finished.  Printing Data.\r\n");

		// Print data
		for(i = 0; i < NUM_SAMP; i++)
		{
			itoa(recv_data_right[i],buffer,10);
			serial_write_string(buffer);
			serial_write_string(",");
			itoa(recv_data_left[i],buffer,10);
			serial_write_string(buffer);
			serial_write_string("\r\n");
			delay(50);
		}

		serial_write_string("End of data.\r\n");
		
	}

	return 0;
}

uint8_t serial_read_line(char* buf, uint8_t max_len)
{
	int ret;
	uint8_t num_chars = 0;
	//char out_buffer[32];

	while(num_chars < max_len)
	{
		ret = usb_serial_getchar();
		if(ret == -1)
		{
			//strcpy(out_buffer,"getchar returns -1\r\n");
			//usb_serial_write(out_buffer, strlen(out_buffer));
			//yield();

		}
		else
		{
			if(ret == '\r' || ret == '\n')
			{
				// We've read the whole line so return
				//strcpy(out_buffer, "found EOL, returning\r\n");
				//usb_serial_write(out_buffer,strlen(out_buffer));

				return num_chars;
			}
			else
			{
				//strcpy(out_buffer, "Got character: ");
				//usb_serial_write(out_buffer,strlen(out_buffer));

				//usb_serial_putchar(ret);
				//usb_serial_putchar('\r');
				//usb_serial_putchar('\n');

				buf[num_chars] = ret;
				num_chars++;
			}
		}
	}

	return num_chars;
}

void serial_write_string(const char *str)
{
	usb_serial_write(str,strlen(str));
}


void i2s0_tx_isr(void)
{
	int32_t res, dummy_var;

	int32_t outp_samp = (out_buf[tx_buf_idx] << 8);

	//serial_write_string("Entered RX ISR\r\n");

	// output right channel only
	I2S0_TDR0 = 0;
	//if(output_real_part)
	//{
		I2S0_TDR0 = outp_samp;
	//}
	//else
	//{
		//I2S0_TDR0 = out_buf_imag[tx_buf_idx];
	//}
	//I2S0_TDR0 = 0;
	
	tx_buf_idx++;
	if(tx_buf_idx >= SIG_LENGTH)
	{
		tx_buf_idx = 0;
	}	

	// Update 5/22/14: Moved receiver block here so
	// that all the code is in a single interrupt, and the tx/rx
	// indices are guaranteed to match up.
	// -- RFWH
	
	// Rx data is in upper 24 bits of 32 bit int
	// Reading converts uint32_t to int32_t (should
	// keep sign intact), and then we need to
	// right shift by 8 bits to get the 24 bits we want
	// in the right place (assuming the compile will do
	// an arithmetic shift, ie new bit is same as previous MSB to sign extend).
	dummy_var = I2S0_RDR0; // Left chan discarded
	res = I2S0_RDR0; // Right channel data
	//dummy_var = I2S0_RDR0; // Left chan discarded

	// Save all data up until we're out of space
	// Throw out first sample
	if(curr_run > 0)
	{
		recv_data_right[rx_buf_idx] += (res >> 8);
		recv_data_left[rx_buf_idx] += (dummy_var >> 8);
	}

	rx_buf_idx++;

	if(rx_buf_idx >= NUM_SAMP)
	{
		rx_buf_idx = 0;
		curr_run++;
	}

	if(curr_run >= NUM_RUNS)
	{
		i2s_stop();
		curr_run = 0;
		test_running = 0;
		rx_buf_idx = 0;
	}

	// Don't save data on first run (first run will have ~0s for first
	// n samples, where n is delay from spkr to mic)
//	if(curr_run != 0)
//	{
//		if(output_real_part)
//		{
//			recv_data_real[tx_buf_idx] += res;
//		}
//		else
//		{
//			recv_data_imag[tx_buf_idx] += res;
//		}
//	}
//
//	tx_buf_idx++;
//
//	if(tx_buf_idx >= SIG_LENGTH)
//	{
//		tx_buf_idx = 0;
//		curr_run++;
//	}
//
//	if(curr_run >= NUM_AVGS)
//	{
//		i2s_stop();
//		curr_run = 0;
//		test_running = 0;
//		tx_buf_idx = 0;
//	}
}


//void i2s0_rx_isr(void)
//{
//	uint16_t dummy_var;
//	int16_t res;
//
//	res = I2S0_RDR0; // Left channel data
//	dummy_var = I2S0_RDR0; // Right chan discarded
//
//	recv_data_real[rx_buf_idx++] += res;
//
//	if(rx_buf_idx >= SIG_LENGTH)
//	{
//		rx_buf_idx = 0;
//	}
//}
