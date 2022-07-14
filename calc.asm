; The following program is an implementation of a five-function calculator using a stack. 
;+,-,*,/ are built using a subroutine call inside of the Evaluate subroutine. The ^ 
;then calls several instances of the * subroutine to complete the calculation. All 
;subroutines in this program are callee-saved so that they may be copied and reused in
;future programs.
.ORIG x3000
	
	JSR EVALUATE			;
	JSR PRINT_RES			;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRINT_RES

	AND R4, R4, #0		; copy R5 data into R4 for hex printing
	ADD R4, R5, R4		;

PRINT_NUM
	AND R1, R1, #0 		; ]
	ADD R1, R1, #-4 	; ] init digit counter to -4

LOOP_OUTER 
	ADD R1, R1, #0 		; setCC to 'digit counter' 
	BRz PRINTDONE		;
	
	AND R0, R0, #0 		; init 'digit' to 0
	AND R3, R3, #0 		; ]
	ADD R3, R3, #-4		; ] init 'bit counter' to -4
	
LOOP_INNER
	ADD R3, R3, #0 		; setCC to R3 data
	BRz PRINT_HEX 		; print from 'bit counter' if it has 4 bits of data loaded
	
	ADD R0, R0, R0 		; left shift 'digit' to prepare for next bit of data
	
	ADD R4, R4, #0 		; setCC to R4 data
	BRzp IS_ZERO 		; is the MSB in data a 0?
	
	ADD R0, R0, #1 		; the MSB in data is a 1, so add 1 to 'digit'.
	
IS_ZERO
	ADD R4, R4, R4 		; left shift 'data' 
	
	ADD R3, R3, #1 		; increment 'bit counter'
	BRnzp LOOP_INNER 	; do it again

PRINT_HEX
	ADD R0, R0, #-10 	; is 'digit' <= 9?
	BRzp IS_LETTER 		; 
	
	LD R6, IS_NUM_N 	;
	ADD R0, R0, R6 		; (ASCII 0) + 10 
	BRnzp PRINT_HEX_DOIT ; "Do it" -Palpatine, exactly once
	
IS_LETTER
	LD R6, IS_LETTER_N 	;
	ADD R0, R0, R6 		; (ASCII A) 

PRINT_HEX_DOIT
	OUT
	
	ADD R1, R1, #1 		; increment 'digit counter' 
	BRnzp LOOP_OUTER 	; begin next row to print

PRINTDONE
	HALT
;end of program, no need to properly restore registers

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;R0 - character input from keyboard
;R6 - current numerical output
;CALLEE-SAVED R2
;CALLEE-SAVED R3
;R7 SAVED (NESTED JSR)

EVALUATE

	ST R2, SAVER2			;
	ST R1, SAVER1			;
	ST R3, SAVER3			;
	ST R7, SAVER7			; saves R7 (PC for RET trap)

EVAL_START
	GETC
	OUT

	LD R2, EQUAL_NEG 		; ]test if input was an = sign
	ADD R2, R2, R0 			; |
	BRz EVAL_DONE 			; ]if true, RET

	LD R2, SPACE_NEG		; ]test if input was a space
	ADD R2, R2, R0			; |
	BRz EVAL_START			; ]if true, ignore it, go to start of SR

	AND R2, R2, #0			; ]test if input is [0,9] (1/2)
	ADD R2, R0, R2			; |
	LD R3, NEG_47			; |R0 less than 47 causes this branch jump
	ADD R2, R3, R2			; |
	BRnz CHECK_OPERATOR		; ]jump if NaN (1/2)

	AND R2, R2, #0			; ]test if input is [0,9] (2/2)
	ADD R2, R0, R2			; |
	LD R3, NEG_58			; |R0 greater than 58 causes this branch jump
	ADD R2, R3, R2			; |
	BRzp CHECK_OPERATOR		; ]jump if NaN (2/2)

	LD R1, HEX_NEG			; input must be [0,9] operand
	ADD R0, R0, R1			; HEX FIX
	JSR PUSH				; push R0 to stack
	BRnzp EVAL_START		; operand recorded

CHECK_OPERATOR
	AND R2, R2, #0			; test if '+' was input
	ADD R2, R0, R2			;
	LD R3, PLUS_NEG			;
	ADD R2, R3, R2			;
	BRz TO_PLUS				; 

	AND R2, R2, #0			; test if '-' was input
	ADD R2, R0, R2			;
	LD R3, MINUS_NEG		;
	ADD R2, R3, R2			;
	BRz TO_MIN				; 

	AND R2, R2, #0			; test if '*' was input
	ADD R2, R0, R2			;
	LD R3, ASTERISK_NEG		;
	ADD R2, R3, R2			;
	BRz TO_MULT				; 

	AND R2, R2, #0			; test if '/' was input
	ADD R2, R0, R2			;
	LD R3, SLASH_NEG		;
	ADD R2, R3, R2			;
	BRz TO_DIV				; 

	AND R2, R2, #0			; test if '^' was input
	ADD R2, R0, R2			;
	LD R3, CARROT_NEG		;
	ADD R2, R3, R2			;
	BRz TO_EXP				; 
	
