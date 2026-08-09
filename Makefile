.SUFFIXES:
.PHONY: all clean
.SECONDEXPANSION:
.PRECIOUS:
.SECONDARY:

cft_obj := main.o

roms := cft.gbc

all: cft.gbc

clean:
	rm $(roms) $(cft_obj) $(roms:.gbc=.map) $(roms:.gbc=.sym) # gbmh.2bpp

cft.gbc: main.asm hardware.inc
# 	rgbgfx -o gbmh.2bpp gbmh.png
	rgbasm -o main.o main.asm
	rgblink -w -n cft.sym -m cft.map -o cft.gbc main.o 
	rgbfix -Cjv -i SNDM -k 01 -l 0x33 -m 0x0F -p 0 -r 0 -t COLORFIGHT cft.gbc
