.SUFFIXES:
.PHONY: all clean
.SECONDEXPANSION:
.PRECIOUS:
.SECONDARY:

pic_obj := main.o

roms := pic.gbc

all: pic.gbc

clean:
	rm -f $(roms) $(pic_obj) $(roms:.gbc=.map) $(roms:.gbc=.sym)

pic.gbc:
	rgbasm -o main.o main.asm
	rgblink -n pic.sym -m pic.map -o pic.gbc main.o 
	rgbfix -Cjv -i SNDM -k 01 -l 0x33 -m 0x00 -p 0 -r 0 -t TEST170917 pic.gbc