ERROR_EVAL
	LEA R0, ERROR_MSG 		;if the program makes it here, the input was invalid 
	PUTS 
	HALT
	
TO_PLUS
	JSR PLUS				; ]perform the correct operator on stack, then restart
	BRnzp EVAL_START		; ]same as all TO_ labels
TO_MIN
	JSR MIN					;
	BRnzp EVAL_START		;
TO_MULT
	JSR MUL					;
	BRnzp EVAL_START		;
TO_DIV
	JSR DIV					;
	BRnzp EVAL_START		;
TO_EXP
	JSR EXP					;
	BRnzp EVAL_START		;

EVAL_DONE
	
	JSR POP					;
	JSR POP					;
	ADD R5, R5, #0			; check for valid 
	BRz ERROR_EVAL			;

	LD R2, SAVER2			; ]
	LD R3, SAVER3			; | CALLEE-SAVED values loaded back in place
	LD R7, SAVER7			; ]

	LD R6, STACK_TOP		; load output to R6
	ADD R6, R6, #0			; point at value to print instead of next available one
	
	AND R5, R5, #0			; ]
	LDR R5, R6, #0			; ] put the result (top of stack) into R5 using the pointer
	RET


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;out R0
;PLUS SUBROUTINE
PLUS	

	ST R7, ADD_SAVER7		;
    ST R0, ADD_SAVER0		;
    ST R1, ADD_SAVER1		;
    ST R6, ADD_SAVER6		;

	LD R6, STACK_TOP		;

	JSR POP					; first POP of add
	LD R6, STACK_TOP		;
	ADD R5, R5, #0			; setCC to R5
	BRp ERROR_PLUS			; if R5 returned as 1, first POP failed
	AND R1, R1, #0			; ]
	ADD R1, R0, #0			; ] POP put an operand in R0, save it here

	JSR POP					; second POP of add
	LD R6, STACK_TOP		;
	ADD R5, R5, #0			; setCC to R5
	BRp ERROR_PLUS			; if R5 returned as 1, second POP failed
	
	ADD R0, R0, R1			; do the PLUS operation, save in R0

	JSR PUSH				; push the result to stack
	LD R6, STACK_TOP		;
	ADD R5, R5, #0			;
	BRp ERROR_PLUS			; if R5 returned as 1, PUSH failed

    LD R7, ADD_SAVER7		; ]
    LD R0, ADD_SAVER0		; | restore registers
    LD R1, ADD_SAVER1		; |
    LD R6, ADD_SAVER6		; ]

	RET

ERROR_PLUS
	LEA R0, ERROR_MSG 		;if the program makes it here, the input was invalid 
	PUTS 
	HALT
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;out R0
;MIN SUBROUTINE
MIN	

	ST R7, MIN_SAVER7		;
    ST R0, MIN_SAVER0		;
    ST R1, MIN_SAVER1		;
    ST R6, MIN_SAVER6		;

	LD R6, STACK_TOP		;

	JSR POP					; first POP of add
	LD R6, STACK_TOP		;
	ADD R5, R5, #0			; setCC to R5
	BRp ERROR_MIN			; if R5 returned as 1, first POP failed
	AND R1, R1, #0			; ]
	ADD R1, R0, #0			; ] POP put an operand in R0, save it here

	JSR POP					; second POP of add
	LD R6, STACK_TOP		;
	ADD R5, R5, #0			; setCC to R5
	BRp ERROR_MIN			; if R5 returned as 1, second POP failed
	
	NOT R1, R1				; ] 
	ADD R1, R1, #1			; |
	ADD R0, R0, R1			; ] do the MIN operation, save in R0

	JSR PUSH				; push the result to stack
	LD R6, STACK_TOP		;
	ADD R5, R5, #0			;
	BRp ERROR_MIN			; if R5 returned as 1, PUSH failed

    LD R7, MIN_SAVER7		; ]
    LD R0, MIN_SAVER0		; | restore registers
    LD R1, MIN_SAVER1		; |
    LD R6, MIN_SAVER6		; |

	RET

