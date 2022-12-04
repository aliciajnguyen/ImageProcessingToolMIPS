#name: Alicia Nguyen		
#studentID: 260424285

.data

#Must use accurate file path.
#file paths in MARS are relative to the mars.jar file.
# if you put mars.jar in the same folder as test2.txt and your.asm, input: should work.
input:	.asciiz "test1.txt"
output:	.asciiz "borded.pgm"	#used as output

borderwidth: .word 3   #specifies border width
buffer:  .space 2048	# buffer for upto 2048 bytes
newbuff: .space 2048
headerbuff: .space 2048  #stores header

#any extra data you specify MUST be after this line 
borderbuff:.space 2048
writebuff: .space 2048

errorOpen: .asciiz 	"There was an error and this file could not be opened."
errorRead: .asciiz 	"There was an error and this file could not be read."
errorClose: .asciiz 	"There was an error and this file was not closed properly."
errorWrite: .asciiz 	"There was an error and the file was not written to properly."
sucRead: .asciiz 	"The file was read successfully."
sucWrite: .asciiz 	"The file was written to successfully."

writeMsg: .asciiz "\n The contents of the headerbuff are: " 

loopMsg: .asciiz "\nThe contents of i are: "
loopMsg2: .asciiz "\nThe contents of j are: "
loopMsg3: .asciiz "\nThe value of k is: "
bordMsg1: .asciiz "\n Case entered to write from array."
bordMsg2: .asciiz "\n Case entered to write filling border"
bordMsg3: .asciiz "\n The value of the byte written to the output is: "
kBugMsg: .asciiz "\n THE VALUE WHEN RETURNING TO MAIN MENU IS: "

format: .asciiz "P2\n24  7\n15\n"

	.text
	.globl main

main:	la $a0,input		#readfile takes $a0 as input
	jal readfile
	#$v0 should contain the number of bytes read to newbuff
   	move $s1, $v0

	la $a0, newbuff		#$a1 will specify the "2D array" we will be flipping
	la $a1, borderbuff	#$a2 will specify the buffer that will hold the 'bordered' array.
	la $a2,borderwidth
	jal bord
	#returns updated numbre of elements valuein $v0
	
	move $s1, $v0

	la $a0, output		#writefile will take $a0 as file location
	la $a1,borderbuff		#$a1 takes location of what we wish to write
	move $a2, $s1		#pass argument of how many bytes to read from newbuff
	la $a3,writebuff		#pass the adress of writebuff in a3
	jal writefile

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


	#take newbuff as input and use borderbuff as output
	#this function uses the 2 for loops with iterations adjusted to match new height and width
	#we check the cases if the input pointer falls on a to-be-filled section or a to be filled
	#from array section, and takes input as such
