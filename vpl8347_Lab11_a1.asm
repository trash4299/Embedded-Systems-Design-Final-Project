
	.cdecls C,LIST,"msp430g2553.h"

;Constants
LED0		.equ	0x01	;for a single LED on
LED1		.equ	0x10
LED2		.equ	0x20
LED3		.equ	0x40
LED4		.equ	0x80
LED5		.equ	0xe8
LED6		.equ	0xd8
LED7		.equ	0xb8
LED8		.equ	0x78

LEDs0		.equ	0x00	;for multiple LEDs on
LEDs1		.equ	0x10
LEDs2		.equ	0x30
LEDs3		.equ	0x70
LEDs4		.equ	0xf0
LEDs5		.equ	0xe8
LEDs6		.equ	0xc8
LEDs7		.equ	0x88
LEDs8		.equ	0x08

;Global functions
		.global setup
		.global waitForCenter
		.global waitForUpDown
		.global waitForLeftRight
		.global getSamples
		.global convertSamples
		.global displaySamples
		.global UART_samples

;Variables
		.data
		.bss	meas_base, 10
		.bss	meas_latest, 10
		.bss	sensor_status, 1
		.bss	SWdelay, 1
		.bss	conArray, 20	;num of LEDs to light up (0-8) for each sample

;Subroutines
		.text
setup:
		bis.b	#0xf9, &P1DIR	; set up P1 as outputs
		bic.b	#0xf9, &P1OUT	; P1 outputs 0
		bis.b 	#0x6, &P1SEL 	; P1.2/P1.1 = USART0 TXD/RXD
		bis.b 	#0x6, &P1SEL2 	; P1.2/P1.1 = USART0 TXD/RXD
		mov.b	#0x1a, SWdelay
		call	#meas_base_val
		mov.b	#0xdf, SWdelay
		ret

meas_setup:
			bic.b 	R5, &P2DIR 				; Setup P2.x to pin oscillation mode
			bic.b 	R5, &P2SEL
			bis.b 	R5, &P2SEL2
		 	mov 	#TASSEL_3, &TA0CTL 		; The oscillation from P2.x is driving INCLK input of TA0
			mov 	#CM_3 + CCIS_2 + CAP, &TA0CCTL1
			ret

waitForCenter:
			mov.b	#0xdf, SWdelay
			mov		#LED0, P1OUT
			call 	#SWtimer
			mov		#0, P1OUT
			call 	#SWtimer
			mov		#LED0, P1OUT
			call 	#SWtimer
			mov		#0, P1OUT
			call 	#SWtimer
			mov		#LED0, P1OUT
			call 	#SWtimer
			mov		#0, P1OUT
			call 	#SWtimer
			mov		#LED0, P1OUT
			call 	#SWtimer
			mov		#0, P1OUT
			call 	#SWtimer

			mov.b	#0x1a, SWdelay
meas1		call	#meas_latest_val
			call 	#det_sensor
			call	#display
			mov 	#0x8, r14
			cmp.w	meas_latest(R14), meas_base(R14)
			jge		endwait1
			jmp		meas1
endwait1	ret

waitForUpDown:
			mov.b	#0xdf, SWdelay
			mov		#LED1, P1OUT
			call 	#SWtimer
			mov		#LED4, P1OUT
			call 	#SWtimer
			mov		#LED1, P1OUT
			call 	#SWtimer
			mov		#LED4, P1OUT
			call 	#SWtimer
			mov		#LED1, P1OUT
			call 	#SWtimer
			mov		#LED4, P1OUT
			call 	#SWtimer
			mov		#LED1, P1OUT
			call 	#SWtimer
			mov		#LED4, P1OUT
			call 	#SWtimer
			clr		P1OUT
			call 	#SWtimer

			mov.b	#0x1a, SWdelay
meas2		call	#meas_latest_val
			call 	#det_sensor
			call	#display
			mov 	#0x6, r14
			cmp		meas_latest(r14), meas_base(r14)
			jge		endwait2a
			mov 	#0x2, r14
			cmp		meas_latest(r14), meas_base(r14)
			jge		endwait2b
			jmp		meas2
endwait2a	mov		#0, r13
			ret
endwait2b	mov		#1, r13
			ret

