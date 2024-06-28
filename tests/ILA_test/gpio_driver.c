/*
 * Drives the GPIO with a pulse to simulate a detector hit
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xgpio.h"
#include "xparameters.h"


int main() {
	volatile int Delay;

	// initialize platform
    init_platform();
    print("Successfully started GPIO driver application");

    // Create GPIO driver instances for the PMOD pin (we treat it as output)
    XGpio out;

    // initialize GPIO driver
    XGpio_Initialize(&out, XPAR_AXI_GPIO_0_DEVICE_ID);

    // Data direction (input=1, output=0)
    XGpio_SetDataDirection(&out, 1, 1);

    while(1) {
    	// Write pin high for 20us
    	print("Sending pulse over GPIO\n\r");
    	XGpio_DiscreteWrite(&out, 1, 1);
    	usleep(20);
    	XGpio_DiscreteWrite(&out, 1, 0);
    	// sleep for 0.5s until next pulse
    	usleep(500000);
    }

}
