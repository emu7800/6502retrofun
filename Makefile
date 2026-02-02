.PHONY: all clean 64-t
.DEFAULT_GOAL: all

all:
	make -C 64-t
	make -C adventure

64-t:
	make -C 64-t

adventure:
	make -C adventure

clean:
	make clean -C 64-t
	make clean -C adventure
