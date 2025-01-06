.text 
.org 0x20

izvorna_koda: .asciz "    \n\n     stev1: .var 0xf123       @ komentar 1\n @prazna vrstica \n    stev2: .var      15\nstev3: .var 128\n_start:\n mov r1, #5 @v r1 premakni 5\nmov r2, #1\nukaz3: add r1, #1\nb _start"

.align
izvorna_koda_pocisceno: .space 120
.align

tabela_oznak: .space 100
.align
.global _start
_start:
	
	@----------- PRVI KORAK -----------
	@komentarji in presledki in prepis v precisceno
	
		@r0 - izvorna_koda nas
		@r1 - izvorna_koda_pocisceno nas
		@r2 - temp char
		@r3 - stanje 0 - normal, 1 - comment(@)
		
		adr r0, izvorna_koda
		adr r1, izvorna_koda_pocisceno
		sub r0, r0, #1	@premik na dejansko začetek
		sub r1, r1, #1
	
	PRVI_KORAK:
		ldrb r2, [r0, #1]! 	@bralec
		
		cmp r2, #10			@preverimo za presledke in commente preskok če ja
		moveq r3, #0		@res state r3
		cmp r2, #64			@check @
		moveq r3, #1		@res state r3
		cmp r3, #1			@check COMMENT
		beq PRVI_KORAK		@če COMMENT preskok
		
		cmp r2, #32			@check presledek
		bleq PRESLEDEK		@če presledek skoč v presledek
		
		strb r2, [r1, #1]!	@shrani v output 
		cmp r2, #0			@preveri konec niza
		beq	DRUGI_KORAK_INIT@naprej na 2
		b PRVI_KORAK		@till end
		
	PRESLEDEK:
		ldrb r2, [r0, #-1]	@prever prejsni
		cmp r2,#32			@preveri presledek
		bls	PRVI_KORAK
		
		ldrb r2, [r0,#1]	@prever desn
		cmp r2, #32			@če je odzadaj presledek
		bls PRVI_KORAK
		cmp r2, #64			@prever za @
		beq PRVI_KORAK
		
		ldrb r2, [r0]	@shrani če ni presledek v čist niz
		mov pc, lr
	
	@----------- DRUGI KORAK -----------
	@odvečne vrstice '\n' oz LF in prepis
		
		@r0 - izvorna_koda nas
		@r1 - izvorna_koda_pocisceno nas
		@r2 - temp char
		@r3 - stanje  0 - normal, 1 - začetek vrstice, 3 - oznake :
	
	DRUGI_KORAK_INIT:
		adr r0, izvorna_koda
		adr r1, izvorna_koda_pocisceno
		sub r0, r0, #1
		sub r1, r1, #1
		mov r2, #0 @RESET
		mov r3, #1
		
	DRUGI_KORAK:
		ldrb r2, [r1, #1]! 			@bralec
		cmp r2, #58	
		moveq r3, #3 
		beq ZAPIS
		
		cmp r2, #10 				@pogled za /n
		beq ISKANJE_LF 				@gre na vpogled zaradi uporabnosti
		movne r3, #0
		b ZAPIS				 		@vse ostalo postavi 0 in jih zapiše
	
	ZAPIS:							
		strb r2, [r0, #1]! 			@bralec @r2 se shrani na očiščen niz na lokacijo r0
		cmp r2, #0
		bne DRUGI_KORAK 			@konec preidde na POCISTI_OSTALO
		b POCISTI_OSTALO
		
	MENJAVA_LF:
		mov r2, #32
		strb r2, [r0, #1]!
		b DRUGI_KORAK
		
	ISKANJE_LF:
		cmp r3,#1
		bhi MENJAVA_LF 		@če je stanje večje od 1 se LF zamenja z presledkom
		beq DRUGI_KORAK				@če je stanje se zamenja z presledkom LF SE IGNORIRA!
		mov r3, #1					@da se na 1 da se obravnava kot začetek nove vrstice			
		b ZAPIS
		
	POCISTI_OSTALO:
		mov r2, #0
		adr r1, izvorna_koda_pocisceno
		sub r1, r1, #1
		b POCISTI_LOOP

	POCISTI_LOOP:
		strb r2, [r0, #1]!
		cmp r0, r1
		bne POCISTI_LOOP
		b TRETJI_KORAK_INIT
		
	@----------- TRETJI KORAK -----------
	@tabela oznak

		@r0 - izvorna_koda nas
		@r1 - izvorna_koda_pocisceno nas
		@r2 - temp char
		@r3 - word start index
		@r4 - oznaka adressa

	TRETJI_KORAK_INIT:
		adr r0, izvorna_koda
		adr r1, tabela_oznak
		sub r0, r0, #1	@RESET
		sub r1, r1, #1
		mov r3, r0		
		mov r4, #0
		b ISKANJE_OZNAK

	ISKANJE_OZNAK:
		ldrb r2, [r0, #1]! 			
		cmp r2, #10					@poglej newline
		addeq r4, r4, #1 			@povecaj stevec
		cmp r2, #58					@poglej ce je :
		beq NASLOV_OZNAK
		
		cmp r2, #32					@poglej ce je :
		movls r3, r0 				@shranimo naslov v r0 saj je konec besede
		cmp r2, #0					@poglej ce je vse prebral
		bne ISKANJE_OZNAK
		b _end

	NASLOV_OZNAK:
		mov r2, #39 				@zapis '
		strb r2, [r1, #1]!			
		sub r0, r0, #1
		b ZAPIS_OZNAK

	ZAPIS_OZNAK:
		ldrb r2, [r3, #1]!			@preberi znak iz "besede" (od r3 naprej)
		strb r2, [r1, #1]!			@zapiši v tabela_oznak
		cmp r3, r0
		bne ZAPIS_OZNAK 			@ponavljaj, dokler ne pridemo do dvopičja
		
		mov r2, #39					@dodaj zaključno '
		strb r2, [r1, #1]!
		mov r2, #0					@in za njim še 0, da imamo zaključen C-niz
		strb r2, [r1, #1]!
		
		add r0, r0, #1				@kazalec v izvorni kodi premaknemo naprej (prek dvopičja)
		tst r1, #1
		addeq r1, r1, #1			@če je liho, ga poravnamo (dodamo 1 bajt)
		
		strh r4, [r1, #1]!	 		@zapišemo 16-bitno vrednost r4 (tj. 'naslov') v tabelo
		add r1, r1, #1		 		@po 16-bitnem zapisu se premaknemo naprej
		b ISKANJE_OZNAK

_end: b _end