VERSION ?=
CC = gcc
SRC = src/
BUILD = build/
RESULTS ?= results$(VERSION)

CFLAGS = -g -O3 -march=native -fno-omit-frame-pointer

.DEFAULT_GOAL = md

$(BUILD):
	mkdir -p $(BUILD)

$(RESULTS):
	mkdir -p $(RESULTS)

md: $(SRC)/MD$(VERSION).cpp | $(BUILD)
	$(CC) $(CFLAGS) $(SRC)MD$(VERSION).cpp -lm -o $(BUILD)md$(VERSION)

.PHONY: clean run results-dir

results-dir: | $(RESULTS)

clean:
	rm -rf $(BUILD) $(RESULTS)

export OMP_NUM_THREADS ?= 48

run: md | $(RESULTS)
	cd $(RESULTS) && ../$(BUILD)md$(VERSION) < ../inputdata.txt