waitForLeftRight:
			mov.b	#0xdf, SWdelay
			mov		#LED3, P1OUT
			call 	#SWtimer
			mov		#LED7, P1OUT
			call 	#SWtimer
			mov		#LED3, P1OUT
			call 	#SWtimer
			mov		#LED7, P1OUT
			call 	#SWtimer
			mov		#LED3, P1OUT
			call 	#SWtimer
			mov		#LED7, P1OUT
			call 	#SWtimer
			mov		#LED3, P1OUT
			call 	#SWtimer
			mov		#LED7, P1OUT
			call 	#SWtimer
			clr		P1OUT
			call 	#SWtimer

			mov.b	#0x1a, SWdelay
meas3		call	#meas_latest_val
			call 	#det_sensor
			call	#display
			mov 	#0x0, r14
			cmp		meas_latest(r14), meas_base(r14)
			jge		endwait3a
			mov 	#0x4, r14
			cmp		meas_latest(r14), meas_base(r14)
			jge		endwait3b
			jmp		meas3
endwait3a	clr		P1OUT
			bis		#2, r13
			ret
endwait3b	clr		P1OUT
;bic		#2, r13			;this bit will be set because of mov in waitForUpDown
			ret

convertSamples:
			mov		#0, r10		; loop counter and conArray index
			mov		#0, r11		; UART_samples index
			cmp		#2, r13		; checks lin or log
			jge		conlin
conlog		mov.b	#8, conArray(r10)
			;bic		#0x0003, UART_samples(r11)		;not needed because i switched to jge

			cmp		#1000000000b, UART_samples(r11)
			jge		next
			dec.b	conArray(r10)
			cmp		#0100000000b, UART_samples(r11)
			jge		next
			dec.b	conArray(r10)
			cmp		#0010000000b, UART_samples(r11)
			jge		next
			dec.b	conArray(r10)
			cmp		#0001000000b, UART_samples(r11)
			jge		next
			dec.b	conArray(r10)
			cmp		#0000100000b, UART_samples(r11)
			jge		next
			dec.b	conArray(r10)
			cmp		#0000010000b, UART_samples(r11)
			jge		next
			dec.b	conArray(r10)
			cmp		#0000001000b, UART_samples(r11)
			jge		next
			dec.b	conArray(r10)
			cmp		#0000000100b, UART_samples(r11)
			jge		next
			dec.b	conArray(r10)
			;cmp		#0000000000b, UART_samples(r11)		;don't need because if here then it will fit case
			jmp		next
conlin		mov.b	#1, conArray(r10)
			bic		#0x007f, UART_samples(r11)

			cmp		#0x0000, UART_samples(r11)
			jeq		next
			inc.b	conArray(r10)
			cmp		#0x0080, UART_samples(r11)
			jeq		next
			inc.b	conArray(r10)
			cmp		#0x0100, UART_samples(r11)
			jeq		next
			inc.b	conArray(r10)
			cmp		#0x0180, UART_samples(r11)
			jeq		next
			inc.b	conArray(r10)
			cmp		#0x0200, UART_samples(r11)
			jeq		next
			inc.b	conArray(r10)
			cmp		#0x0280, UART_samples(r11)
			jeq		next
			inc.b	conArray(r10)
			cmp		#0x0300, UART_samples(r11)
			jeq		next
			inc.b	conArray(r10)
			;cmp		#0x0380, UART_samples(r11)		;it should never reach here
			;jeq		next
next		incd	r11
			inc		r10
			cmp		#0x14, r10
			jne		conlin
			ret

displaySamples:																		;ADD IN CENTER BUTTON AS ESCAPE AND DOUBLE CHECK LED POSITIONS FOR ARRAY
			mov.b	#0x1a, SWdelay
			mov		#0, r15		; reload boolean
			bic		#2, r13
			mov		#TASSEL_1 + ID_0 + TAIE, &TA0CTL
			mov		#CCIE, &TACCTL0
twoorfive	cmp		#1, r13		; checks "sample rate"
			jeq		five

			mov		#0x1900, &TACCR0
			EINT							;might not be needed because maybe in c file
			jmp		restart
five		mov		#0x3e80, &TACCR0
			EINT							;might not be needed because maybe in c file

restart		mov		#0, r10		; loop counter and conArray index
oneormore	cmp.b	#5, conArray(r10)
			bis		#MC_1, &TA0CTL
			jge		morea

one			cmp		#1, r15
			jeq		reload
			mov		conArray(r10), r5
			mov		LEDs0(r5), P1OUT
			jmp		one
morea		cmp		#1, r15
			jeq		reload
			mov		#LEDs4, P1OUT
