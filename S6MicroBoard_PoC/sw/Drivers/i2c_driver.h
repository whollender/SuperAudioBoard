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

#ifndef I2C_DRIVER_H
#define I2C_DRIVER_H

#include "xiomodule.h"

/******************************************************************************
 * Registers
 ******************************************************************************/

/* The IO module commands automatically add 0xC0000000 to this, so 
 * it's really an offset from that. */
#define I2C_BASE_ADDR 		0x00040000u

/* Status and control reg */
#define I2C_STAT_CTRL 		(I2C_BASE_ADDR + 0x0u)
#define I2C_SC_MOD_EN 		(u32)0x1 /* Bit 0 */
#define I2C_SC_MOD_BUSY		(u32)0x2 /* Bit 1 */
#define I2C_SC_START_STR	(u32)0x4 /* Bit 2 */
#define I2C_SC_STOP_STR		(u32)0x8 /* Bit 3 */
#define I2C_SC_SEND_BYTE	(u32)0x10 /* Bit 4 */
#define I2C_SC_RECV_BYTE	(u32)0x20 /* Bit 5 */
#define I2C_SC_SEND_ACK_STR	(u32)0x40 /* Bit 6 */
#define I2C_SC_SEND_ACK		(u32)0x80 /* Bit 7 */
#define I2C_SC_RECV_ACK_STR	(u32)0x100 /* Bit 8 */
#define I2C_SC_ACK_RCVD		(u32)0x200 /* Bit 9 */

/* Divide ratio reg */
#define I2C_DIVIDE_RATIO	(I2C_BASE_ADDR + 0x4u)
#define I2C_DR_RATIO(x)		(u32)((x) & 0xFF)

/* Data out register */
#define I2C_DATA_OUT		(I2C_BASE_ADDR + 0x8u)

/* Data input register */
#define I2C_DATA_IN		(I2C_BASE_ADDR + 0xCu)



/******************************************************************************
 * Functions
 ******************************************************************************/

/* Set module divide ratio */
int I2C_SetDivideRatio(XIOModule *inst, u8 ratio);

/* Enable I2C interface */
int I2C_EnableInterface(XIOModule *inst);

/* Disable interface */
int I2C_DisableInterface(XIOModule *inst);

/* Wait for module to finish current command */
int I2C_WaitForModuleReady(XIOModule *inst);

/* Send start signal and hold bus */
int I2C_SendStart(XIOModule *inst);

/* Send stop signal and release bus */
int I2C_SendStop(XIOModule *inst);

/* Send byte */
int I2C_SendByte(XIOModule *inst, u8 data);

/* Receive byte */
u8 I2C_RecvByte(XIOModule *inst);

/* Send acknowledge or not-acknowledge */
int I2C_SendAck(XIOModule *inst, int sendAck);

/* Receive acknowledge */
int I2C_RecvAck(XIOModule *inst);

#endif
