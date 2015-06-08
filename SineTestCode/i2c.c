/******************************************************************************
* Sine loopback test for SuperAudioBoard
* 
* i2c.c
*
* Basic I2C implementation for master reads and writes on Teensy 3.x
* Based pretty heavily on PJRCs implementation of the arduino wire lib
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

#include "mk20dx128.h"
#include "i2c.h"

extern void yield();

// I2C read error storage
static uint8_t i2c_rx_err = 0;

// I2C initialization state
static uint8_t i2c_init_flag = 0;


// Initialize I2C block
void i2c_init()
{
	if(i2c_init_flag == 0)
	{
		// Turn on clock to I2C block
		SIM_SCGC4 |= SIM_SCGC4_I2C0;

		// Setup pins 18 and 19
		PORTB_PCR3 = PORT_PCR_MUX(2)|PORT_PCR_ODE|PORT_PCR_SRE|PORT_PCR_DSE;
		PORTB_PCR2 = PORT_PCR_MUX(2)|PORT_PCR_ODE|PORT_PCR_SRE|PORT_PCR_DSE;

		// Setup clock divider for 100kHz
		I2C0_F = 0x27;

		// Setup filter for 4 bus clock cycles
		I2C0_FLT = 4;

		// Set high drive
		I2C0_C2 = I2C_C2_HDRS;

		// and, finally, actually enable the device
		I2C0_C1 = I2C_C1_IICEN;
		
		i2c_init_flag = 1;
	}
}


// Write bytes to slave device
uint8_t i2c_write(uint8_t slave_address, uint8_t num_bytes, const uint8_t *buffer)
{
	uint8_t err_code = 0;
	uint8_t i;
	uint8_t stat;

	// Check for num_bytes larger than MAX_BYTES
	if(num_bytes > I2C_WRT_MAX_BYTES)
	{
		return I2C_WRT_ERR_TOO_MANY_BYTES;
	}

	// This is much simpler than the implementation in Wire because
	// we don't have to worry about the i2c slave interrupt leaving
	// the bus in different states
	
	// Clear the flags
	I2C0_S = I2C_S_IICIF | I2C_S_ARBL;

	// TODO: Wait for bus to be free before setting up?
	// Set up the bus for a master tx
	
	// If we're already the master, send a rep start,
	// otherwise, wait for the bus to clear, then send a start
	if(I2C0_C1 & I2C_C1_MST)
	{
		I2C0_C1 = I2C_C1_IICEN | I2C_C1_MST | I2C_C1_RSTA | I2C_C1_TX;
	}
	else
	{
		while(I2C0_S & I2C_S_BUSY)
		{
			yield();
		}

		I2C0_C1 = I2C_C1_IICEN | I2C_C1_MST | I2C_C1_TX;
	}

	for(i = 0; i < (num_bytes + 1); i++)
	{
		if(i == 0) // Send address byte
			I2C0_D = slave_address << 1;
		else // Send data byte
			I2C0_D = buffer[i-1];

		// Wait for xfer to complete
		// TODO: Seems weird to poll for interrupt flag instead of
		// transfer complete flag, but it looks like the interrupt flag will
		// be set even if arb is lost, no ack sent, etc
		while (!(I2C0_S & I2C_S_IICIF)) 
			yield();
		I2C0_S = I2C_S_IICIF; // clear flag

		// Check for NACK
		stat = I2C0_S;
		if(stat & I2C_S_RXAK)
		{
			if(i == 0) // NACK on the address byte
				err_code = I2C_WRT_ERR_ADDR_NACK;
			else
				err_code = I2C_WRT_ERR_DATA_NACK;
			
			break; // don't try to send any more data
		}

		if(stat & I2C_S_ARBL)
		{
			err_code = I2C_WRT_ERR_LOST_ARB;

			// Clear arb lost flag
			I2C0_S = I2C_S_ARBL;

			break;
		}

	}

	// Send stop and reset I2C block
	I2C0_C1 = I2C_C1_IICEN;


	return err_code;
}


// Read bytes from slave device
uint8_t i2c_read(uint8_t slave_address, uint8_t max_bytes, uint8_t *buffer)
{
	uint8_t count = 0;
	uint8_t dummyread;
	uint8_t stat;

	if(max_bytes > I2C_RD_MAX_BYTES)
	{
		i2c_rx_err = I2C_RD_ERR_TOO_MANY_BYTES;
		return 0;
	}

	// Clear flags
	I2C0_S = I2C_S_IICIF | I2C_S_ARBL;

	// Grab the bus to send the address
	// If we're already the master, send a rep start,
	// otherwise, wait for the bus to clear, then send a start
	if(I2C0_C1 & I2C_C1_MST)
	{
		I2C0_C1 = I2C_C1_IICEN | I2C_C1_MST | I2C_C1_RSTA | I2C_C1_TX;
	}
	else
	{
		while(I2C0_S & I2C_S_BUSY)
		{
			yield();
		}

		I2C0_C1 = I2C_C1_IICEN | I2C_C1_MST | I2C_C1_TX;
	}

	// Send the address
	I2C0_D = (slave_address << 1) | 1;
	
	// Wait for xfer to complete
	while(!(I2C0_S & I2C_S_IICIF))
		yield();
	I2C0_S = I2C_S_IICIF;

	stat = I2C0_S;

	if(stat & I2C_S_RXAK)
	{
		I2C0_C1 = I2C_C1_IICEN; // Reset block
		i2c_rx_err = I2C_RD_ERR_ADDR_NACK;
		return 0;
	}

	if(stat & I2C_S_ARBL)
	{
		I2C0_C1 = I2C_C1_IICEN;
		i2c_rx_err = I2C_RD_ERR_LOST_ARB;
		return 0;
	}

	// Now actually read the bytes in
	if(max_bytes == 1)
	{
		I2C0_C1 = I2C_C1_IICEN | I2C_C1_MST | I2C_C1_TXAK;
	}
	else
	{
		I2C0_C1 = I2C_C1_IICEN | I2C_C1_MST;
	}

	dummyread = I2C0_D;

	while(max_bytes > 1)
	{
		// wait for data
		while(!(I2C0_S & I2C_S_IICIF))
			yield();
		I2C0_S = I2C_S_IICIF;

		max_bytes--;

		if(max_bytes == 1)
		{
			I2C0_C1 = I2C_C1_IICEN | I2C_C1_MST | I2C_C1_TXAK;
		}
		
		buffer[count] = I2C0_D;
		count++;
	}

	while(!(I2C0_S & I2C_S_IICIF))
		yield();
	I2C0_S = I2C_S_IICIF;

	I2C0_C1 = I2C_C1_IICEN | I2C_C1_MST | I2C_C1_TX;
	buffer[count] = I2C0_D;
	count++;
	I2C0_C1 = I2C_C1_IICEN;
	i2c_rx_err = 0;
	return count;
}

// Return read error
uint8_t i2c_get_read_err()
{
	return i2c_rx_err;
}
