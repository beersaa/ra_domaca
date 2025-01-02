.text
.org 0x20

izvorna_koda: .asciz " \n\n stev1: .var 0xf123 @ komentar 1\n @prazna vrstica \n stev2: .var 15\nstev3: .var 128\n_start:\n mov r1, #5 @v r1 premakni 5\nmov r2, #1\nukaz3: add r1, #1\nb _start"
izvorna_koda_pocisceno: .space 120

@r0 - izvorna_koda nas
@r1 - izvorna_koda_pocisceno nas
@r2 - temp char
@r3 - state (0 - normal, 1 - comment)
.align
.global _start
_start:
	
	@----------- PRVI KORAK -----------
	@komentarji in presledki
	
		adr r0, izvorna_koda
		adr r1, izvorna_koda_pocisceno
		sub r0,r0,#1	@premik na dejansko začetek
		sub r1,r1,#1
	
	PRVI_DEL:
		ldrb r2,[r0, #1]! 	@bralec
		cmp r2, #10			@check LF
		moveq r3, #0		@res state r3
		cmp r2, #64			@check COMMENT
		moveq r3, #1		@res state r3
		cmp r3, #1			@check COMMENT
		beq PRVI_DEL		@če COMMENT preskok
		cmp r2, #32			@check presledek
		beq CHECK_SPACE		@če presledek preveri odvečne
		strb r2, [r1, #1]!	@shrani v output 
		cmp r2, #0			@preveri konec niza
		bne PRVI_DEL		@till end
		b DRUGI_DEL_INIT	@naprej na 2
		
	CHECK_SPACE:
		ldrb r3, [r0, #-1]	@prever lev
		cmp r3,#32			@če presledek ignoriraj 
		beq	PRVI_DEL
		ldrb r3, [r0,#1]	@prever desn
		cmp r3, #32			@če presledek ignoriraj
		beq PRVI_DEL
		strb r2,[r1,#1]!	@Shrani če ni useless
		b PRVI_DEL
		
end: b end	