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

#include "delay.h"

void wait_ms(XIOModule *inst, u32 time_ms)
{
	//u32 current_count;
	//u32 i;
	// Use timer 0
	u8 timer = 0;

	// Assume 100MHz clock (10 ns period, 100e3 clocks per ms)
	// timer is 32 bit, so make sure that we won't overflow the timer
	// when we multiply the wait time in ms by 100k.
	if(time_ms > 42949) // (2^32 - 1) / 100e3 = 4294967295 / 100e3 = 42949.6
	{
		print("\n\rError in wait_ms(): Parameter is too large and will overflow timer.\r\n");
		return;
	}

	u32 timer_reset_val = time_ms * 100000;
	/*
	print("timer reset val is: ");
	print_u32_hex(timer_reset_val);
	print("\n\r");
	*/

	// Stop timer (in case it's running)
	XIOModule_Timer_Stop(inst,timer);

	// Set timer reset val
	XIOModule_SetResetValue(inst,timer,timer_reset_val);

	// Set options to 0 (sets preload bit to 0, which turns off the
	// auto reload function).
	XIOModule_Timer_SetOptions(inst,timer,0);

	// Start the timer
	XIOModule_Timer_Start(inst,timer);

	// Wait for timer to expire before returning
	while(XIOModule_GetValue(inst,timer) != 0xFFFFFFFF)
	{
		// Do nothing
	}

	XIOModule_Timer_Stop(inst,timer);
}
