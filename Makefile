.PHONY: all clean 64-t
.DEFAULT_GOAL: all

all:
	make -C 64-t

64-t:
	make -C 64-t

clean:
	make clean -C 64-t
