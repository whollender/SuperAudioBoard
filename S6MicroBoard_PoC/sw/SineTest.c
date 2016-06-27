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

#include <stdio.h>
#include "platform.h"
#include "cs4272.h"
#include "delay.h"
#include "i2s_slave.h"
#include "sine_samples.h"

#define MAX_INPUT_LEN 4096

#define SERIAL_INPUT_BUFFER_LEN 32

int32_t input_buffer[MAX_INPUT_LEN];

char serialInputBuffer[SERIAL_INPUT_BUFFER_LEN];

XIOModule iomod_inst;

void print(char *str);

void print_u32_hex(u32 val);

u8 serial_read_line(char* buf, u8 max_len);

void clearInpBuffer(void);

typedef enum
{
	Left,
	Right,
} Channel;

Channel selectedChannel;

void RunSineTest(void);

int main()
{
    init_platform();

    XIOModule_Initialize(&iomod_inst, 0);

    wait_ms(&iomod_inst,1000);

    codec_init(&iomod_inst);

    wait_ms(&iomod_inst,1000);
    print("Codec Initialized\r\n");
    print("Reading back registers\r\n");

    int i;
    uint8_t regData;
    for(i = 1; i < 9; i++)
    {
    	regData = codec_read(&iomod_inst,i);
    	print("Address ");
    	print_u32_hex((u32)i);
    	print(" ");
    	print_u32_hex((u32)regData);
    	print("\r\n");
    }

    print("Waiting 5 seconds for codec HPF to stabilize...\r\n");

    wait_ms(&iomod_inst,5000);

    u8 numCharsRet;

    clearInpBuffer();

    while(1)
    {
    	print("Please select the channel (L/R)\r\n> ");
    	numCharsRet = serial_read_line(serialInputBuffer,SERIAL_INPUT_BUFFER_LEN);

    	if(numCharsRet > 0)
    	{
    		if((serialInputBuffer[0] == 'l') || (serialInputBuffer[0] == 'L'))
    		{
    			selectedChannel = Left;
    			break;
    		}
    		else if((serialInputBuffer[0] == 'r') || (serialInputBuffer[0] == 'R'))
    		{
    			selectedChannel = Right;
    			break;
    		}
    	}

    	print("Invalid channel selection.\r\n");
    }
    clearInpBuffer();

    RunSineTest();


    for(i = 0; i < MAX_INPUT_LEN; i++)
    {
    	xil_printf("%d\r\n",input_buffer[i]);
    }

    print("End of samples\r\n");


    return 0;
}

void print_u32_hex(u32 val)
{
	char c[2];
	u8 i;
	u8 temp_val;

	for(i = 0; i < 8; i++)
	{
		temp_val = (u8)((val >> (28 - 4*i)) & 0x0f);
		if(temp_val < 10)
			c[0] = (char)(temp_val + 0x30);
		else
			c[0] = (char)(temp_val + 0x37);

		c[1] = '\0';

		print(c);
	}
}

u8 serial_read_line(char* buf, u8 max_len)
{
    u8 ret;
    u8 num_chars = 0;

    while(num_chars < max_len)
    {
        ret = XIOModule_RecvByte(STDIN_BASEADDRESS);
        if(ret == -1)
        {

        }
        else
        {
            if(ret == '\n')
            {
                return num_chars;
            }
            else
            {
                buf[num_chars] = ret;
                num_chars++;
            }
        }
    }

    return num_chars;
}

void clearInpBuffer(void)
{
	int i;
	for(i = 0; i < SERIAL_INPUT_BUFFER_LEN; i++)
	{
		serialInputBuffer[i] = '\0';
	}
}

void RunSineTest(void)
{

    print("Starting Sine test...\r\n");

    // Zero out input array
    int i;
    for(i = 0; i < MAX_INPUT_LEN; i++)
    {
    	input_buffer[i] = 0;
    }

    int extraSamples = MAX_INPUT_LEN % SINE_LENGTH;
    int maxInputSamples = MAX_INPUT_LEN - extraSamples;

    uint8_t outputIdx = 0;
    uint8_t firstRound = 1;
    uint32_t inputIdx = 0;

    while(1)
    {
    	waitForI2SData(&iomod_inst);

    	// Write output samples and read input samples
        if(selectedChannel == Right)
        {
            XIOModule_IoWriteWord(&iomod_inst,I2S_TX_L,0);
            XIOModule_IoWriteWord(&iomod_inst,I2S_TX_R,(sineBuf[outputIdx] << 8));

            XIOModule_IoReadWord(&iomod_inst,I2S_RX_L);
            input_buffer[inputIdx] = ((int32_t)XIOModule_IoReadWord(&iomod_inst,I2S_RX_R)) >> 8;
        }
        else
        {
            XIOModule_IoWriteWord(&iomod_inst,I2S_TX_L,(sineBuf[outputIdx] << 8));
            XIOModule_IoWriteWord(&iomod_inst,I2S_TX_R,0);

            input_buffer[inputIdx] = ((int32_t)XIOModule_IoReadWord(&iomod_inst,I2S_RX_L)) >> 8;
            XIOModule_IoReadWord(&iomod_inst,I2S_RX_R);
        }

    	// Increment indices
    	outputIdx++;
    	if(outputIdx == SINE_LENGTH)
    	{
    		outputIdx = 0;
    	}

    	inputIdx++;
    	if(inputIdx == maxInputSamples)
    	{
    		inputIdx = 0;

    		if(firstRound == 1)
    			firstRound = 0;
    		else
    			break;
    	}

    }

    print("Test finished, printing samples.\r\n");
}


