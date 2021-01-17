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
# Milestone 1, 2, 3, 4 fully completed
# Milestone 5 2/3 completed
#
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 4.1 Tracked score
# 4.2 Dynamic difficulty change (faster gameplay, smaller platforms)
# 5.1 Realistic physics (Acceleration present while jumping up and down)
# 5.2 Dynamic on-screen notifications (Pog!, wow!, nice!)
# ... (add more if necessary)
#
# Link to video demonstration for final submission:
# - https://youtu.be/tB7U6ZJ-0lY
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
	colBlack: .word 0x000000
	colGreen: .word 0x57F20F
	platform1: .word 2
	platform1H: .word 7
	platform2: .word 6
	platform2H: .word 15
	platform3: .word 10
	platform3H: .word 23
	platform4: .word 16
	platform4H: .word 31
	platformLength: .word 15
	score: .word 1000
	scoreCounter: .word 0
	shiftCounter: .word 0
	t7Help: .word 0
	drawPogCounter: .word 0
	drawPogFrame: .word 0
	
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
	
	beq $t7, 4, updateDoodlerY
	
	finishUpdateY:
	
	lw $t1, scoreCounter
	beq $t1, 5, setLength
	
	finishSetLength:
	
	lw $t1, shiftCounter
	bne $t1, 0, shiftPlatforms
	
	finishShiftPlatforms:
	
	jal drawEntire
	jal generatePlatforms
	jal drawScore
	
	finishDrawScore:
	
	lw $t1, drawPogFrame
	bgtz $t1, drawPog
	
	finishDrawPog:
	
	jal drawDoodler
	jal sleep
	finishSleep:
	
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
	lw $t1, score
	bgt $t1, 10, sleep2
	
	li $v0, 32
	li $a0, 33
	syscall
	
	j finishSleep
	
	sleep2:
	bgt $t1, 20, sleep3
	
	li $v0, 32
	li $a0, 22
	syscall
	
	j finishSleep
	
	sleep3:
	
	li $v0, 32
	li $a0, 16
	syscall
	
	j finishSleep

#Updates the Y position of Doodler
updateDoodlerY:
	j setT7
	finishSetT7:
	lw $t0, displayAddress
	lw $t2, doodlerPosY
	la $a0, doodlerPosY
	lw $t3, doodlerPosX
	la $a1, doodlerJumpLen
	lw $t4, doodlerJumpLen
	lw $t5, doodlerUp
	la $a2, doodlerUp
	lw $t6, platformCol
	#The doodler is currently going up
	beq $t5, 1, goUp
	
	mul $t3, $t3, 4
	mul $t2, $t2, 128
	add $t0, $t0, $t2
	add $t0, $t0, $t3
	add $t0, $t0, 128
	lw $t4, 0($t0)
	#The doodler hit a platform
	beq $t4, $t6, startUp
	#The doodler  is going down
	lw $t2, doodlerPosY
	add $t2, $t2, 1
	sw $t2, 0($a0)
	lw $t4, doodlerJumpLen
	add $t4, $t4, -1
	sw $t4, 0($a1)
	
	j finishUpdateY
	#The logic for moving the doodler up
	startUp:
		li $t4, 1
		li $t7, 3
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
			li $t3, 0
			sw $t4, 0($a2)
			
			lw $t3, doodlerJumpLen
			add $t3, $t3, -1
			sw $t3, 0($a1)
			
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
	la $a0, drawPogFrame
	li $t2, 1
	sw $t2 0($a0)
	
	la $a0, drawPogCounter
	lw $t2, drawPogCounter
	
	beq $t2, 3, setPogCounter
	
	add $t2, $t2, 1
	sw $t2, 0($a0)
	j finishPogCounter
	
	setPogCounter:
	li $t2, 1
	sw $t2, 0($a0)
	
	finishPogCounter:
	
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
	li $t1, 0
	la $a0, scoreCounter
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
	lw $t1, t7Help
	
	beq $t1, 1, startShift
	
	j finishShiftPlatforms
	startShift:
	li $t1, 0
	la $a0, t7Help
	sw $t1, 0($a0)
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
#Divides the number properly in order to draw numbers in the correct location	
drawScore:
	lw $t1, score
	div $t2, $t1, 1000
	lw $t3, displayAddress
	add $t3, $t3, 68
	
	jal drawNumber
	
	mul $t4, $t2, 1000
	sub $t1, $t1, $t4
	
	div $t2, $t1, 100
	
	add $t3, $t3, 16
	
	jal drawNumber
	
	mul $t4, $t2, 100
	sub $t1, $t1, $t4
	
	div $t2, $t1, 10
	
	add $t3, $t3, 16
	
	jal drawNumber
	
	mul $t4, $t2, 10
	sub $t1, $t1, $t4
	
	div $t2, $t1, 1
	
	add $t3, $t3, 16
	
	jal drawNumber
	
	j finishDrawScore

