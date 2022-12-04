#name: Alicia Nguyen		
#studentID: 260424285

.data
#Must use accurate file path.
#file paths in MARS are relative to the mars.jar file.
# if you put mars.jar in the same folder as test2.txt and your.asm, input: should work.
input:	.asciiz "test1.txt"
output:	.asciiz "flipped.pgm"	#used as output
axis: .word 1 # 0=flip around x-axis....1=flip around y-axis
buffer:  .space 2048		# buffer for upto 2048 bytes
newbuff: .space 2048

#any extra data you specify MUST be after this line 
writebuff: .space 2048

errorOpen: .asciiz 	"There was an error and this file could not be opened."
errorRead: .asciiz 	"There was an error and this file could not be read."
errorClose: .asciiz 	"There was an error and this file was not closed properly."
errorWrite: .asciiz 	"There was an error and the file was not written to properly."
sucRead: .asciiz 	"The file was read successfully."
sucWrite: .asciiz 	"The file was written to successfully."
bufContentMsg: .asciiz   "The contents of the buffer are: \n" 

#Debugging Statements
BufConvSRMsg: .asciiz "Case 3: The value added to the buffer was: \n."
BufConvSRMsg1: .asciiz "Got into Case 2, value stored was: \n."
BufConvSRMsg2: .asciiz "In the case where nothing added to newbuff \n."
BufConvSRMsg3: .asciiz "In the case 'almost end' \n."
BufConvSRMsg4: .asciiz "LOOP End \n."
BufConvSRMsg6: .asciiz "Got into convert buff subroutine\n."
flipMsg1: .asciiz "\n The value of i is: "
flipMsg2: .asciiz "\n The value of j is: "
flipMsg3: .asciiz "\n A's loaded byte is: "
flipMsg4: .asciiz "\n B's loaded byte is: "


format: .asciiz "P2\n24 7\n15\n"

	.text
	.globl main

main:
    la $a0,input	#readfile takes $a0 as input
    jal readfile #input: buffer output: newbuff
    #$v0 should contain the number of bytes read to newbuff
    move $s1, $v0
				
	la $a0,buffer		#$a0 will specify the "2D array" we will be flipping
	la $a1,newbuff		#$a1 will specify the buffer that will hold the flipped array.
	la $a2,axis       	#either 0 or 1, specifying x or y axis flip accordingly
	jal flip			#input: newbuff output:newbuff (we flip in place)

	la $a0, output		#writefile will take $a0 as file location we wish to write to.
	la $a1,newbuff		#$a1 takes location of what data we wish to write.
	move $a2, $s1		#pass argument of how many bytes to read from newbyff
	la $a3,writebuff		#pass the adress of writebuff in a3
	jal writefile		#input: flipbuff output: writebuff

	li $v0,10		# exit
	syscall

	#input: buffer output: newbuff
	#This routine uess the Q1a routine but adds a subroutine that 
	#stores the ascii characters as integers (2d in 1d array)
