#####################################################################
#
# CSCB58 Fall 2020 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Justin Wang, 1005548481
#
# Bitmap Display Configuration:
# - Unit width in pixels: 16					     
# - Unit height in pixels: 16
# - Display width in pixels: 512
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1/2/3/4/5 (choose the one the applies)
# Milestone 1, 2 fully completed
# Milestone 3 partial, game terminates if Doodler hits bottom of screen
#
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
# ... (add more if necessary)
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). 
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################

.data
	displayAddress:	.word	0x10008000
	doodlerUp: .word  0
	doodlerJumpLen: .word 0
	doodlerPosX: .word 30
	doodlerPosY: .word 25
	sky: .word 0x4BFAF5
	doodlerCol: .word 0x2EA319
	platformCol: .word 0x550059 
	platform1: .word 2
	platform1H: .word 7
	platform2: .word 6
	platform2H: .word 15
	platform3: .word 10
	platform3H: .word 23
	platform4: .word 16
	platform4H: .word 31
	platformLength: .word 15
	score: .word 0
	scoreCounter: .word 0
	shiftCounter: .word 0
	
	
.text
	lw $t0, displayAddress	# $t0 stores the base address for display
	li $t7, 0
	
	WHILE:
	
	#Check for Input
	lw $t8, 0xffff0000 
	beq $t8, 1, keyboardInput
	
	finishKeyboardInput:
	
	add $t7, $t7, 1
	lw $t1, doodlerPosY
	beq $t1, 32, Exit
	lw $t0, displayAddress
	
	beq $t7, 2, updateDoodlerY
	
	finishUpdateY:
	
	lw $t1, scoreCounter
	beq $t1, 4, setLength
	
	finishSetLength:
	
	lw $t1, shiftCounter
	bne $t1, 0, shiftPlatforms
	
	finishShiftPlatforms:
	
	jal drawEntire
	jal generatePlatforms
	jal drawDoodler
	jal sleep
	
	jal WHILE
	

#sets the entire screen to sky	
drawEntire:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	lw $t0, displayAddress
	lw $t2, sky
	li $t1, 0

	WHILEde:
	beq $t1, 1024, DONEde
	
	sw $t2, 0($t0)
	add $t0, $t0, 4
	add $t1, $t1, 1
	
	jal WHILEde
	
	DONEde:
	lw $ra, 0($sp)
	addi, $sp, $sp, 4
	lw $t0, displayAddress
	jr $ra
	
#Draws Where the Doodler is
drawDoodler:
	lw $t3, doodlerPosX
	lw $t2, doodlerPosY
	lw $t0, displayAddress
	
	mul $t3, $t3, 4
	mul $t2, $t2, 128
	
	add $t4, $t2, $t3
	
	add $t0, $t0, $t4
	
	lw $t3, doodlerCol
	
	sw $t3, 0($t0)
	
	jr $ra
	
#sets framerate
sleep:
	li $v0, 32
	li $a0, 33
	syscall
	
	jr $ra

#Updates the Y position of Doodler
updateDoodlerY:
	
	lw $t0, displayAddress
	li $t7, 1
	lw $t2, doodlerPosY
	la $a0, doodlerPosY
	lw $t3, doodlerPosX
	la $a1, doodlerJumpLen
	lw $t4, doodlerJumpLen
	lw $t5, doodlerUp
	la $a2, doodlerUp
	lw $t6, platformCol

	beq $t5, 1, goUp
	
	mul $t3, $t3, 4
	mul $t2, $t2, 128
	add $t0, $t0, $t2
	add $t0, $t0, $t3
	add $t0, $t0, 128
	lw $t4, 0($t0)
	
	beq $t4, $t6, startUp
	
	lw $t2, doodlerPosY
	add $t2, $t2, 1
	sw $t2, 0($a0)
	
	
	j finishUpdateY
	
	startUp:
		li $t4, 1
		sw $t4, 0($a2)
		sw $t4, 0($a1)
		lw $t2, doodlerPosY
		add $t2, $t2, -1
		sw $t2, ($a0) 
		
		beq $t2, 13, shiftScreen
		
		j finishUpdateY
		
		#If it was above the third platform, then start shifting the screen up
		shiftScreen:
			la $a0, shiftCounter
			li $t1, 1
			sw $t1, 0($a0)
			lw $t1, scoreCounter
			la $a0, scoreCounter
			add $t1, $t1, 1
			sw $t1, 0($a0)
			lw $t1, score
			la $a0, score
			add $t1, $t1, 1
			sw $t1, 0($a0)
			j finishUpdateY
		
	# doodler is currently going up
	goUp:
		beq $t4, 10, startDown
		
		add $t4, $t4, 1
		sw $t4, 0($a1)
		
		add $t2, $t2, -1
		sw $t2, 0($a0)
		
		j finishUpdateY
		#Doodler is at apex and about to go dowwn
		startDown:
			li $t4, 0
			sw $t4, 0($a1)
			
			li $t3, 0
			sw $t3, 0($a2)
		
			add $t2, $t2, 1
			sw $t2, 0($a0)
			
			j finishUpdateY
			

#Checks what the keyboard input is	
keyboardInput:
	lw $t2, 0xffff0004
	
	beq $t2, 0x6A, doodleLeft
	beq $t2, 0x6B, doodleRight

#Moves Doodle left	
doodleLeft:
	lw $t2, doodlerPosX
	
	la $a0, doodlerPosX
	beq $t2, 0, doodleLeftHelp
	sub $t2, $t2, 1
	sw $t2, 0($a0)
	
	j finishKeyboardInput
	
doodleLeftHelp:
	li $t2, 31
	sw $t2, 0($a0)
	
	j finishKeyboardInput

