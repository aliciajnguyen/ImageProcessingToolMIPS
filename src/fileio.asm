#name: Alicia Nguyen
#studentID: 260424285

.data

#Must use accurate file path.
#file paths in MARS are relative to the mars.jar file.
# if you put mars.jar in the same folder as test2.txt and your.asm, input: should work.
input:	.asciiz "test1.txt" #used as input
output:	.asciiz "copy.pgm"	#used as output

buffer:  .space 2048		# buffer for upto 2048 bytes

errorOpen: .asciiz 	"There was an error and this file could not be opened."
errorRead: .asciiz 	"There was an error and this file could not be read."
errorClose: .asciiz 	"There was an error and this file was not closed properly."
errorWrite: .asciiz 	"There was an error and the file was not written to properly."
sucRead: .asciiz 	"The file was read successfully."
sucWrite: .asciiz 	"The file was written to successfully."

format: .asciiz "P2\n24 7\n15\n"

	.text
	.globl main

main:	la $a0,input		#readfile takes $a0 as input
	jal readfile

	la $a0, output		#writefile will take $a0 as file location
	la $a1,buffer		#$a1 takes location of what we wish to write.
	jal writefile

	li $v0,10		# exit
	syscall

readfile:

	#Open the file to be read,using $a0
	#$a0 contans a pointer to the file we've hardcoded as input
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
	#move $a0, $v1		#address of ascii string, otherwise load address of the buffer?
	la $a0, buffer
 
	#li $a1, 2048		#HARDCODED BUFFER MAX
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

	jr $ra

writefile:
	#save arguments passed into t registers
	move $t0, $a0		#address of the file location  OF OUTPUT now in $t0
	move $t1, $a1		#address of buffer now in in $t1

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

	#write the specified characters as seen on assignment PDF: #P2 #24 7 #15
	li $v0, 15
	move $a0, $t2	#mode the file descriptor into a0
	la $a1, format	#write the formatting string to the file
	li $a2, 11	#formatting string is 11 chars long
	syscall

	#######ACCORDING TO MYCOURSES we're only checking open success, not write success	
	#conduct error check to see if write was successful
	slt $t0, $v0, $zero 			#set $t0 to 1 if we got a $v0 that was negative (error)
	beq $t0, $zero, writeSuccess2		#if there's no error indicating 1 in $t0, jump to ok case

	li  $v0, 4				# print the error prompt
	la  $a0, errorWrite
	syscall	

	#just exit if the file didn't read properly
	li $v0, 10
	syscall

    writeSuccess2:

	#write the content stored at the address in $a1 (which has been moved to $t1)
	li $v0, 15
	move $a0, $t2	#file descriptor placed in a0
	move $a1, $t1	#address of input buffer placed in a1
	li $a2, 2048
	##################just added the entire buffer to be written to the file even if empty, need to do something else?
	#otherwise we'd do a loop and counter to see how many elements in file befoe EOF type flag?
	#nope, read's to buffer max, later we do a more complicated version
	syscall

	#conduct error check to see if write from buffer was successful
	slt $t0, $v0, $zero 			#set $t0 to 1 if we got a $v0 that was negative (error)
	beq $t0, $zero, writeSuccess3		#if there's no error indicating 1 in $t0, jump to ok case

	li  $v0, 4				# print the error prompt
	la  $a0, errorWrite
	syscall	

	#just exit if the file didn't read properly
	li $v0, 10
	syscall

    writeSuccess3:

	#close the file (make sure to check for errors)
	li $v0, 16
	move $a0, $t2 		#maybe already in there? move file descritor into a0 maybe again
	syscall

	#give a written successfully message
	li  $v0, 4				
	la  $a0, sucWrite
	syscall	

	jr $ra