readfile:
	#Open the file to be read,using $a0
	#$a0 contains a pointer to the file we've hardcoded as input
	li $v0, 13
	li $a1, 0	#$a0 already contains pointer, gets 0 because we're only reading
	li $a2, 0	#ignore the mode?
	syscall

	#Conduct error check, to see if file exists
	slt  $t0, $v0, $zero 			#set $t0 to 1 if we got a $v0 that was negative (error)
	beq $t0, $zero, openSuccess		#if there's no error indicating 1 in $t0, jump to ok case

	li  $v0, 4				# print the error prompt
	la  $a0, errorOpen
	syscall	

	#just exit if the file doesn't exist (if we make the input not hardcoded, change to re-enter)
	li $v0, 10
	syscall

    openSuccess:

	# You will want to keep track of the file descriptor*
	move  $t1, $v0	#file descriptor placed in $t1

	# read from file
	# use correct file descriptor, and point to buffer
	# hardcode maximum number of chars to read
	# read from file

	move  $a0, $t1		#file descriptor now in a0
	la $a1,buffer		#load the address of the buffer into a1
	li $a2, 2048	#load max number of chars CAREFUL WITH HARDCODING
	li $v0, 14
	syscall

	#conduct error check to see if read was successful
	slt $t0, $v0, $zero 			#set $t0 to 1 if we got a $v0 that was negative (error)
	beq $t0, $zero, readSuccess		#if there's no error indicating 1 in $t0, jump to ok case

	li  $v0, 4				# print the error prompt
	la  $a0, errorRead
	syscall	

	#just exit if the file didn't read properly
	li $v0, 10
	syscall

    readSuccess:

	# address of the ascii string you just read is returned in $v1. ??????
	# the text of the string is in buffer
	#print contents of what we've read from the buffer onto the screen
	li $v0, 4
	la $a0, buffer
        syscall
	
	# close the file (make sure to check for errors)
	li $v0, 16
	move $a0, $t1 		#maybe already in there? move file descritor into a0 maybe again
	syscall
	
	#give a read successfully message
	#give a written successfully message
	li  $v0, 4				
	la  $a0, sucRead
	syscall	

	#we're going to call a subroutine from this routine
	#save return address onto stack WHAT ABOUT LOSING STACK VALUES?
	addi $sp, $sp, -4 #decrement stack pointer
	sw $ra, 0($sp) #save ret address

	#call subroutine to convert the ascii buffer to int newbuffer
	jal convertBuffToInt

	#restore stack values and pointer
	lw $ra, 0 ($sp) #restore read's return address

	jr $ra
	
	#subroutine to convert ascii buffer to int newbuffer
	#The logic of this subroutine is to use 3 pointers, 2 will traverse input buffer, value A
	#They will determine the 'case' of how to read the ascii chars and store into the output buffer
	#using the 3rd pointer	
	#this method INTENTIONALLY uses only temp registers for easier implementation later (though it looks ugly here)
	convertBuffToInt:

		#what are these for?
		la $t0, buffer #address of input buffer
		la $t1, newbuff #address of output buffer
		
		la $t2, buffer #(A)address pointer to input buffer current location
		la $t3, buffer #(B)'roving' pointer to find spaces and newlines in input buffer 
		la $t4, newbuff #address pointer to OUTPUT buffer to current location
		move $t5, $zero #counter of how many chars in output buffer
		
		#loaded values from input will be referred to as A and B
		move $t6, $zero #A:loaded value of input buffer current location pointer
		move $t7, $zero #B:loaded value of input buffer roving pointer
		move $t8, $zero #value getting stored in output buffer
		move $t9, $zero #branch decision variable
				
		#making the assumption here that the buffer that has not been filled is filled with null (0)
		#addi $t2, $t2, 1
		addi $t3, $t3, 1 #update roving pointer (B), always one ahead
	
	loop:		
		
		lb $t6 0($t2)	#(A)load byte from input buffer CL pointer	
		lb $t7 0($t3)	#(B)load byte from input buffer roving pointer
		move $t8, $zero  #erase any contents of t8
																						
		#check loop condition here
		beq $t7, $zero, loopAlmostEnd #if t6 or t7 are NULL, finish writing to array then done!
		beq $t6, $zero, loopEnd #really shouldn't hit this case unless even $?
		
		#ask if input A is a number
		slti $t9, $t6, 58 #set t9 to 1 if t6 val is less than 58 (indicating a number)
		beq $t9, $zero, inputAnotNum #branch if t9=0, meaning more than 58
		slti $t9, $t6, 48 #set t9 to 1 if t6 val is less than 48 (indicating it's NOT a number)
		bne $t9, $zero, inputAnotNum
		
		#if we got here we've established input A is a number
		#now check input B
		slti $t9, $t7, 58 #set t9 to 1 if t7 val is less than 58 (indicating a number)
		beq $t9, $zero, AisNumBnotNum #branch if t9=0, meaning more than 58
		slti $t9, $t7, 48 #set t9 to 1 if t7 val is less than 48 (indicating it's NOT a number)
		bne $t9, $zero, AisNumBnotNum
		
		#Case 3		#if we got here BOTH values of A and B are numbers (Case 3)

		addi $t6, $t6, -48	#convert both from ascii to int
		mul $t6, $t6, 10 #multiply by 10 because higher order digit 
		addi $t7, $t7, -48
		add $t8, $t6, $t7 #add the converted values of t6 and t7 to t8
		sb  $t8, 0($t4)  #store into the output array
		
		#UPDATE CASE 3 POINTERS
		addi $t5, $t5, 1 #update counter of how many bytes used in newbuff
		addi $t2, $t2, 2 #(A)update input pointer current location
		addi $t3, $t3, 2	#*(B)update input pointer roving
		addi $t4, $t4, 1 #update output address pointer
		
		j loop
	 	 	 
		#Case 2
	AisNumBnotNum:
		addi $t6, $t6, -48 #convert ascii to int
		sb $t6, 0($t4) #store in output buffer
		
		#UPDATE CASE 2 POINTERS
		addi $t5, $t5, 1 #update counter of how many bytes used in newbuff
		addi $t2, $t2, 1 #(A)update input pointer current location
		addi $t3, $t3, 1	#*(B)update input pointer roving
		addi $t4, $t4, 1 #update output address pointer
		
		j loop


		# Case 1 A is not a number so we don't care what B is		
	inputAnotNum:
		#update pointers for another loop iteration BUT no counts
		addi $t2, $t2, 1 #(A)update input pointer current location
		addi $t3, $t3, 1	#*(B)update input pointer roving
		j loop		
		
		#sent here if $t7 NULL
	loopAlmostEnd:
		slti $t9, $t6, 58 #set t9 to 1 if t6 val is less than 58 (indicating a number)
		beq $t9, $zero, loopEnd #branch if t9=0, meaning more than 58
		slti $t9, $t6, 48 #set t9 to 1 if t6 val is less than 48 (indicating it's NOT a number)
		bne $t9, $zero, loopEnd
	
		#IF the last byte is a number
		addi $t6, $t6, -48 #convert ascii to int
		sb $t6 ($t4) #store in output buffer
		addi $t5, $t5, 1 #update counter of how many bytes used in newbuff
		
	loopEnd:
	
		#return with how many bytes (relavant chars copied) in $v0
		add $v0, $t5, $zero
		 jr $ra	 

	#input: newbuff output:newbuff (we flip in place)
	#this subroutine flips depending on the value given using nested for loops that scan
	#as though this was a 2d array, so conversions between 2d and 1d arrays can happen
	#for flipping we cycled through the elements, saved the byte, and then stored the byte
	#again at the appropriate address (depending on the flip)