#Moves Doodle Right	
doodleRight:
	lw $t2, doodlerPosX
	
	la $a0, doodlerPosX
	beq $t2, 31, doodleRightHelp
	add $t2, $t2, 1
	sw $t2, 0($a0)
	
	j finishKeyboardInput

doodleRightHelp:
	li $t2, 0
	sw $t2, 0($a0)
	
	j finishKeyboardInput
	
#Generates the platforms, NOT FINAL
generatePlatforms:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	lw $t1, platform1
	lw $t4, platformLength
	lw $t3, platform1H
	li $t2, 0
	lw $t6, platformCol
	lw $t0, displayAddress
	
	mul $t1, $t1, 4
	mul $t3, $t3, 128
	add $t5, $t1, $t3
	
	add $t0, $t0, $t5
	
	WHILE1:
	
	beq $t2, $t4, DONE1
	
	sw $t6, 0($t0)
	
	add $t0, $t0, 4
	
	add $t2, $t2, 1
	
	jal WHILE1
	
	DONE1:
	
	lw $t1, platform2
	lw $t3, platform2H
	li $t2, 0
	lw $t0, displayAddress
	
	mul $t1, $t1, 4
	mul $t3, $t3, 128
	add $t5, $t1, $t3
	
	add $t0, $t0, $t5
	
	WHILE2:
	
	beq $t2, $t4, DONE2
	
	sw $t6, 0($t0)
	
	add $t0, $t0, 4
	
	add $t2, $t2, 1
	
	jal WHILE2
	
	DONE2:
	
	lw $t1, platform3
	lw $t3, platform3H
	li $t2, 0
	lw $t0, displayAddress
	
	mul $t1, $t1, 4
	mul $t3, $t3, 128
	add $t5, $t1, $t3
	
	add $t0, $t0, $t5
	
	WHILE3:
	
	beq $t2, $t4, DONE3
	
	sw $t6, 0($t0)
	
	add $t0, $t0, 4
	add $t2, $t2, 1
	
	jal WHILE3
	
	DONE3:
	
	lw $t1, platform4
	lw $t3, platform4H
	li $t2, 0
	lw $t0, displayAddress
	
	mul $t1, $t1, 4
	mul $t3, $t3, 128
	add $t5, $t1, $t3
	
	add $t0, $t0, $t5
	
	WHILE4:
	
	beq $t2, $t4, DONE4
	
	sw $t6, 0($t0)
	add $t0, $t0, 4
	add $t2, $t2, 1
	
	jal WHILE4
	
	DONE4:
	
	lw $ra, 0($sp)
	addi, $sp, $sp, 4
	
	jr $ra
	

#Reduces the length of the platform by 1
setLength:
	lw $t1, platformLength
	
	beq $t1, 1, setLengthDONE
	
	la $a0, platformLength
	add $t1, $t1, -1
	sw $t1, 0($a0)
	
	li $t1, 0
	la $a0, scoreCounter
	sw $t1, 0($a0)
	
	j finishSetLength
	setLengthDONE: 
	
	li $t1, -999
	la $a0, scoreCounter
	
	li $t1, 0
	la $t1, 0($a0)
	j finishSetLength
	
		
#generate random number for creating new platform		
generateRandom:
	lw $t1, platformLength
	li $t2, 32
	sub $t1, $t2, $t1
	li $v0, 42
 	li $a0, 0
 	move $a1, $t1	
	syscall
	
	jr $ra

#Shift all the down platforms by 1, and set Doodler down 1 as well
shiftPlatforms:
	beq $t7, 1, startShift
	
	j finishShiftPlatforms
	startShift:
	lw $t1, shiftCounter
	la $a0, shiftCounter
	add $t1, $t1, 1
	sw $t1, 0($a0)
	beq $t1, 2, createNewPlatform
	
	lw $t2, platform1H
	la $a1, platform1H
	add $t2, $t2, 1
	sw $t2, 0($a1)
	
	lw $t2, platform2H
	la $a1, platform2H
	add $t2, $t2, 1
	sw $t2, 0($a1)
	
	lw $t2, platform3H
	la $a1, platform3H
	add $t2, $t2, 1
	sw $t2, 0($a1)
	
	lw $t2, platform4H
	la $a1, platform4H 
	add $t2, $t2, 1
	sw $t2, 0($a1)
	
	lw $t2, doodlerPosY
	la $a1, doodlerPosY
	add $t2, $t2, 1
	sw $t2, 0($a1)
	
	beq $t1, 9, setShiftCounter
	j finishShiftPlatforms
	
	setShiftCounter:
		li $t1, 0
		sw $t1, 0($a0)
		j finishShiftPlatforms
	#Move platform index, create new platform
	createNewPlatform:
	lw $t2, platform3H
	la $a1, platform4H
	add $t2, $t2, 1
	sw $t2, 0($a1)
	
	lw $t2, platform3
	la $a1, platform4
	sw $t2, 0($a1)
	
	lw $t2, platform2H
	la $a1, platform3H
	add $t2, $t2, 1
	sw $t2, 0($a1)
	
	lw $t2, platform2
	la $a1, platform3
	sw $t2, 0($a1)
	
	lw $t2, platform1H
	la $a1, platform2H
	add $t2, $t2, 1
	sw $t2, 0($a1)
	
	lw $t2, platform1
	la $a1, platform2
	sw $t2, 0($a1)
	
	jal generateRandom
	move $t1, $a0
	li $t2, 0
	
	la $a1, platform1H
	sw $t2, 0($a1)
	la $a1, platform1
	sw $t1, 0($a1)
	
	j finishShiftPlatforms
	
	
	
	
Exit:
	li $v0, 10 # terminate the program gracefully
	syscall
