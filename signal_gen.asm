; Name:	Mendel Wells:    312250087
;		Yehuda Lederman: 312563869
; File:	signal_gen.asm
; Date:	 13/01/2022
; Purpose: Creating a simple function generator, that can output three types of signals, in frequencys between 1-999 Hz
; The user will operate the signal generator by sending via the UART a four character string. The first character
; will be an ‘S’ (Sine) or an  ‘A’ (sAwtooth), or an ‘Q’ (sQuare). The next three characters
; will be a three frequency value. for exsample to have the signal generator output a
; 500 Hz sin wave, the user will type S500.
;
; Tester  : DR. Yosi Golovachev  
;____________________________________________
#include <ADUC841.H>

;give meaningful names
SIGNAL           EQU      R2 
FREQ_HUN_H       EQU      R3 
FREQ_HUN_L       EQU      R4
FREQ_TEN         EQU      R5 
FREQ_UNIT        EQU      R6 


CSEG    	AT		 0000H 
JMP		    MAIN
 
	
;_______________________________________________________
CSEG		AT			0023H	                         ; UART ISR	
	
JMP         TRANSMIT	
	

;_______________________________________________________
CSEG		AT			000BH	                        ; Timr0 ISR	

JMP        TIMER



CSEG		AT			0100H
;_______________________________________________________
MAIN:

ANL			TMOD,		#11110000B				;configure timer 0 
ORL			TMOD,		#00000010B
MOV			TH0,		#040                    ;set Timer 0 to interrupt every 1/(256 × 200)s

MOV			T3FD,		#020H					;configure timer 3  baudrate to 115,200


ANL			T3CON,		#01111010B				;Sets the timer and the DIV value (2)
ORL			T3CON,		#10000010B

ANL			DACCON,		#00101001B				;configure  DAC1
ORL			DACCON,		#10010110B

ANL			ADCCON1,	#10111111B				;amplitude change from 0 to Vref
ORL			ADCCON1,	#10000000B

CLR			SM0
SETB		SM1									; puts the UART in 8-bit variable baud rate mode
SETB		REN									; allow the serial port to receive data

SETB    	TR0 								; turn Timer 0 on.
SETB 		ET0	                                ; enable its interrupt.
SETB 		EA 									; globally enable interrupts
SETB		ES									; enable serial interrupt.

CLR         FLAG3                    		    ;clear all flags for next transmitet
CLR         FLAG2
CLR         FLAG1

JMP			$

CSEG    AT 0200H
TIMER:
PUSH		ACC                 ;  store accumolator value in stack 
PUSH		PSW                 ;  store cerry in stack

SIN: 
CJNE      SIGNAL ,      #'S' ,  SAWTOOTH
MOV         DPTR,   #SIN_WAVE
JMP         OUTPUT 

	
SAWTOOTH:	
CJNE      SIGNAL ,      #'A' ,  SQUARE
MOV         DPTR,   #SAWTOOTH_WAVE
JMP         OUTPUT

SQUARE:	
CJNE      SIGNAL ,      #'Q' ,  NOT_VALID
MOV         DPTR,   #SQUARE_WAVE
JMP         OUTPUT

NOT_VALID:
POP			PSW                         ; return stored values from stack
POP			ACC 
RETI

OUTPUT:
; see if CNTR_H is over 200
MOV         A,    CNTR_H
CJNE		A,	#200,	SUBTRACT
MOV			CNTR_H,	#0
JMP			NEXT
SUBTRACT:
JC			NEXT	
CLR			C
MOV			A,			CNTR_H	
SUBB		A,			#200
MOV			CNTR_H,	A

NEXT:

; add value of frequncey to canter in order to output signal in tha needed frequncey
MOV       A,       FREQ_L
ADD       A,       CNTR_L
MOV       CNTR_L,   A
MOV       A,      #0

MOV       A,       FREQ_H
ADDC      A,       CNTR_H
MOV       CNTR_H,   A  
MOV       A,      #0

;outpot to DAC1 the value in the table that is needed for tha sin wave
MOV			A,			CNTR_H
MOVC		A,			@A+DPTR
MOV			DAC1L,		A
POP			PSW                         ; return stored values from stack
POP			ACC 
RETI


CSEG    AT 0300H
TRANSMIT:
PUSH		ACC                 ;  store accumolator value in stack 
PUSH		PSW                 ;  store cerry in stack
	
CLR			RI					; RI must be cleared.
;Check what bit was transmited 

BIT3:
JB          FLAG3,       BIT2
SETB        FLAG3
MOV         SIGNAL,          SBUF   ;save MSB in SIGNAL

POP			PSW                         ; return stored values from stack
POP			ACC 
RETI

BIT2:
JB          FLAG2,       BIT1
SETB        FLAG2
MOV         A,                 SBUF
ANL         A,       #0001111B        ; translat ASCII to dechimal
MOV         B,       #100
MUL         AB
MOV         FREQ_HUN_L , A
MOV         FREQ_HUN_H , B

POP			PSW                         ; return stored values from stack
POP			ACC 
RETI

BIT1:
JB          FLAG1,       BIT0
SETB        FLAG1
MOV         A,                 SBUF
ANL         A,       #0001111B        ; translat ASCII to dechimal
MOV         B,       #10
MUL         AB
MOV         FREQ_TEN , A

POP			PSW                         ; return stored values from stack
POP			ACC 
RETI


BIT0:

CLR         FLAG3                      ;clear all flags for next transmitet
CLR         FLAG2
CLR         FLAG1

MOV         A,                 SBUF
ANL         A,       #0001111B        ; translat ASCII to dechimal

MOV         FREQ_UNIT , A             ; it is unnecessary but we add it for readability of program 
SETB        END_TRNS                  ; indecated that the string is finsht

;sum frequency to two byet in memory
SUM:
JNB         END_TRNS,     STILL_TRANSMITTING
CLR         END_TRNS

MOV         FREQ_H,      #0
MOV         FREQ_L,      #0

MOV         A,          FREQ_UNIT
ADD         A,          FREQ_L
MOV         FREQ_L,     A              ; no need to add carry 
MOV         A,          #0

MOV         A,          FREQ_TEN
ADD         A,          FREQ_L
MOV         FREQ_L,     A              ; no need to add carry 
MOV         A,          #0

MOV         A,          FREQ_HUN_L
ADD         A,          FREQ_L
MOV         FREQ_L,     A
MOV         A,          FREQ_HUN_H    
ADDC        A,          FREQ_H                ; take care of carry
MOV         FREQ_H,     A

POP			PSW                         ; return stored values from stack
POP			ACC 
RETI

STILL_TRANSMITTING:
JMP         SUM

SIN_WAVE:
#include <sin.asm>


SAWTOOTH_WAVE:
#include <sawtooth.asm>


SQUARE_WAVE:
#include <square.asm>

BSEG 
	FLAG3    :	DBIT 1                               ; user defind  flag 3 tels us if MSB weas transmited	
	FLAG2    :	DBIT 1                               ; user defind  flag 2 tels us if bit 2 weas transmited
	FLAG1    :	DBIT 1                               ; user defind  flag 1 tels us if bit 1 weas transmited
	END_TRNS :	DBIT 1                           ; user defind  flag 0 tels us if LSB weas transmited
	
DSEG	AT		0030H
		
	CNTR_H:     DS  1
	CNTR_L:     DS  1
	FREQ_H:		DS  1
	FREQ_L:     DS  1   
END	