#Draws the correct number	
drawNumber:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	beq $t2, 0, drawZero
	beq $t2, 1, drawOne
	beq $t2, 2, drawTwo
	beq $t2, 3, drawThree
	beq $t2, 4, drawFour
	beq $t2, 5, drawFive
	beq $t2, 6, drawSix
	beq $t2, 7, drawSeven
	beq $t2, 8, drawEight
	beq $t2, 9, drawNine
	
	lw $ra, 0($sp)
	addi, $sp, $sp, 4
	
	jr $ra
	
drawZero:
	lw $t4, colBlack
	sw $t4, 0($t3)
	sw $t4, 4($t3)
	sw $t4, 8($t3)
	sw $t4, 128($t3)
	sw $t4, 136($t3)
	sw $t4, 256($t3)
	sw $t4, 264($t3)
	sw $t4, 384($t3)
	sw $t4, 392($t3)
	sw $t4, 512($t3)
	sw $t4, 516($t3)
	sw $t4, 520($t3)
	
	jr $ra
	
drawOne:
	lw $t4, colBlack
	sw $t4, 0($t3)
	sw $t4, 4($t3)
	sw $t4, 132($t3)
	sw $t4, 260($t3)
	sw $t4, 388($t3)
	sw $t4, 512($t3)
	sw $t4, 516($t3)
	sw $t4, 520($t3)
	
	jr $ra

drawTwo:
	lw $t4, colBlack
	sw $t4, 0($t3)
	sw $t4, 4($t3)
	sw $t4, 8($t3)
	sw $t4, 136($t3)
	sw $t4, 256($t3)
	sw $t4, 260($t3)
	sw $t4, 264($t3)
	sw $t4, 384($t3)
	sw $t4, 512($t3)
	sw $t4, 516($t3)
	sw $t4, 520($t3)
	
	jr $ra
	
drawThree:
	lw $t4, colBlack
	sw $t4, 0($t3)
	sw $t4, 4($t3)
	sw $t4, 8($t3)
	sw $t4, 136($t3)
	sw $t4, 256($t3)
	sw $t4, 260($t3)
	sw $t4, 264($t3)
	sw $t4, 392($t3)
	sw $t4, 512($t3)
	sw $t4, 516($t3)
	sw $t4, 520($t3)
	
	jr $ra

drawFour:
	lw $t4, colBlack
	sw $t4, 0($t3)
	sw $t4, 8($t3)
	sw $t4, 128($t3)
	sw $t4, 136($t3)
	sw $t4, 256($t3)
	sw $t4, 260($t3)
	sw $t4, 264($t3)
	sw $t4, 392($t3)
	sw $t4, 520($t3)
	
	jr $ra
	
drawFive:
	lw $t4, colBlack
	sw $t4, 0($t3)
	sw $t4, 4($t3)
	sw $t4, 8($t3)
	sw $t4, 128($t3)
	sw $t4, 256($t3)
	sw $t4, 260($t3)
	sw $t4, 264($t3)
	sw $t4, 392($t3)
	sw $t4, 512($t3)
	sw $t4, 516($t3)
	sw $t4, 520($t3)
	
	jr $ra
	
drawSix:
	lw $t4, colBlack
	sw $t4, 0($t3)
	sw $t4, 128($t3)
	sw $t4, 256($t3)
	sw $t4, 260($t3)
	sw $t4, 264($t3)
	sw $t4, 384($t3)
	sw $t4, 392($t3)
	sw $t4, 512($t3)
	sw $t4, 516($t3)
	sw $t4, 520($t3)
	
	jr $ra
	
drawSeven:
	lw $t4, colBlack
	sw $t4, 0($t3)
	sw $t4, 4($t3)
	sw $t4, 8($t3)
	sw $t4, 136($t3)
	sw $t4, 264($t3)
	sw $t4, 392($t3)
	sw $t4, 520($t3)
	
	jr $ra
	
drawEight:
	lw $t4, colBlack
	sw $t4, 0($t3)
	sw $t4, 4($t3)
	sw $t4, 8($t3)
	sw $t4, 128($t3)
	sw $t4, 136($t3)
	sw $t4, 256($t3)
	sw $t4, 260($t3)
	sw $t4, 264($t3)
	sw $t4, 384($t3)
	sw $t4, 392($t3)
	sw $t4, 512($t3)
	sw $t4, 516($t3)
	sw $t4, 520($t3)
	
	jr $ra
	
drawNine:
	lw $t4, colBlack
	sw $t4, 0($t3)
	sw $t4, 4($t3)
	sw $t4, 8($t3)
	sw $t4, 128($t3)
	sw $t4, 136($t3)
	sw $t4, 256($t3)
	sw $t4, 260($t3)
	sw $t4, 264($t3)
	sw $t4, 392($t3)
	sw $t4, 520($t3)
	
	jr $ra

#Set how many frames before the next drawing of the doodler	
setT7:
	li $t4, 1
	la $a0, t7Help
	sw $t4, 0($a0)
	lw $t1, doodlerJumpLen
	
	bgt $t1, 5, setT72
	
	li $t7, 3
	j finishSetT7
	
	setT72:
		bgt $t1, 8, setT73
		li $t7, 2
		j finishSetT7
	
	setT73:
		li $t7, 1
		j finishSetT7
		

