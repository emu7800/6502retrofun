.PHONY: all clean
.DEFAULT_GOAL: all

all: ADVNTURE.BIN ADVeNTURE.BIN ADVeNTURE8K.BIN

%.BIN: %.o
	ld65 -o $@ -C $*.cfg -m $*.map.txt -Ln $*.labels.txt $<
	../convert_sym.py $*.labels.txt $*.sym

%.o: %.s
	ca65 -o $@ -I inc -g -l $*.listing.txt $<

ADVeNTURE.o: ADVNTURE.s
	ca65 -o $@ -I inc -g -l $*.listing.txt $< -D FIXME

clean:
	-rm -f *.o *.BIN *.txt *.sym
