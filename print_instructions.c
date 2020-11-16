#include <stdio.h>
#include <stddef.h>

void print_instructions(void *func_addr, size_t len) {
	unsigned char *instruction = NULL;
	size_t columns = 20;
	
	for (size_t i = 0; i < len; ++i) {
		instruction = (unsigned char *) func_addr + i;
		fprintf(stderr, "%02X ", *instruction);
		if (i % columns == 19)
			printf("\n");
	}
	
	fprintf(stderr, "\n");
}