ERROR_MIN
	LEA R0, ERROR_MSG 		;if the program makes it here, the input was invalid 
	PUTS 
	HALT
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
EQUAL_NEG	.FILL #-61  ;
SPACE_NEG	.FILL #-32	;
NEG_47		.FILL #-47	;
NEG_58		.FILL #-58	;
PLUS_NEG	.FILL #-43	;
MINUS_NEG	.FILL #-45	;
ASTERISK_NEG .FILL #-42	;
SLASH_NEG	.FILL #-47	;
CARROT_NEG	.FILL #-94	;
HEX_NEG		.FILL #-48	;
HEX_POS 	.FILL #48	;
IS_NUM_N	.FILL #58 ;	(ASCII 0) + 10 
IS_LETTER_N	.FILL #65 ; (ASCII A) + 10 

SAVER1		.BLKW #1	;
SAVER2		.BLKW #1	;
SAVER3		.BLKW #1	;
SAVER7		.BLKW #1	;

ERROR_MSG .STRINGZ "Invalid Expression" ;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MUL	

	ST R7, MUL_SAVER7		;
    ST R0, MUL_SAVER0		;
    ST R1, MUL_SAVER1		;
    ST R6, MUL_SAVER6		;
	ST R2, MUL_SAVER2		;

	LD R6, STACK_TOP		;

	JSR POP					; first POP of MUL
	LD R6, STACK_TOP		;
	ADD R5, R5, #0			; setCC to R5
	BRp ERROR_MIN			; if R5 returned as 1, first POP failed
	AND R1, R1, #0			; ]
	ADD R1, R0, #0			; ] POP put an operand in R0, save it here

	JSR POP					; second POP of MUL
	LD R6, STACK_TOP		;
	ADD R5, R5, #0			; setCC to R5
	BRp ERROR_MIN			; if R5 returned as 1, second POP failed
	AND R2, R2, #0			;
	ADD R2, R0, #0			;
	AND R0, R0, #0			;

MUL_LOOP
	ADD R0, R0, R1			; ] MUL
	ADD R2, R2, #-1			; |
	BRp MUL_LOOP			; ]

	JSR PUSH				; push the result to stack
	LD R6, STACK_TOP		;
	ADD R5, R5, #0			;
	BRp ERROR_MIN			; if R5 returned as 1, PUSH failed

    LD R7, MUL_SAVER7		; ]
    LD R0, MUL_SAVER0		; | restore registers
    LD R1, MUL_SAVER1		; |
    LD R6, MUL_SAVER6		; |
	LD R2, MUL_SAVER2		; ]

	RET
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DIV	

	ST R7, DIV_SAVER7		;
    ST R0, DIV_SAVER0		;
    ST R1, DIV_SAVER1		;
    ST R6, DIV_SAVER6		;
	ST R2, DIV_SAVER2		;

	LD R6, STACK_TOP		;

	JSR POP					; first POP of DIV
	LD R6, STACK_TOP		;
	ADD R5, R5, #0			; setCC to R5
	BRp ERROR_MIN			; if R5 returned as 1, first POP failed
	AND R2, R2, #0			; ]
	ADD R2, R0, #0			; ] POP put an operand in R0, save it here

	JSR POP					; second POP of DIV
	LD R6, STACK_TOP		;
	ADD R5, R5, #0			; setCC to R5
	BRp ERROR_MIN			; if R5 returned as 1, second POP failed
	AND R1, R1, #0			;
	ADD R1, R0, R1			;

	AND R0, R0, #0			;
	NOT R2, R2				; flip R2 for subtraction
	ADD R2, R2, #1			;

DIV_LOOP
	ADD R0, R0, #1			;
	ADD R1, R2, R1			; = R1 - R2
	BRzp DIV_LOOP			;

	ADD R0, R0, #-1			; fix div

	JSR PUSH				; push the result to stack
	LD R6, STACK_TOP		;
	ADD R5, R5, #0			;
	BRp ERROR_MIN			; if R5 returned as 1, PUSH failed

    LD R7, DIV_SAVER7		; ]
    LD R0, DIV_SAVER0		; | restore registers
    LD R1, DIV_SAVER1		; |
    LD R6, DIV_SAVER6		; |
	LD R2, DIV_SAVER2		; ]

	RET	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
EXP

	ST R7, EXP_SAVER7		;
    ST R0, EXP_SAVER0		;
    ST R6, EXP_SAVER6		;
    ST R1, EXP_SAVER1		;
	ST R2, EXP_SAVER2		;
	ST R3, EXP_SAVER3		;
	ST R4, EXP_SAVER4		;

	LD R6, STACK_TOP		;

	JSR POP					; first POP of EXP
	LD R6, STACK_TOP		;
	ADD R5, R5, #0			; setCC to R5
	BRp ERROR_MIN			; if R5 returned as 1, first POP failed
	AND R2, R2, #0			; ]
	ADD R2, R0, #0			; ] POP put an operand in R0, save it here

	JSR POP					; second POP of EXP
	LD R6, STACK_TOP		;
	ADD R5, R5, #0			; setCC to R5
	BRp ERROR_MIN			; if R5 returned as 1, second POP failed
	ST R0, EXP_SAVE			; save base

	AND R4, R4, #0			;
	ADD R4, R2, #0			; R4 = exponent-1
	ADD R4, R4, #-1			; 