moreb		call	#meas_latest_val					;maybe take this out if slows down lights too much
			mov 	#0x8, r14
			cmp.w	meas_latest(R14), meas_base(R14)
			jge		endDisplay
			mov.b	conArray(r10), r5
			mov		LEDs0(r5), P1OUT
			jmp		morea

reload		call	#meas_latest_val
			mov 	#0x8, r14
			cmp.w	meas_latest(R14), meas_base(R14)
			jge		endDisplay
			mov		#0, r15
			inc		r10
			cmp		#0x14, r10
			jeq		restart
			jmp		oneormore
endDisplay	bis		#MC0, &TA0CTL
			clr		P1OUT
			ret

meas_base_val:
			mov.b	#0x02, R5	; initialize R5 to point to P2.x
			mov.b	#0x00, R6	; initialize R6 to the base of meas_base
meas_base_again
			call 	#meas_setup
			bis 	#MC_2 + TACLR, &TA0CTL
			call	#SWtimer				;provide the accumulation period.could use ACLK fed from VLO instead
			xor		#CCIS0, &TA0CCTL1		;capture trigger by toggeling CCIS0
			mov		TA0CCR1, meas_base(R6)
			bic 	#MC1+MC0, &TA0CTL
			sub 	#0x20, meas_base(R6)	; Adjust this baseline
			bic.b 	R5,&P2SEL2				; Stop the oscillation on the latest. pin
			rla.b	R5						; Prepare next x
			add.b	#0x02, R6				; Prepare the next index into the array
			cmp.b	#0x40, R5				; Check if done with all five sensors
			jne		meas_base_again
			ret

meas_latest_val:
			mov.b	#0x02, R5		; initialize R5 to point to P2.1
			mov.b	#0x00, R6		; initialize R6 to the base of meas_base
meas_latest_again
			call 	#meas_setup
			bis 	#MC_2 + TACLR, &TA0CTL
			call	#SWtimer
			xor		#CCIS0, &TA0CCTL1			; Trigger SW capture
			mov 	TA0CCR1, meas_latest(R6)	; Save captured value in array
			bic 	#MC1+MC0, &TA0CTL
			bic.b 	R5,&P2SEL2					; Stop the oscillation on the latest pin
			rla.b	R5							; Prepare next x
			add.b	#0x02, R6					; Prepare the next index into the array
			cmp.b	#0x40, R5					; Check if done with all five sensors
			jne		meas_latest_again
			ret

det_sensor:	clr.b	sensor_status
			mov.b	#0x02, R5		; initialize R5 to point to P2.1
			mov.b	#0x00, R6		; initialize R6 to the base of meas_base
CheckNextSensor
			cmp		meas_latest(R6), meas_base(R6)
			jl		NotThisSensor
			bis.b	R5, sensor_status
NotThisSensor
			rla.b	R5					; Prepare next x
			add.b	#0x02, R6			; Prepare the next index into the array
			cmp.b	#0x40, R5			; Check if done with all five sensors
			jne		CheckNextSensor
			ret

display:
checkmid	cmp.b 	#0x20, sensor_status
			jl		checkup
			mov 	#LED0, P1OUT
			ret
checkup		cmp.b	#0x10, sensor_status
			jl		checkrit
			mov 	#LED5, P1OUT
			ret
checkrit	cmp.b	#0x08, sensor_status
			jl		checkdwn
			mov 	#LED8, P1OUT
			ret
checkdwn	cmp.b	#0x04, sensor_status
			jl		checklef
			mov 	#LED4, P1OUT
			ret
checklef	cmp.b	#0x02, sensor_status
			jl		checknon
			mov 	#LED1, P1OUT
			ret
checknon	mov 	#0x00, P1OUT
			ret

SWtimer:
			mov.b	SWdelay, r8			; The total SW delay count = SWdelay * SWdelay
Reloadr7	mov.b	SWdelay, r7
ISr70		dec		r7
			jnz		ISr70
			dec		r8
			jnz		Reloadr7
			ret
;ISR
T0_A0_ISR:	bic.w	#TAIFG ,&TA0CTL		; this code runs when 	TAR = TACCR0
			bic.w 	#CCIFG, &TACCTL0
			mov		#1, r15
Skip		reti

;Interrupt Vectors
            .sect   ".int09"        ; T0_A0 Vector (0xFFF2) - 1 source (CCIE on CCR0)
isr_T0_A0:  .short  T0_A0_ISR       ; T0_A0 ISR address
.end
