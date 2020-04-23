/**************************************************************************************************************************
By:                 Carlos Barrios
Date Created:       March 19, 2020
File name:          cabeee_Lab11_c1.c
Description:        Main C file for Lab 11. Combination of capacitive touch sensor, timer, and UART functionality.
                    The program starts up and gathers baseline measurements from the touch sensors.
                    Next it indicates that the center touch sensor should be pressed.
                    When this is pressed the program then indicates to the user that the up or down sensor should be pressed.
                        If Up pressed: samples will be displayed for 0.2 seconds each
                        If Down pressed: samples will be displayed for 0.5 seconds each
                    Next it indicates user should press left or right sensor.
                        If Right pressed: samples will be displayed on linear scale
                        If Left pressed: samples will be displayed on logarithmic scale (base 2)
                    The UART then reads 20 samples.
                    All samples are then converted to a linear or logarithmic scale.
                    Samples are then displayed in 0.2 or 0.5 second intervals on the CapTouch LEDs. Each time a new sample is
                    displayed the sample is sent over UART and displayed on a terminal on the PC.
                    At any point during the display loop the center touch sensor can be pressed to reset the program
                    to the start of the while(1) loop (waitForUpDown).
**************************************************************************************************************************/

#include <msp430g2553.h>

char UART_SW_FLAG;
int uartRxedChar;
int UART_samples[20];
int samp[20] = {369,237,127,48,6,4,43,119,226,356,498,641,774,887,969,1015,1020,986,913,808};

extern void setup(void);
extern void waitForCenter(void);
extern void waitForUpDown(void);
extern void waitForLeftRight(void);
extern void getSamples(void);
extern void convertSamples(void);
extern void displaySamples(void);

void main(void) {
    WDTCTL = WDTPW | WDTHOLD;   // stop watchdog timer
    setup();
    waitForCenter();
    while(1) {
        waitForUpDown();
        waitForLeftRight();
        //getSamples();             ;for debugging
        UART_setup();
        memcpy(UART_samples,samp,20);
        convertSamples();
        displaySamples();
    }
}


void UART_setup (void) {
    UCA0CTL0 = 0;
    UCA0CTL1 = 0;

    UCA0CTL1 |= UCSSEL1 + UCSSEL0;  // UCLK = SMLK ~1MHz
    UCA0STAT = 0;
    //UCA0STAT |= UCLISTEN;            // Loopback - used for debugging only
    UCA0BR0 = 0x68;                 // Set Baud Rate 9600
    UCA0BR1 = 0;                    // Baud Rate Cont.

    UCA0MCTL = 0x02;                // Modulation Control Register UCBRFx = 0, UCBRSx = 1, UCOS16 = 0
    //SW reset of the USI state machine
    UCA0CTL1 &= ~UCSWRST;
    UC0IE   |= UCA0RXIE;// Enable USART0 RX interrupt
    __bis_SR_register(GIE);
    while (IFG2 & UCA0TXIFG == 0);
    UCA0TXBUF = 'U';
}

void UART_newline(void) {
    while (IFG2 & UCA0TXIFG == 0);
    UCA0TXBUF = 0x0D;   // carriage return
    while (IFG2 & UCA0TXIFG == 0);
    UCA0TXBUF = 0x0A;   // newline
}

void getSamples (void) {
    char UART_count;
    char sampleNum;

    P1OUT &= ~0xF8;     // turn off all leds

    UART_setup();
    UART_newline();
    UART_SW_FLAG = 0;

    for (sampleNum = 0; sampleNum < 20; sampleNum++) {
        UART_samples[sampleNum] = 0;
        for (UART_count = 0; UART_count < 3; UART_count++) {
            while (UART_SW_FLAG == 0);
            UART_SW_FLAG = 0;
            if (uartRxedChar >= '0' && uartRxedChar <= '9') {
                uartRxedChar -= '0';
            }
            else if (uartRxedChar >= 'A' && uartRxedChar <= 'F') {
                uartRxedChar = uartRxedChar - 'A' + 10;
            }
            else if (uartRxedChar >= 'a' && uartRxedChar <= 'f') {
                uartRxedChar = uartRxedChar - 'a' + 10;
            }
            else if (uartRxedChar == 0x0D || uartRxedChar == 0x0A) {
                // ignore carriage return and newline
                sampleNum--;
                break;
            }
            else if (uartRxedChar == '$') {
                // start the entire 20 samples over again
                sampleNum = -1;
                break;
            }
            else {
                // unknown character entered, start this sample all over again (all 3 characters).
                sampleNum--;
                break;
            }
            switch (UART_count) {
                case 0:
                    uartRxedChar <<= 8;
                    break;
                case 1:
                    uartRxedChar <<= 4;
                    break;
                case 2:
                    //uartRxedChar <<= 0;
                    break;
                default:
                    break;
            }
            UART_samples[sampleNum] += uartRxedChar;
        }
    }
}

#pragma vector = USCIAB0RX_VECTOR
__interrupt void UART_RX_FFEE_ISR(void) {
    uartRxedChar = UCA0RXBUF;
    while (IFG2 & UCA0TXIFG == 0);
    UCA0TXBUF = uartRxedChar;
    UART_SW_FLAG = 1;
    return;
}
