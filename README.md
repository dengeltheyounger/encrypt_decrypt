This is an assembly program that encrypts and decrypts its main routine

Originally, get_page_size and change_protections were functions that were
part of a separate library. I basically globbed them into this program. This
is the main reason that the program is so disorganized. Eventually, I want to
clean up the assembly and organize it a little better (while also maximizing what
can be encrypted and decrypted). Otherwise, this is pretty good for now.

Strictly speaking, not all of this code is assembly. The print instructions
routine is written in C. But that is more because it was there just to showcase
that the instructions were being encoded and decoded. 

My reason for doing this is mainly that I've always had a fascination with
self modifying code from the moment I first started programming. I have been
dreaming of one day getting to the point of being able to write self modifying
code for as long as I've been a programmer. 
