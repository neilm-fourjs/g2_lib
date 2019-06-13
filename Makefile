
export GENVER=320
export BIN=bin

export PROJBASE=$(PWD)

TARGETS=$(BIN)/g2_lib.42x

all: $(TARGETS)

$(BIN)/g2_lib.42x:
	gsmake g2_lib.4pw


test:
	gsmake test.4pw

clean:
	find . -name \*.42? -delete
	find . -name \*.zip -delete
	find . -name \*.gar -delete

