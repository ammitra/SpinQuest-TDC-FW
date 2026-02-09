/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*
 * helloworld.c: simple test application for 16ch TDC 
 *
 * This application initializes the BRAM and GPIO drivers for the 16ch TDC test. 
 * There are two free-running counters in the PL which generate TDC hit pulses and 
 * a trigger signal, respectively. The TDC hit pulses are routed to the upper PMOD 
 * GPIO pins, which are connected to the lower pins by jumper wires. The lower pins
 * are connected to the 16ch TDC module for digitization. The pulses are generated
 * every 20us, and the second free-running counter generates a trigger pulse every 
 * 160us. There are 12 GPIO pins wired together, so we obtain the following data rate:
 *
 * (12 channels) * (8B / pulse) = 96B of data per set of pulses 
 * The trigger fires every 160us, which gives 8 pulses/trigger.
 * There are ~6250 triggers/s = 6.25kHz trigger rate.
 * (6250 triggers / s) * (8 pulses / trigger) * (96B data / pulse) = 4,800,000B/s = 4.8MBps
 * 
 * The TDC constantly digitizes the input pulses and writes them to one of two BRAMs.
 * Upon trigger accept, it ceases writing to the current BRAM and switches writing to the 
 * second BRAM, then sends an edge-triggered interrupt pulse to the PS along with sending out 
 * the ID of the BRAM *currently* being written to over GPIO. The PS receives the interrupt 
 * pulse and calls the ISR. The ISR performs the following operations:
 *      1. Asserts a busy flag over GPIO
 *      2. Checks the ID of the BRAM currently being written to, selects the other one to read from.
 *      3. Reads out the BRAM entirely (for now, prints to serial port).
 *      4. Deasserts the busy flag.
 *      5. Clears processor interrupt, resumes arbitrary code execution in wait for another trigger.
 *
 * 
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <xbram_hw.h>
#include <xil_io.h>
#include <xstatus.h>

#include "xgpio.h"
#include "xparameters.h"
#include "xparameters_ps.h"
#include "xil_assert.h"
#include "xil_exception.h"
#include "xbram.h"

#include "xscugic.h"

/* Driver pointers */
XGpio READ_BUSY;    // PS -> PL busy flag
XGpio WHICH_BRAM;   // PL -> PS BRAM ID value (01 or 10)
XBram BRAM_1;
XBram BRAM_2;
XBram_Config *BRAM_1_CFG;
XBram_Config *BRAM_2_CFG;

// Status trackers
int Status;

// IRQ handling
XScuGic         GIC;
XScuGic_Config  *GIC_CONFIG;
void ISR(void * CallBackRef);   // function prototype

void ISR(void * CallBackRef) {
    u32 IntIDFull;  // Used to clear the interrupt
    u64 bram_data;  // 64b data from the BRAM 

    // 1. Assert busy flag
    XGpio_DiscreteWrite(&READ_BUSY, 1, 0x1);

    // 2. Check ID of the BRAM currently being written to. Choose other BRAM for the ID
    u32 bram_id;
    bram_id = XGpio_DiscreteRead(&READ_BUSY, 1);
    u32 bram_addr;
    if (bram_id == 1) {
        bram_addr = XPAR_AXI_BRAM_2_CTRL_BASEADDR;   // misspelled "AXI" -> "AX" in the block design gg
    }
    else if (bram_id == 2) {
        bram_addr = XPAR_AXI_BRAM_1_CTRL_BASEADDR;
    }
    else {
        xil_printf("[ISR] ERROR: BRAM ID #%d invalid - expect ID = 1 or 2...\n\r",bram_id);
    }

    // Just read out from both BRAMs
    u32 bram1_addr = XPAR_AXI_BRAM_1_CTRL_BASEADDR;
    u32 bram2_addr = XPAR_AXI_BRAM_2_CTRL_BASEADDR;
    u64 bram1_data;
    u64 bram2_data;

    // 3. Read out the entire BRAM - print value at each address to serial port. 
    for (int i=0; i<8192; i=i+8) {    // 64b data words = 8 bytes, increment address by 8 (byte addressing)
        // bram_data = XBram_ReadReg(bram_addr, i);
        // printf("BRAM %u : addr  %d\t 0x%lx\n\r",bram_id, i, bram_data);
        // fflush (stdout); 

        bram1_data = XBram_ReadReg(bram1_addr, i);
        bram2_data = XBram_ReadReg(bram2_addr, i);
        printf("BRAM 1 : addr  %d\t 0x%lx\n\r",i, bram1_data);
        printf("BRAM 2 : addr  %d\t 0x%lx\n\r",i, bram2_data);
        fflush (stdout);
    }

    usleep(5);

    // 4. Deassert busy flag
    XGpio_DiscreteWrite(&READ_BUSY, 1, 0x0);

    // 5. Clear the interrupt flag
    IntIDFull = XScuGic_CPUReadReg(&GIC, XSCUGIC_INT_ACK_OFFSET);
    XScuGic_CPUWriteReg(&GIC, XSCUGIC_EOI_OFFSET, IntIDFull);
}



