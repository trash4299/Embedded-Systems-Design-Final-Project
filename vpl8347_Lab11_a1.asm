
	.cdecls C,LIST,"msp430g2553.h"       ; Include device header file

LED0		.equ	0x01
LED1		.equ	0x10
LED2		.equ	0x20
LED3		.equ	0x40
LED4		.equ	0x80
LED5		.equ	0xE8
LED6		.equ	0xD8
LED7		.equ	0xB8
LED8		.equ	0x78

		.global setup
		.global waitForCenter
		.global waitForUpDown
		.global waitForLeftRight
		.global getSamples
		.global convertSamples
		.global displaySamples

		.data
		.bss	meas_base, 10
		.bss	meas_latest, 10
		.bss	sensor_status, 1
		.bss	SWdelay, 1
		.text
setup:
		bis.b	#0xf9, &P1DIR	; set up P1 as outputs
		bic.b	#0xf9, &P1OUT	; P1 outputs 0
		bis.b 	#0x6, &P1SEL 	; P1.2/P1.1 = USART0 TXD/RXD
		bis.b 	#0x6, &P1SEL2 	; P1.2/P1.1 = USART0 TXD/RXD
		mov.b	#0x1a, SWdelay
		call	#meas_base_val
		mov.b	#0xdf, SWdelay
		clr		r13
		clr 	r14
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
endwait3a	bic		#0, r13
			ret
endwait3b	bis		#2, r13
			ret

convertSamples:

			ret

displaySamples:

			ret

meas_base_val:
			mov.b	#0x02, R5	; initialize R5 to point to P2.x
			mov.b	#0x00, R6	; initialize R6 to the base of meas_base
meas_base_again
			call 	#meas_setup
			bis 	#MC_2 + TACLR, &TA0CTL 	; Clear TAR and start TA0 in continuous mode
			call	#SWtimer			;provide the accumulation period;could use instead ACLK fed from VLO
			xor		#CCIS0, &TA0CCTL1	;capture trigger by toggeling CCIS0
			mov		TA0CCR1, meas_base(R6)
			bic 	#MC1+MC0, &TA0CTL 	; Stop TA
			sub 	#0x20, meas_base(R6)	; Adjust this baseline
			bic.b 	R5,&P2SEL2		; Stop the oscillation on the latest. pin
			rla.b	R5				; Prepare next x
			add.b	#0x02, R6		; Prepare the next index into the array
			cmp.b	#0x40, R5		; Check if done with all five sensors
			jne		meas_base_again	;
			ret						;

meas_latest_val:
			mov.b	#0x02, R5	; initialize R5 to point to P2.1
			mov.b	#0x00, R6		; initialize R6 to the base of meas_base
meas_latest_again
			call 	#meas_setup	;
			bis 	#MC_2 + TACLR, &TA0CTL 	; Continuous, Clear TAR
			call	#SWtimer
			xor		#CCIS0, &TA0CCTL1	; Trigger SW capture
			mov 	TA0CCR1, meas_latest(R6)	; Save captured value in array
			bic 	#MC1+MC0, &TA0CTL 	; Stop timer
			bic.b 	R5,&P2SEL2		; Stop the oscillation on the latest. pin
			rla.b	R5				; Prepare next x
			add.b	#0x02, R6		; Prepare the next index into the array
			cmp.b	#0x40, R5		; Check if done with all five sensors
			jne		meas_latest_again
			ret

det_sensor:	clr.b	sensor_status
			mov.b	#0x02, R5		; initialize R5 to point to P2.1
			mov.b	#0x00, R6		; initialize R6 to the base of meas_base
CheckNextSensor
			cmp		meas_latest(R6), meas_base(R6)
			jl		NotThisSensor
			bis.b	R5, sensor_status	; Update sensor_status
NotThisSensor
			rla.b	R5				; Prepare next x
			add.b	#0x02, R6		; Prepare the next index into the array
			cmp.b	#0x40, R5		; Check if done with all five sensors
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
			mov.b	SWdelay, r8				; The total SW delay count = SWdelay * SWdelay
Reloadr7	mov.b	SWdelay, r7
ISr70		dec		r7
			jnz		ISr70
			dec		r8
			jnz		Reloadr7
			ret

	.end