POOP
	LD R0, EXP_SAVE			; load base
	JSR PUSH				;
	ADD R2, R2, #-1			;
	BRp POOP				;

EXP_LOOP
	JSR MUL
	ADD R4, R4, #-1			;
	BRp EXP_LOOP			;

	LD R6, STACK_TOP		;
	ADD R5, R5, #0			;
	BRp ERROR_MIN			; if R5 returned as 1, PUSH failed

    LD R7, EXP_SAVER7		; ]
    LD R0, EXP_SAVER0		; | restore registers
    LD R1, EXP_SAVER1		; |
    LD R6, EXP_SAVER6		; |
	LD R2, EXP_SAVER2		; |
	LD R3, EXP_SAVER3		; |
	LD R4, EXP_SAVER4		; ]

	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;IN:R0, OUT:R5 (0-success, 1-fail/overflow)
;R3: STACK_END R4: STACK_TOP
;
PUSH	
	ST R3, PUSH_SaveR3	;save R3
	ST R4, PUSH_SaveR4	;save R4
	AND R5, R5, #0		;
	LD R3, STACK_END	;
	LD R4, STACK_TOP	;
	ADD R3, R3, #-1		;
	NOT R3, R3		;
	ADD R3, R3, #1		;
	ADD R3, R3, R4		;
	BRz OVERFLOW		;stack is full
	STR R0, R4, #0		;no overflow, store value in the stack
	ADD R4, R4, #-1		;move top of the stack
	ST R4, STACK_TOP	;store top of stack pointer
	BRnzp DONE_PUSH		;
OVERFLOW
	ADD R5, R5, #1		;
DONE_PUSH
	LD R3, PUSH_SaveR3	;
	LD R4, PUSH_SaveR4	;
	RET


PUSH_SaveR3	.BLKW #1	;
PUSH_SaveR4	.BLKW #1	;


;OUT: R0, OUT R5 (0-success, 1-fail/underflow)
;R3 STACK_START R4 STACK_TOP
;
POP	
	ST R3, POP_SaveR3	;save R3
	ST R4, POP_SaveR4	;save R3
	AND R5, R5, #0		;clear R5
	LD R3, STACK_START	;
	LD R4, STACK_TOP	;
	NOT R3, R3		;
	ADD R3, R3, #1		;
	ADD R3, R3, R4		;
	BRz UNDERFLOW		;
	ADD R4, R4, #1		;
	LDR R0, R4, #0		;
	ST R4, STACK_TOP	;
	BRnzp DONE_POP		;
UNDERFLOW
	ADD R5, R5, #1		;
DONE_POP
	LD R3, POP_SaveR3	;
	LD R4, POP_SaveR4	;
	RET


POP_SaveR3	.BLKW #1	;
POP_SaveR4	.BLKW #1	;
STACK_END	.FILL x3FF0	;
STACK_START	.FILL x4000	;
STACK_TOP	.FILL x4000	;

MIN_SAVER7	.BLKW #1	;
MIN_SAVER0	.BLKW #1	;
MIN_SAVER1	.BLKW #1	;
MIN_SAVER6	.BLKW #1	;
ADD_SAVER7	.BLKW #1	;
ADD_SAVER0	.BLKW #1	;
ADD_SAVER1	.BLKW #1	;
ADD_SAVER6	.BLKW #1	;
MUL_SAVER7	.BLKW #1	;
MUL_SAVER0	.BLKW #1	;
MUL_SAVER1	.BLKW #1	;
MUL_SAVER6	.BLKW #1	;
MUL_SAVER2	.BLKW #1	;
DIV_SAVER7	.BLKW #1	;
DIV_SAVER0	.BLKW #1	;
DIV_SAVER1	.BLKW #1	;
DIV_SAVER6	.BLKW #1	;
DIV_SAVER2	.BLKW #1	;
EXP_SAVER7	.BLKW #1	;
EXP_SAVER0	.BLKW #1	;
EXP_SAVER1	.BLKW #1	;
EXP_SAVER6	.BLKW #1	;
EXP_SAVER2	.BLKW #1	;
EXP_SAVER3	.BLKW #1	;
EXP_SAVER4	.BLKW #1	;
EXP_SAVE	.BLKW #1	;

.END
