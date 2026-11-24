CC = gcc
SRC = src/
CFLAGS = -O3 -ffast-math -fopenmp -mcpu=a64fx

.DEFAULT_GOAL = md

md:     $(SRC)/MD.cpp
	$(CC) $(CFLAGS) $(SRC)MD.cpp -lm -o md    

clean:
	rm -f ./md    

export OMP_NUM_THREADS ?= 48
run:
	./md     < inputdata.txt >/dev/null
