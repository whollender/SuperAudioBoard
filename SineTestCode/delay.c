//////////////////////////////////////////////////////////////////////////
// delay.c
//
// delay() and micros() for when semi-accurate delays are necessary
// during execution.
// William Hollender, 5/1/14
//////////////////////////////////////////////////////////////////////////

#include "mk20dx128.h"
#include "delay.h"

extern void yield();

// the systick interrupt is supposed to increment this at 1 kHz rate
volatile uint32_t systick_millis_count = 0;

//uint32_t systick_current, systick_count, systick_istatus;  // testing only

uint32_t micros(void)
{
	uint32_t count, current, istatus;

	__disable_irq();
	current = SYST_CVR;
	count = systick_millis_count;
	istatus = SCB_ICSR;	// bit 26 indicates if systick exception pending
	__enable_irq();
	 //systick_current = current;
	 //systick_count = count;
	 //systick_istatus = istatus & SCB_ICSR_PENDSTSET ? 1 : 0;
	if ((istatus & SCB_ICSR_PENDSTSET) && current > 50) count++;
	current = ((F_CPU / 1000) - 1) - current;
	return count * 1000 + current / (F_CPU / 1000000);
}

void delay(uint32_t ms)
{
	uint32_t start = micros();

	if (ms > 0) {
		while (1) {
			if ((micros() - start) >= 1000) {
				ms--;
				if (ms == 0) return;
				start += 1000;
			}
			yield();
		}
	}
}

