.PHONY: all clean
.DEFAULT_GOAL: all

all: ADVNTURE.BIN ADVeNTURE.BIN

ADVNTURE.BIN: ADVNTURE.o
	ld65 -o ADVNTURE.BIN  -C ADVNTURE.cfg  -m ADVNTURE.map.txt  ADVNTURE.o

ADVeNTURE.BIN: ADVeNTURE.o
	ld65 -o ADVeNTURE.BIN -C ADVNTURE.cfg -m ADVeNTURE.map.txt ADVeNTURE.o

%.o: %.s
	ca65 -o $@ -t c64 -l $*.listing.txt $<

clean:
	-rm -f *.o *.prg *.listing.txt *.map.txt
