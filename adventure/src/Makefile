.PHONY: all clean
.DEFAULT_GOAL: all
includes = *.inc gfx/gr/*.inc gfx/pf/*.inc


all: ADVNTURE.BIN #ADVeNTURE.BIN ADVeNTURE8k.BIN

ADVNTURE.BIN: ADVNTURE.o $(includes)
	ld65 -o ADVNTURE.BIN  -C ADVNTURE4k.cfg  -m ADVNTURE.map.txt  ADVNTURE.o

#ADVeNTURE.BIN: ADVeNTURE.o $(includes)
#	ld65 -o ADVeNTURE.BIN -C ADVNTURE4k.cfg -m ADVeNTURE.map.txt ADVeNTURE.o
#
#ADVeNTURE8k.BIN: ADVeNTURE8k.o $(includes)
#	ld65 -o ADVeNTURE8k.BIN -C ADVNTURE8k.cfg -m ADVeNTURE8k.map.txt ADVeNTURE8k.o

%.o: %.s
	ca65 -o $@ -t c64 -l $*.listing.txt $<

clean:
	-rm -f *.o *.prg *.listing.txt *.map.txt
