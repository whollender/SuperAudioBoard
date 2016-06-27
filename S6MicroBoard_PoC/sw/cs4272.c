/*
 * Copyright (c) 2016 RF William Hollender
 *
 * Permission is hereby granted, free of charge,
 * to any person obtaining a copy of this software
 * and associated documentation files (the "Software"),
 * to deal in the Software without restriction,
 * including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit
 * persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission
 * notice shall be included in all copies or
 * substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY
 * OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
 * NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 */

#include "cs4272.h"
#include "i2c_driver.h"
#include "delay.h"


// Setup I2C address for codec
#define CODEC_ADDR 0x10 // TODO: need to double check

#define GPIO_RESET_CHANNEL 1
#define GPIO_RESET_PIN 0

void codec_write(XIOModule *inst, uint8_t reg, uint8_t data)
{
	// For CS4272 all data is written between single
	// start/stop sequence

	uint8_t addr = CODEC_ADDR << 1;

	int ackRecvd;

	I2C_SendStart(inst);
	I2C_WaitForModuleReady(inst);
	
	I2C_SendByte(inst,addr);
	I2C_WaitForModuleReady(inst);

	ackRecvd = I2C_RecvAck(inst);

	if(ackRecvd != 1)
	{
		I2C_SendStop(inst);
		I2C_WaitForModuleReady(inst);
		print("Codec did not acknowledge address byte.\r\n");
		return;
	}

	I2C_SendByte(inst,reg);
	I2C_WaitForModuleReady(inst);

	ackRecvd = I2C_RecvAck(inst);

	if(ackRecvd != 1)
	{
		I2C_SendStop(inst);
		I2C_WaitForModuleReady(inst);
		print("Codec did not acknowledge register address byte.\r\n");
		return;
	}

	I2C_SendByte(inst,data);
	I2C_WaitForModuleReady(inst);

	ackRecvd = I2C_RecvAck(inst);

	if(ackRecvd != 1)
	{
		I2C_SendStop(inst);
		I2C_WaitForModuleReady(inst);
		print("Codec did not acknowledge data byte.\r\n");
		return;
	}

	I2C_SendStop(inst);
	I2C_WaitForModuleReady(inst);

}

uint8_t codec_read(XIOModule *inst, uint8_t reg)
{
	// No waveform demo for read,
	// so assume first write MAP,
	// then rep-start (or stop and start),
	// the read
	
	uint8_t buf;

	uint8_t addr = (CODEC_ADDR << 1);

	int ackRecvd;

	// Send register address
	I2C_SendStart(inst);
	I2C_WaitForModuleReady(inst);
	
	I2C_SendByte(inst,addr);
	I2C_WaitForModuleReady(inst);

	ackRecvd = I2C_RecvAck(inst);

	if(ackRecvd != 1)
	{
		I2C_SendStop(inst);
		I2C_WaitForModuleReady(inst);
		print("Codec did not acknowledge address byte.\r\n");
		return 0;
	}

	I2C_SendByte(inst,reg);
	I2C_WaitForModuleReady(inst);

	ackRecvd = I2C_RecvAck(inst);

	if(ackRecvd != 1)
	{
		I2C_SendStop(inst);
		I2C_WaitForModuleReady(inst);
		print("Codec did not acknowledge register address byte.\r\n");
		return 0;
	}

	// Read byte
	addr = (CODEC_ADDR << 1) | 1;
	I2C_SendStart(inst);
	I2C_WaitForModuleReady(inst);
	
	I2C_SendByte(inst,addr);
	I2C_WaitForModuleReady(inst);

	ackRecvd = I2C_RecvAck(inst);

	if(ackRecvd != 1)
	{
		I2C_SendStop(inst);
		I2C_WaitForModuleReady(inst);
		print("Codec did not acknowledge address byte.\r\n");
		return 0;
	}

	buf = I2C_RecvByte(inst);

	I2C_SendAck(inst,0);
	I2C_WaitForModuleReady(inst);

	I2C_SendStop(inst);
	I2C_WaitForModuleReady(inst);

	return buf;
}

void codec_init(XIOModule *inst)
{
	// Setup Initial Codec
	
	// Initialize I2C
	I2C_SetDivideRatio(inst,250u);
	wait_ms(inst, 1);
	I2C_EnableInterface(inst);
	wait_ms(inst, 100);

	// Setup Reset pin (GPIO)
	// Right now assuming that we're using Teensy pin 2
	// which is Port D pin 0
	
	u32 mask = 1 << GPIO_RESET_PIN;
	XIOModule_DiscreteClear(inst, 1, 1);

	wait_ms(inst, 1);
	
	// Release Reset (drive pin high)
	XIOModule_DiscreteSet(inst, 1, 1);
	
	// Wait for ~2-5ms (1-10 ms time window spec'd in datasheet)
	wait_ms(inst, 2);
	
	// Set power down and control port enable as spec'd in the 
	// datasheet for control port mode
	codec_write(inst, CODEC_MODE_CTRL2, CODEC_MODE_CTRL2_POWER_DOWN
			| CODEC_MODE_CTRL2_CTRL_PORT_EN);
	
	// Further setup
	wait_ms(inst, 1);

	// Set ratio select for MCLK=512*LRCLK (BCLK = 64*LRCLK), and master mode
	codec_write(inst, CODEC_MODE_CONTROL, CODEC_MC_RATIO_SEL(3) | CODEC_MC_MASTER_SLAVE);

	wait_ms(inst, 10);
	
	// Release power down bit to start up codec
	// TODO: May need other bits set in this reg
	codec_write(inst, CODEC_MODE_CTRL2, CODEC_MODE_CTRL2_CTRL_PORT_EN);
	
	// Wait for everything to come up
	wait_ms(inst, 10);
}
