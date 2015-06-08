/******************************************************************************
* Sine loopback test for SuperAudioBoard
* 
* i2c.h
*
* Functions to set up, write to, and read from i2c bus as master only.
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

#ifndef I2C_H
#define I2C_H

#include <inttypes.h>

// Initialize I2C block
void i2c_init();

// Write bytes to slave device, return >0 if error condition
uint8_t i2c_write(uint8_t slave_address, uint8_t num_bytes, const uint8_t *buffer);

// Possible write error condition
#define I2C_WRT_MAX_BYTES          32 // max number of bytes to tx
#define I2C_WRT_ERR_TOO_MANY_BYTES 1  // num_bytes is larger than MAX_BYTES
#define I2C_WRT_ERR_ADDR_NACK      2  // slave NACK on address tx
#define I2C_WRT_ERR_DATA_NACK      4  // slave NACK on data tx
#define I2C_WRT_ERR_LOST_ARB       8  // We lost arbitration to another master (should never happen)

// Read bytes from slave, returning the number of bytes received
uint8_t i2c_read(uint8_t slave_address, uint8_t max_bytes, uint8_t *buffer);

// i2c_read can't return an error code, so need to store it off and read
// it back with a separate function
uint8_t i2c_get_read_err();

// Read error conditions (probably the same as write error conditions)
#define I2C_RD_MAX_BYTES           32
#define I2C_RD_ERR_TOO_MANY_BYTES  1
#define I2C_RD_ERR_ADDR_NACK       2
#define I2C_RD_ERR_LOST_ARB        4



#endif
