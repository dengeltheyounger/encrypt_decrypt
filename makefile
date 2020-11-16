main: encrypt_decrypt.S print_instructions.c
	gcc -o main encrypt_decrypt.S print_instructions.c -ggdb

clean:
	if [[ -f main ]]; then rm main; fi
