.PHONY: all clean
.DEFAULT_GOAL: all

all: ADVNTURE.BIN

ADVNTURE.BIN: ADVNTURE.o
	ld65 -o ADVNTURE.BIN -C ADVNTURE.cfg -m ADVNTURE.map.txt ADVNTURE.o

%.o: %.s
	ca65 -o $@ -t c64 -l $*.listing.txt $<

clean:
	-rm -f *.o *.prg *.listing.txt *.map.txt
