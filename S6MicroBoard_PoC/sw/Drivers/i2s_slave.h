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

#ifndef I2S_SLAVE_H
#define I2S_SLAVE_H

#include "XIOModule.h"

#define I2S_ADDR_OFFSET 0x00080000u
#define I2S_STATUS (I2S_ADDR_OFFSET + 0x0u)
#define I2S_TX_R (I2S_ADDR_OFFSET + 0x4u)
#define I2S_TX_L (I2S_ADDR_OFFSET + 0x8u)
#define I2S_RX_R (I2S_ADDR_OFFSET + 0xCu)
#define I2S_RX_L (I2S_ADDR_OFFSET + 0x10u)

void waitForI2SData(XIOModule *inst);

#endif

