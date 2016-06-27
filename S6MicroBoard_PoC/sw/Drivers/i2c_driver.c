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

#include "i2c_driver.h"

/* Set module divide ratio */
int I2C_SetDivideRatio(XIOModule *inst, u8 ratio)
{
    	XIOModule_IoWriteWord(inst,I2C_DIVIDE_RATIO,I2C_DR_RATIO(ratio));
	return 0;
}

/* Enable I2C interface */
int I2C_EnableInterface(XIOModule *inst)
{
    	XIOModule_IoWriteWord(inst,I2C_STAT_CTRL,I2C_SC_MOD_EN);
	return 0;
}

/* Disable interface */
int I2C_DisableInterface(XIOModule *inst)
{
   	XIOModule_IoWriteWord(inst,I2C_STAT_CTRL,0x0u);
	return 0;
}

/* Wait for module to finish current command */
int I2C_WaitForModuleReady(XIOModule *inst)
{
	u32 curr_stat = XIOModule_IoReadWord(inst,I2C_STAT_CTRL);
	while((curr_stat & I2C_SC_MOD_BUSY) != 0)
	{
		curr_stat = XIOModule_IoReadWord(inst,I2C_STAT_CTRL);
	}
	return 0;
}

/* Send start signal and hold bus */
int I2C_SendStart(XIOModule *inst)
{
   	XIOModule_IoWriteWord(inst, I2C_STAT_CTRL, I2C_SC_START_STR | I2C_SC_MOD_EN);
	return 0;
}

/* Send stop signal and release bus */
int I2C_SendStop(XIOModule *inst)
{
   	XIOModule_IoWriteWord(inst, I2C_STAT_CTRL, I2C_SC_STOP_STR | I2C_SC_MOD_EN);
	return 0;
}

/* Send byte */
int I2C_SendByte(XIOModule *inst, u8 data)
{
   	XIOModule_IoWriteWord(inst, I2C_DATA_OUT, (u32)data);
   	XIOModule_IoWriteWord(inst, I2C_STAT_CTRL, I2C_SC_SEND_BYTE | I2C_SC_MOD_EN);
	return 0;
}

/* Receive byte */
u8 I2C_RecvByte(XIOModule *inst)
{
   	XIOModule_IoWriteWord(inst, I2C_STAT_CTRL, I2C_SC_RECV_BYTE | I2C_SC_MOD_EN);

	I2C_WaitForModuleReady(inst);

	u32 data_rcvd = XIOModule_IoReadWord(inst,I2C_DATA_IN);

	return (u8)(data_rcvd & 0xFF);
}

/* Send acknowledge or not-acknowledge */
int I2C_SendAck(XIOModule *inst, int sendAck)
{
	if (sendAck == 1)
		XIOModule_IoWriteWord(inst, I2C_STAT_CTRL, I2C_SC_SEND_ACK | I2C_SC_SEND_ACK_STR | I2C_SC_MOD_EN);
	else
		XIOModule_IoWriteWord(inst, I2C_STAT_CTRL, I2C_SC_SEND_ACK_STR | I2C_SC_MOD_EN);

	return 0;
}

/* Receive acknowledge */
int I2C_RecvAck(XIOModule *inst)
{
   	XIOModule_IoWriteWord(inst, I2C_STAT_CTRL, I2C_SC_RECV_ACK_STR | I2C_SC_MOD_EN);

	I2C_WaitForModuleReady(inst);

	u32 data_rcvd = XIOModule_IoReadWord(inst,I2C_STAT_CTRL);

	if ((data_rcvd & I2C_SC_ACK_RCVD) > 0)
		return 1;
	else
		return 0;
}