bord:
	#a0=newbuff (input)
	#a1=CHANGED TO BORDERBUFF (output)
	#a2=borderwidth
	#Can assume 24 by 7 as input
	#Try to understand the math before coding!
	#EXAMPLE: if borderwidth=2, 24 by 7 becomes 28 by 11.
	
	#first save s registers to stack so we can use them
	addi $sp, $sp, -28
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	sw $s4, 16($sp)
	sw $s5, 20($sp)
	sw $s6, 24($sp)

	#initialize all registers	
	move $t0, $zero #i value
	move $t1, $zero #j value
	move $t2, $a0 #loaded address of input array (newbuff) (A)
	move $t3, $a1 #loaded address of output array (borderbuff) (B)
	move $t4, $zero #calculated A offset, then A pter (offset + address)
	move $t5, $zero #calculated B offset, then B pter (offset + address)
	move $t6, $zero #counter k (offset for B)
	move $t7, $zero #register containing the width variable
	move $t8, $zero #register containing height variable
	move $t9, $zero #register for branch decisions, borrowed for array address calclations

	lb $s0, 0($a2)   #s0 now contains the pxlwidth value
	move $s1, $zero #clear BECOMES NEW WIDTH X'
	move $s2, $zero #clear BECOMES NEW HEiGHT Y'
	move $s3, $zero #transfer byte load register
	move $s4, $zero #clear register for temp calcs
	move $s5, $zero #clera register for temp calcs
	move $s6, $zero #clear reg for temp calcs
		
	addi $t7, $t7, 24#register containing the width variable 24 (x)
	addi $t8, $t8, 7	#register w height variable 7 (y)
	add $s1, $t7, $s0 #s1 adds first pxlwdth
	add $s1, $s1, $s0 #s1 adds second pixlwidth NOW CONTAINS X' NEW WIDTH
	add $s2, $t8, $s0 #s2 adds first pxlwidth
	add $s2, $s2, $s0 #adds second pixldith NOW CONTAINS Y' NEW HEIGHT
	

	#check register contents
	#la $a0, regCheck
	#li $v0, 4 
	#syscall
	#move $a0, $s2
	#li $v0, 1 
	#syscall

   for1:	

   for2:   #so pointer A, an address in t2 starts off pointing to the new buffer
	#li $v0, 4
	#la $a0, loopMsg
	#syscall
	#li $v0, 1
	#move $a0, $t0
	#syscall

	#li $v0, 4
	#la $a0, loopMsg2
	#syscall
	#li $v0, 1
	#move $a0, $t1
	#syscall


	###########contents we change for flip other axis or transpose	
	#BRANCH DECISIONS (if we fill in the border or fill in from the array)
	slt $t9, $t1, $s0 #if (j<pxlwidth), set t9 to 1 
	bne $t9, $zero, fillBorder
	
	#get NEWWIDTH -pxlwidth -1 into s4
	sub $s4, $s1, $s0 #NEWWIDTH - pxlwidth
	addi $s4, $s4, -1 #-1
	
	sgt $t9, $t1, $s4 #if (j>NEWWIDTH-pxlwidth-1)
	bne $t9, $zero, fillBorder
	
	slt $t9, $t0, $s0 #if (i<pxlwidth), set t9 to 1
	bne $t9, $zero, fillBorder
	
	#get NEWHEIGHT -pxlwidth -1 into s4
	sub $s4, $s2, $s0 #NEWHEIGHT - pxlwidth
	addi $s4, $s4, -1 #-1
	
	sgt $t9, $t0, $s4 #if (i>NEWHEIGHT -pxlwidth-1), set t9 to 1
	bne $t9, $zero, fillBorder

	#if we got here we're in case FILL FROM ARRAY
	#li $v0, 4
	#la $a0, bordMsg1
	#syscall
			
	#find pointer A
	#calculate offset IN OLD ARRAY ((i-pxlwidth)*x) + (j-pxlwidth)
	##############YOU BETTER HOPE YOUR MATH IS RIGHT
	#its not #NOW GOOD
	
	#work in s5 and s6
	sub $s5, $t0, $s0 #i-pxlwdth
	mul $s5, $s5, $t7 #(i-pxlwidth)*x)
	sub $s6, $t1, $s0 #(j-pxlwidth)
	add $s5, $s5, $s6 #((i-pxlwidth)*x) + (j-pxlwidth)
	                
        #add offset to loaded address to get pointer A
        add $t4, $s5, $t2 #t4 contains pointer a (offset + address)
        
        #find pointer B
        # b is just output array's loaded addrss and k offset
        add $t5, $t3, $t6
        
        #data transfer
        lb $s3, 0($t4) #load from A
        sb $s3, 0($t5) #save into B
        
        #li $v0, 4
	#la $a0, bordMsg3
	#syscall
	#li $v0, 1
	#move $a0, $s3
	#syscall
        
	j loopBordEnd

   fillBorder: 
	#case where we fill in the loop bordre
	#li $v0, 4
	#la $a0, bordMsg2
	#syscall
	
	
	move $s3, $zero     	#clear s3 just in case?
	addi $s3, $s3, 15	#we're adding the value 15 as the border
	
	#get B pointer
	add $t5, $t3, $t6 #b's pointer just output array's loaded address and k offset
	
	sb $s3, 0($t5) #store the byte in the output array
	
	#li $v0, 4
	#la $a0, bordMsg3
	#syscall
	#li $v0, 1
	#move $a0, $s3
	#syscall
		
    loopBordEnd:	
  	#k gets updated in both cases
    	addi $t6, $t6, 1
    	   
	####################################
	#li $v0, 4
	#la $a0, loopMsg3
	#syscall
	#li $v0, 1
	#move $a0, $t6
	#syscall

				
	#check inner (for2) conditions
	addi $t1, $t1, 1 #update inner for loop 1 counter (j value)
	slt $t9, $t1, $s1 #set t9 to 1 if j<NEW WIDTH (width + pxlbord + pxlbord) 
	bne $t9, $zero, for2
	
	move $t1, $zero #reset j value 

	#check outter loop (for1) conditions
	addi $t0, $t0, 1 #update outter for loop 1 counter (i value)
	slt $t9, $t0, $s2 #check if i< NEW HEIGHT (heigt + pxlbord + pxlbord) 
	bne $t9, $zero, for1

	#bug to look at later
	#return new number of elements transferred 
	#test add t6 to itself to see if this is what's throttling output
	add  $t6, $t6, $t6
	add $t6, $t6, $t6
	move $v0, $t6
	
	#restore s registers from stack
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	lw $s4, 16($sp)
	lw $s5, 20($sp)
	lw $s6, 24($sp)	
	addi $sp, $sp, 28
	
	jr $ra
	
	#largely the same as Q1b but we have to convert the integer array back into a suitable ascii array
	#this is done just by inserting spaces between values	
	#contains a subroutine that writes to the headerbuffer for insertio
	#takes input of borderbuff and outputs writebuff