#Drawing the messages		
drawPog:
	lw $t2, drawPogFrame
	beq $t2, 50, stopDrawFrame
	la $a0, drawPogFrame
	add $t2, $t2, 1
	sw $t2, 0($a0)
	
	lw $t1, drawPogCounter
	beq $t1, 1, sketchPog
	beq $t1, 2, sketchWow
	j sketchNice
	
	stopDrawFrame:
	la $a0, drawPogFrame
	sw $zero, 0($a0)
	
	j finishDrawPog
	
sketchPog:
	lw $t1, displayAddress
	lw $t2, colGreen
	add $t1, $t1, 2104
	sw $t2, 0($t1)
	sw $t2, 4($t1)
	sw $t2, 8($t1)
	sw $t2, 32($t1)
	sw $t2, 36($t1)
	sw $t2, 40($t1)
	sw $t2, 48($t1)
	sw $t2, 128($t1)
	sw $t2, 136($t1)
	sw $t2, 160($t1)
	sw $t2, 168($t1)
	sw $t2, 176($t1)
	sw $t2, 256($t1)
	sw $t2, 260($t1)
	sw $t2, 264($t1)
	sw $t2, 272($t1)
	sw $t2, 276($t1)
	sw $t2, 280($t1)
	sw $t2, 288($t1)
	sw $t2, 292($t1)
	sw $t2, 296($t1)
	sw $t2, 304($t1)
	sw $t2, 384($t1)
	sw $t2, 400($t1)
	sw $t2, 408($t1)
	sw $t2, 424($t1)
	sw $t2, 512($t1)
	sw $t2, 528($t1)
	sw $t2, 532($t1)
	sw $t2, 536($t1)
	sw $t2, 548($t1)
	sw $t2, 552($t1)
	sw $t2, 560($t1)
	
	j finishDrawPog
	
sketchWow:
	lw $t1, displayAddress
	lw $t2, colGreen
	add $t1, $t1, 2232
	sw $t2, 0($t1)
	sw $t2, 16($t1)
	sw $t2, 40($t1)
	sw $t2, 56($t1)
	sw $t2, 64($t1)
	sw $t2, 128($t1)
	sw $t2, 136($t1)
	sw $t2, 144($t1)
	sw $t2, 152($t1)
	sw $t2, 156($t1)
	sw $t2, 160($t1)
	sw $t2, 168($t1)
	sw $t2, 176($t1)
	sw $t2, 184($t1)
	sw $t2, 192($t1)
	sw $t2, 256($t1)
	sw $t2, 264($t1)
	sw $t2, 272($t1)
	sw $t2, 280($t1)
	sw $t2, 288($t1)
	sw $t2, 296($t1)
	sw $t2, 304($t1)
	sw $t2, 312($t1)
	sw $t2, 384($t1)
	sw $t2, 388($t1)
	sw $t2, 392($t1)
	sw $t2, 396($t1)
	sw $t2, 400($t1)
	sw $t2, 408($t1)
	sw $t2, 412($t1)
	sw $t2, 416($t1)
	sw $t2, 424($t1)
	sw $t2, 428($t1)
	sw $t2, 432($t1)
	sw $t2, 436($t1)
	sw $t2, 440($t1)
	sw $t2, 448($t1)
	add $t1, $t1, -128
	sw $t2, 0($t1)
	sw $t2, 16($t1)
	sw $t2, 40($t1)
	sw $t2, 56($t1)
	sw $t2, 64($t1)
	
	j finishDrawPog
	
sketchNice:
	lw $t1, displayAddress
	lw $t2, colGreen
	add $t1, $t1, 2104
	sw $t2, 0($t1)
	sw $t2, 4($t1)
	sw $t2, 8($t1)
	sw $t2, 16($t1)
	sw $t2, 24($t1)
	sw $t2, 28($t1)
	sw $t2, 32($t1)
	sw $t2, 40($t1)
	sw $t2, 44($t1)
	sw $t2, 48($t1)
	sw $t2, 56($t1)
	sw $t2, 128($t1)
	sw $t2, 136($t1)
	sw $t2, 152($t1)
	sw $t2, 168($t1)
	sw $t2, 176($t1)
	sw $t2, 184($t1)
	sw $t2, 256($t1)
	sw $t2, 264($t1)
	sw $t2, 272($t1)
	sw $t2, 280($t1)
	sw $t2, 296($t1)
	sw $t2, 300($t1)
	sw $t2, 304($t1)
	sw $t2, 312($t1)
	sw $t2, 384($t1)
	sw $t2, 392($t1)
	sw $t2, 400($t1)
	sw $t2, 408($t1)
	sw $t2, 424($t1)
	sw $t2, 512($t1)
	sw $t2, 520($t1)
	sw $t2, 528($t1)
	sw $t2, 536($t1)
	sw $t2, 540($t1)
	sw $t2, 544($t1)
	sw $t2, 552($t1)
	sw $t2, 556($t1)
	sw $t2, 560($t1)
	sw $t2, 568($t1)
	
	j finishDrawPog
	
Exit:
	li $v0, 10 # terminate the program gracefully
	syscall