flip:
	#Can assume 24 by 7 again for the input.txt file
	#Flip by skimming through 1d array like double nested for loop for 2d array
	#use a temp reg to sort in place 
	#use A and B pointers in the buffer (relative to eachother) to get the values
	#a0 contains buff
	#a1 contains newbuff
	#a2 contains axis address

	#axis: .word 1 # 0=flip around x-axis....1=flip around y-axis
	lb $a2 0($a2) #load the axis bit
	beq $a2, $zero, flipXaxis

	#Case where we flip around Y-axis
	move $t0, $zero #i value (address?)
	move $t1, $zero #j value (address?)
	la $t2, newbuff #address of pointer A starting at the buffer
	move $t3, $zero # byte loaded from pointer A
	move $t4, $zero #address of pointer B
	move $t5, $zero #byte loaded from Pointer B
	move $t6, $zero #the register where we will store our temp value in
	move $t7, $zero #register containing the width variable
	move $t8, $zero #register containing height variable
	move $t9, $zero #register for branch decisions, borrowed for array address calclations

	######CAREFUL OFF BY ONE ERROR
	addi $t7, $t7, 24#register containing the width variable 24 (x)
	addi $t8, $t8, 7	#register w height variable 7 (y)

   for1:	

   for2:   #so pointer A, an address in t2 starts off pointing to the new buffer

	###########contents we change for flip other axis or transpose	
	#calculate A address offset, we loaded A's address in t2
	mul $t6, $t0,$t7 #(i*x)
	add $t6, $t6, $t1 #(i*x)+j 
	add $t9, $t2, $t6 #add the offset we just calculated, t9 holds address a with offset
	
	lb $t3,($t9) #load pointer A's byte
	
	move $t6, $zero		#clear temp registers
	
	#calculate pointer B's offset: [i*x] + (x-j-1)
	mul $t4, $t0, $t7 #[i* x] stored in B's address reg t4
	sub $t6, $t7, $t1 #(x-j) stored in t6
	addi $t6, $t6, -1 #complete (x-j-1) in t6
	add  $t4, $t4, $t6 #array[i*x] + (x-j-1)
	add $t4, $t4, $t2 #add calculated pointer B's address as offset to A's address, B's address now accurate
	lb $t5, ($t4) #load pointer B's byte
	
	move $t6, $zero #clear temp register
	

		
	#now swap the bytes in place in the array!
	sb $t3, ($t4) #save pointer A's loaded byte to B's address WITH OFFSET
 	sb $t5 ($t9) #save pointer B's loaded byte to A's address WITH OFFSET
	
	###########
	#check inner (for2) conditions
	addi $t1, $t1, 1 #update inner for loop 1 counter (j value)
	slti $t9, $t1, 12 #set t9 to 1 if j<width24 /2 ##############TRIED NOT TO HARDCODE BUT I HAD TO
	bne $t9, $zero, for2
	
	move $t1, $zero #reset j value 

	#check outter loop (for1) conditions
	addi $t0, $t0, 1 #update outter for loop 1 counter (i value)
	slt $t9, $t0, $t8 #check if i<height7 
	bne $t9, $zero, for1

	j endFlip

	flipXaxis:
	
	#Case where we flip around X-axis
	move $t0, $zero #i value 
	move $t1, $zero #j value
	la $t2, newbuff #loaded address of input AND output buffer
	move $t3, $zero #Pointer A
	move $t4, $zero #Pointer A (Input) Loaded Byte
	move $t5, $zero #TEMP
	move $t6, $zero ##Counter k (A's offset)
	move $t7, $zero #register containing the width variable
	move $t8, $zero #register containing height variable
	move $t9, $zero #register for branch decisions

	addi $t7, $t7, 24#register containing the width variable 24
	addi $t8, $t8, 7	#register w height variable 7

   forA:	

   forB:   

	li $v0, 4
	la $a0, flipMsg1
	syscall
	li $v0, 1
	move $a0, $t0 
	syscall
	
	li $v0, 4
	la $a0, flipMsg2
	syscall
	li $v0, 1
	move $a0, $t1 
	syscall
	
	##########contents we change for flip other axis or transpose	

	#Calculate Input Pointer A (Offset k + address in t2)
	add $t3, $t2, $t6

	#calculate output Pointer B (offset + address in t2)
	#calculate offset :(Y-i-1)*x)+j
	sub $t5, $t8, $t0 #y-i
	addi $t5, $t5, -1 #(Y-i-1)
	mul $t5, $t5, $t7 #(Y-i-1)*x)
	add $t5, $t5, $t1 #(Y-i-1)*x)+j
	
	#add address
	add $t5, $t5, $t2
	
	#load and switch bytes (oops gotta borrow t9)
	lb $t4, 0($t3) #load input byte from A
	lb $t9, 0($t5) #load byte from B
	
	sb $t9, 0($t3)	#sb into A
	sb $t4, 0($t5)	#sb into B
			
	addi $t6, $t6, 1 #update k counter			
	######################################
	#check inner (for2) conditions
	addi $t1, $t1, 1 #update inner for loop 1 counter (j value)
	slt $t9, $t1, $t7 #set t9 to 1 if j<width24
	bne $t9, $zero, forB
	
	move $t1, $zero #reset j value 

	#check outter loop (for1) conditions
	addi $t0, $t0, 1 #update outter for loop 1 counter (i value)
	slti $t9, $t0, 3 #check if i<height7/2 ###########TRIED NOT TO HARDCODE BUT I HAD TO
	bne $t9, $zero, forA

   endFlip: 
	jr $ra	


	#input: newbuff output: writebuff
	#largely the same as Q1b but we have to convert the integer array back into a suitable ascii array
	#this is done just by inserting spaces between values	