writefile:
	
	#going to call subroutine writeHeader
	#don't take any arguments, since our t registers get set later, don't worry about saving
	#need to save the $ra on the stack though
	addi $sp, $sp, -4 #decrement stack pointer
	sw $ra, 0($sp) #save ret address

	#call subroutine to convert the ascii buffer to int newbuffer
	jal writeHeader

	#restore stack values and pointer
	lw $ra, 0 ($sp) #restore read's return address
	addi $sp, $sp, 4
	
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
	
	#SET REGISTERS FOR OPEN AND WRITE SECTION
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
	move $a0, $t2		#mode the file descriptor into a0
	la $a1, headerbuff	#write the formatting string to the file
	######################testing purposes this is set to format, but it should be set to headerbuff later
	li $a2, 12		#formatting string is 12 chars long
	syscall

	############## CHECK THE CONTENTS OF HEADERBUFF
	#li $v0, 4
	#la $a0, writeMsg
	#syscall
	
	#li $v0, 4
	#la $a0, headerbuff
	#syscall
	##############

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
		#subroutine that writes our header according to the new cropped dimensions
		#copies a prewritten asciiz string, calculates the new dimensions and inserts new dimensions as ascii chars
	writeHeader: 
		la $t0, format #t0 contains the address of the format template
		la $t1, headerbuff #$t1 contains adddress of the headerbuff output
		move $t2, $zero #contains B pointer (add immediate to adjust offset)
		#don't know if this will work, might be buggy
		la $t3, borderwidth
		lb $t3, 0($t3)
		move $t4, $zero
		move $t5, $zero #temp reg
		move $t6, $zero #temp reg
		move $t7, $zero #X or Y value calculated in the dimension
		move $t8, $zero #for dimensions calculations
		move $t9, $zero #forbranch decisions

		#Write format string to formatHeader buffer
	fHeaderloop:
		#get address of A
		add $t2, $t0, $t8 #address of input + i
		lb $t7, 0($t2)
		#clear t2
		move $t2, $zero
	
		#get addresss of B
		add $t2, $t1, $t8 #address of output + i
	
		#copy from A to B
		sb $t7, 0($t2)

		addi $t8, $t8, 1 #update loop counter (i)
		slti $t9, $t8, 12 #set t9 to 1 if still less than 12 (the length of NEW format header)
		bne $t9, $zero, fHeaderloop

		#reset temp registers
		move $t8, $zero
		move $t7, $zero

		#Calculate X Dim
		add $t7, $t3, $t3 #add t7 = pxlwidth + pxlwidth
		addi $t7, $t7, 24 
	
		#case check: 1 or 2 digits
		slti $t9, $t7, 10 #set t9 to 1 if the new dimension (in t7) is less than 10
		bne $t9, $zero, case2a
		
		#Case 1: 2 digit number
		rem $t8, $t7, 10 #dim%10 to get lower order in t7
		#store lower order byte in output address + offset 3 (total pointer in t2)
		addi $t2, $t1, 4 #HARDCODED to position 4 in the output array
		addi $t8, $t8, 48 #convert to ascii
		sb $t8, 0($t2) #store lower order digit in array at position 4
	
		addi $t8, $t8, -48 #convert back to int
		move $t2, $zero #make sure pointer in t2 is cleared
	
		#calculate higherorder digit
		sub $t7, $t7, $t8 #get higher order digit into t7, x-(x%10) (x%10) is in t8
		div $t7, $t7, 10 #finish getting higher order digit, now in t7
	
		addi $t7, $t7, 48 #convert to an ascii value
		addi $t2, $t1, 3 #get pointer (address of output + offset 3)
		sb $t7, 0($t2)
		j endXdim
	
		#Case 2: 1 digit number
   	    case2a:
		#store the first digit, our dimension
		addi $t7, $t7, 48 #convert to ascii character
		addi $t2, $t1, 3		
		sb $t7, 0($t2) #store the digit in the output array
	
		#write a space into the next digit
		li $t7, 32
		addi $t2, $t1, 4		
		sb $t7, 0($t2) #stiore the space in the output array	

    	    endXdim:				
		#Calculate Y dim
		add $t7, $t3, $t3 #add t7 = pxlwidth + pxlwidth
		addi $t7, $t7, 7 
	
		#case check: 1 or 2 digits
		slti $t9, $t7, 10 #set t9 to 1 if the new dimension (in t7) is less than 10
		bne $t9, $zero, case2b
		
		#Case 1: 2 digit number
		rem $t8, $t7, 10 #dim%10 to get lower order in t7
		#store lower order byte in output address + offset 3 (total pointer in t2)
		addi $t2, $t1, 7 #HARDCODED to position 4 in the output array
		addi $t8, $t8, 48 #convert to ascii
		sb $t8, 0($t2) #store lower order digit in array at position 4
	
		addi $t8, $t8, -48 #convert back to int
		move $t2, $zero #make sure pointer in t2 is cleared
	
		#calculate higherorder digit
		sub $t7, $t7, $t8 #get higher order digit into t7, x-(x%10) (x%10) is in t8
		div $t7, $t7, 10 #finish getting higher order digit, now in t7
	
		addi $t7, $t7, 48 #convert to an ascii value
		addi $t2, $t1, 6 #get pointer (address of output + offset 3)
		sb $t7, 0($t2)
		j endYdim
	
		#Case 2: 1 digit number
        	 case2b:
		#store the first digit, our dimension
		addi $t7, $t7, 48 #convert to ascii character
		addi $t2, $t1, 6		
		sb $t7, 0($t2) #store the digit in the output array
	
		#write a space into the next digit
		li $t7, 32
		addi $t2, $t1, 7		
		sb $t7, 0($t2) #stiore the space in the output array	
      	endYdim:
		jr $ra