int main()
{
    init_platform();

    print("Starting 4ch TDC test program...\n\r");
    print("Initializing GPIO and BRAM drivers...\n\r");
    // Initialize GPIO - READ_BUSY
    Status = XGpio_Initialize(&READ_BUSY, XPAR_READ_BUSY_BASEADDR);
    if (Status != XST_SUCCESS) {
        xil_printf("Busy GPIO initialization failed\r\n");
        return XST_FAILURE;
    }
    else {
        xil_printf("Busy GPIO initialization succeeded\r\n");
    }
    // Initialize GPIO - WHICH_BRAM
    Status = XGpio_Initialize(&WHICH_BRAM, XPAR_WHICH_BRAM_BASEADDR);
    if (Status != XST_SUCCESS) {
        xil_printf("BRAM selector GPIO initialization failed\r\n");
        return XST_FAILURE;
    }
    else {
        xil_printf("BRAM selector GPIO initialization succeeded\r\n");
    }
    // Data Direction Reg (input is 1, output is 0)
    XGpio_SetDataDirection(&WHICH_BRAM, 1, 1);
    XGpio_SetDataDirection(&READ_BUSY, 1, 0);
    // BRAM 1 initialization
    BRAM_1_CFG = XBram_LookupConfig(XPAR_AXI_BRAM_1_CTRL_BASEADDR);
    if (BRAM_1_CFG == (XBram_Config *) NULL) {
        xil_printf("BRAM 1 Config lookup failed\r\n");
        return XST_FAILURE;
    }
    else {
        xil_printf("BRAM 1 Config lookup succeeded\r\n");
    }
        Status = XBram_CfgInitialize(&BRAM_1, BRAM_1_CFG,
                                     BRAM_1_CFG->CtrlBaseAddress);
    if (Status != XST_SUCCESS) {
        xil_printf("BRAM 1 initialization failed\r\n");
        return XST_FAILURE;
    }
    else {
        xil_printf("BRAM 1 initialization succeeded\r\n");
    }
    // BRAM 2 initialization
    BRAM_2_CFG = XBram_LookupConfig(XPAR_AXI_BRAM_2_CTRL_BASEADDR);
    if (BRAM_2_CFG == (XBram_Config *) NULL) {
        xil_printf("BRAM 2 Config lookup failed\r\n");
        return XST_FAILURE;
    }
    else {
        xil_printf("BRAM 2 Config lookup succeeded\r\n");
    }
        Status = XBram_CfgInitialize(&BRAM_2, BRAM_2_CFG,
                                     BRAM_2_CFG->CtrlBaseAddress);
    if (Status != XST_SUCCESS) {
        xil_printf("BRAM 2 initialization failed\r\n");
        return XST_FAILURE;
    }
    else {
        xil_printf("BRAM 2 initialization succeeded\r\n");
    }
    print("Finished nitializing GPIO and BRAM drivers...\n\r");

    print("Initializing interrupt handler...\n\r");
    // Look up the config information for the GIC
    GIC_CONFIG = XScuGic_LookupConfig(XPAR_SCUGIC_SINGLE_DEVICE_ID);
    if (NULL == GIC_CONFIG) {
        return XST_FAILURE;
    }
    // Initialize the GIC using the config information
    Status = XScuGic_CfgInitialize(&GIC, GIC_CONFIG, GIC_CONFIG->CpuBaseAddress);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }
    // Set interrupt priority and rising edge trigger
    XScuGic_SetPriorityTriggerType(&GIC, XPS_FPGA0_INT_ID, 0xA0, 0x3);
    // Connect interrupt controller to ARM interrupt handling logic
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler)XScuGic_InterruptHandler, &GIC);
    Xil_ExceptionEnable();
    // Connect interrupt handler
    Status = XScuGic_Connect(&GIC, XPS_FPGA0_INT_ID, (Xil_InterruptHandler)ISR, NULL);
    if (Status != XST_SUCCESS) {
        return XST_FAILURE;
    }
    // Enable device interrupt
    XScuGic_Enable(&GIC,XPS_FPGA0_INT_ID);

    // Idle awaiting trigger
    while(TRUE) {
        sleep(5);
        print("PS idle\n\r");
    }


    cleanup_platform();
    return 0;
}