writefile:

	#use as many arguments as you would like to get this to work.
	#a0 has output address 
	#a1 has newbuff address
	#a2 how many numbers in newbuff
	#a3 address of writebuff

	#first write the integer contents of newbuff basck into writebuff ascii array
	move $t0, $a1 #newbuff address pointer
	move $t1, $a3 #writebuff address pointer
	move $t2, $a2 #how many numbers in new buff to write
	
	li $t3, 0 #counter for how many numbers written
	move $t4, $zero #even or odd variables
	move $t5, $zero #loaded byte from new buff
	li $t6, 32 #space ascii code for insertion of whitespace
	move $t7, $zero #calculation register for ascii conversion
	move $t8, $zero #calculation register for ascii conversion
		
   writeloop: 

	#write the number	
	lb $t5 0($t0) #load the byte from newbuff
	
	#WE NEED TO CHECK IF ONE OR TWO ASCII CHARS
	addi $t7, $t5, 48 #convert it back to an ascii character value
	#check if this calls in our range (indicating it's a one digit number)
	slti  $t8, $t7, 48
	sgt   $t8, $t7, 57
	beq $t8, $zero, oneDigit
	
	#case where it's a two digit number, do different ascii conversion
	#our original loaded byte is in t5 (x)			
	#t7 for lower order #t8 for higher order
	rem $t7, $t5, 10 #x%10 to get lower order in t7
	sub $t8, $t5, $t7#get higher order digits into t8 x-(x%10)
	div $t8, $t8, 10 #finish getting higher order digit
	
	#now actually convert to ascii again
	addi $t7, $t7, 48
	addi $t8, $t8, 48
	
	#store them in the writebuffarray
	sb $t8, 0($t1) #store the higher order digit
	addi $t1, $t1, 1 #incremenet writebuff address by 1
	sb $t7, 0($t1) #store the lower order digit
	
	j update	
																																							
    oneDigit: 	sb $t7, 0 ($t1) #save the converted number to writebuff 

	#update pointers for this case
    update:	addi $t0, $t0, 1 #update the newbuff pointer
	addi $t1, $t1, 1 #update the writebuff pointer
	addi $t3, $t3, 1 #update the counter of how many numbers written

	#write a space	
	sb $t6, 0($t1) 
	addi $t1, $t1, 1 #update writebuff pointer

	#while the counter is less than t2 (number of numbers in newbuff), keep writing
	slt  $t9, $t3, $t2
	bne $t9, $zero, writeloop	
	
	#save arguments passed to writefile into t registers
	move $t0, $a0		#address of the file location output now in t0
	move $t1, $a1		#address of newbuff now in in $t1
	move $t3, $a2		#count of how many bytes to read from newbuff
	move $t4, $a3		#address of writebuff
	
	#open file to be written to, using $a0.
	li $v0, 13
	move $a0, $t0		#pass the file descriptor address as an arugment
	li $a1, 1		#flag this open as writing kind of open
	li $a2, 0		#ignore mode
	syscall
	
	#Conduct error check, to see if file exists (and is opened sucessfully)
	slt $t0, $v0, $zero 			#set $t0 to 1 if we got a $v0 that was negative (error)
	beq $t0, $zero, openSuccess2		#if there's no error indicating 1 in $t0, jump to ok case

	li  $v0, 4				# print the error prompt
	la  $a0, errorOpen
	syscall	

	#just exit if the file doesn't exist (if we make the input not hardcoded, change to re-enter)
	li $v0, 10
	syscall

    openSuccess2:
	
	move  $t2, $v0		#file descriptor is now saved in $t2

	#write the header info into the file
	li $v0, 15
	move $a0, $t2	#mode the file descriptor into a0
	la $a1, format	#write the formatting string to the file
	li $a2, 11	#formatting string is 11 chars long
	syscall

	#write the content of writebuff to file
	li $v0, 15
	move $a0, $t2	#file descriptor placed in a0
	move $a1, $t4	#address of input buffer placed in a1
	add $t3,$t3,$t3 #number of bytes to read from newbuff (we've doubled it bc of spacesP)
	move $a2, $t3	#number of bytes to read from bewbuff	
	syscall

	#close the file (make sure to check for errors)
	li $v0, 16
	move $a0, $t2 		
	syscall

	#give a written successfully message
	li  $v0, 4				
	la  $a0, sucWrite
	syscall	

	jr $ra