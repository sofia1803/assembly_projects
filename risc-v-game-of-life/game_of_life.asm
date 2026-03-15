	.eqv	SYS_EXIT	93
	.eqv	RAND_INT	42
	.data
displayAddr:	.word	0x10040000
white:		.word	0x00ffffff
black:		.word	0x00000000
matA:		.space	4096
matB:		.space	4096 
	.text
#game on 64x64 map
# matA keeps actual state matB has new state after step 
main:		
	# load memory content to s register	
	lw	s0, displayAddr
	la	s1,matA
	la	s2,matB
	# initiate the two matrixes
	call	random_fill
	call	draw_bitmap
	mv	a0,s1
	mv	a1, s2
	call	copym
	# start game
	call	game
	call 	exit
#Filling matrix A with random 1 or 0 
# s1- matrix A address
#Creating initial state
random_fill:
    	li	t0, 4096
    	li	t1, 0
fill_loop:
    	li	a1, 2			# range to draw [0, 2) -> 0,1
    	li	a7, RAND_INT
    	ecall
# t2- beign matrixA pointer
# t3- calculated next address
    	mv	t2, s1
    	add	t3, t2, t1
    	sb	a0, 0(t3)
    	addi	t1, t1, 1   	# i++
    	blt	t1, t0, fill_loop
    	ret	
#game of life
#s1 - matrix A addr s2- matrix B addr
game:
	mv	s11, zero       # 0 if no changes in matrix 1 if any changes 
	li	s10, 64         # matrix size
	mv	a4, zero        # i = 0
game_loop1:
	mv	a5, zero        # j = 0
game_loop2:
#Check and sum neighbours t6-sum of neighbours
#(i-1, j-1)
	mv	a2,s1
	li	t6, 0
	addi	a0, a4, -1
	addi	a1, a5, -1
	call	readm
	add	t6, t6, a3
#(i-1, j)
	addi 	a1, a5, 0
	call 	readm
	add 	t6, t6, a3
#(i-1, j+1)
	addi 	a1, a5, 1
	call 	readm
	add 	t6, t6, a3
#(i, j-1)
	addi 	a0, a4, 0
	addi 	a1, a5, -1
	call 	readm
	add 	t6, t6, a3
#(i, j+1)
	addi 	a1, a5, 1
	call 	readm
	add 	t6, t6, a3
#(i+1, j-1)
	addi 	a0, a4, 1
	addi 	a1, a5, -1
	call 	readm
	add 	t6, t6, a3
#(i+1, j)
	addi 	a1, a5, 0
	call 	readm
	add 	t6, t6, a3
#(i+1, j+1)
	addi 	a1, a5, 1
	call 	readm
	add 	t6, t6, a3
#(i, j)
	mv 	a0, a4
	mv 	a1, a5
	call 	readm
	mv 	a2, s2	#write changes to matB

	beqz 	a3, nolife
haslife:
	li	t0, 3
	bgtu	t6, t0, death	#sum>3 = death
	li	t0, 2
	bltu	t6, t0, death	#sum<2 = death
	j	game_cont
death:
	call	write	#1->0
	li	s11, 1
	j	game_cont
nolife:
	li	t0, 3
	beq	t0, t6, born	#sum == 3 -> born
	j	game_cont
born:
	call	write	# 0->1
	li 	s11, 1
game_cont:
	addi 	a5, a5, 1	#j++ next column
	li 	t0, 63
	bleu 	a5, t0, game_loop2
	# j>63 -> j=0 i++ jump to next row
	addi 	a4, a4, 1	
	bleu 	a4, t0, game_loop1
	# if last row print bitmap update
	call 	draw_bitmap
	mv 	a0, s2
	mv 	a1, s1
	call 	copym	#matB ->matA update 

	bnez 	s11, game
	ret

#reading value in (i, j)
#input: a0 - i a1-j a2-matrix addr
#output: a3 - value
readm:
	mv 	a3, zero
	li 	t2, 63
	bgtu	a0, t2, readm_ret
	blt 	a0, zero, readm_ret
	bgtu	a1, t2, readm_ret
	blt 	a1, zero, readm_ret
	li 	t2, 64
	mul 	t1, t2, a1
	add 	t1, t1, a0
	add 	t0, a2, t1
	lb	a3, 0(t0)
readm_ret:
	ret

#write 0->1 and 1->0 in(i, j)in matrix
#input: a0- i a1-j a2- matrix addr
write:
	li 	t2, 64
	mul 	t1, t2, a1
	add 	t1, t1, a0
	add 	t0, a2, t1
	lb 	t3, 0(t0)
	beqz 	t3, write_1
write_0:
	li 	t4, 0
	j 	write_save
write_1:
	li 	t4, 1
write_save:
	sb 	t4, 0(t0)
	ret	
		
#Coping matrix A to matrix B
#inputs: a0- SRC martix a1-DEST	matrix
copym:		
	li	t0,4096		# maximum value t1 can reach
	li 	t1,0			# iterator
copym_loop:	
	add 	t2,t1,a0
	lb 	t3,0(t2)		# load byte from src matrix
	add 	t2,t1,a1
	sb 	t3,0(t2)		# store byte in dst matrix
	addi 	t1,t1,1
	bne 	t0,t1,copym_loop
	ret

#Draws bitmap based on matrix (0-> black 1->white)
#s0 -displayAddr, s1-matA
draw_bitmap:
#t2 -white t4-black t5-display_pointer t3-matA_pointer
	lw 	t2, white
	lw 	t4, black
	mv 	t5, s0
	mv 	t3,s1
	li 	t0, 0          #pixel index

draw_loop:
	lb 	t1, 0(t3)
	beq 	t1, zero, store_black

#if 1 write white
	sw 	t2, 0(t5)
	j 	next_pixel
store_black:
	sw 	t4, 0(t5)
next_pixel:
	addi 	t5,t5 , 4    # display_pointer+=4 (pixels 4x4)
	addi 	t3, t3, 1    # matA_pointer+=1 
	addi 	t0, t0, 1
	li 	t6, 4096	#64*64 pixels in bitmap
	blt 	t0, t6, draw_loop
	ret

exit:		
	li	a0, 0
	li 	a7,SYS_EXIT
	ecall
