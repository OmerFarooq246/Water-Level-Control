#define __SFR_OFFSET 0x00
#include "avr/io.h"

.global Sensor

Sensor:
SBI DDRB, 1 ;PortB pin 1(PB1) -> D9 of Arduino set to 1(as an output pin)(Trigger pin)
CBI DDRB, 0 ;PortB pin 0(PB0) -> D8 of Arduino set to 0(as an input pin) (Echo pin)
;setting LEDs at outputs at pins 4(RED),5(BLUE) and 6(GREEN) of port D
SBI DDRD, 4
SBI DDRD, 5
SBI DDRD, 6

;main loop
L1:
SBI PORTB, 1
RCALL tms_Delay     ;sending 10 microseconds high pulse to PB1
CBI PORTB, 1 

RCALL Echo
RCALL LED_Control
RCALL ms_Delay
RJMP L1



tms_Delay:
CLR R21              ;making register R21 zero
OUT TCNT0, R20       ;setting value of timer counter register to zero of timer 1
LDI R21, 20          ;loading a value of 20 in R21
OUT OCR0A, R21
LDI R21, 0b00001010  ;seting cs pins to prescalar value of 8 and CTC mode
OUT TCCR0B, R21

check:
IN R21, TIFR0        ;inputing the timer interupt flag
SBRS R21, OCF0A      ;skip next statement if OCF0 is set
RJMP check
CLR R21              ;setting R21 to value zero
OUT TCCR0B, R21      ;setting timer zero off
LDI R21, (1<<OCF0A)
OUT TIFR0, R21
RET                  ;getting out of tms_delay function



ms_Delay:
LDI R21, 255
A: LDI R22, 255
B: LDI R23, 50
C: DEC R23
BRNE C
DEC R22
BRNE B
DEC R21
BRNE A
RET


Echo:
LDI R21, 0b00000000
STS TCCR1A, R12
LDI R21, 0b11000101  ;mode set to normal mode by setting W pins to zero
STS TCCR1B, R21      ;prescalar set to 1024, noise cancellation on, Input capture on rising edge

Rise:
IN R21, TIFR1
SBRS R21, ICF1       ;checking for the Input Capture Flag(set if fall or rise detected)
RJMP Rise
LDS R16, ICR1L       ;storing the value of Input Capture Register(lower) into R16
OUT TIFR1, R21

LDI R21, 0b10000101
STS TCCR1B, R21      ;Timer control set for falling edge detection

Fall:
In R21, TIFR1
SBRS R21, ICF1       ;checking for the Input Capture Flag(set if fall or rise detected)
RJMP Fall
LDS R28, ICR1L       ;storing the value of Input Capture Register(lower) into R28

SUB R28, R16         ;subtracting to get the distance(Distance = Time x Speed of sound)
OUT TIFR1, R21       ;                                PW = (C2 - C1) / (16x10^6)/prescalar
RET                  ;                                Distance = (C2 - C1)/2 x 64x10-6 x 34300


LED_Control:
;LEDs at PD4, PD5 and PD6(D4, D5, D6)
;clearing LEDs
CBI PORTD, 4
CBI PORTD, 5
CBI PORTD, 6

CPI R28, 5
BRLO RED
CPI R28, 15
BRLO BLUE
BRSH GREEN
L:
RET

RED:
SBI PORTD, 4
RJMP L

BLUE:
SBI PORTD, 5
RJMP L

GREEN:
SBI PORTD, 6
RJMP L
