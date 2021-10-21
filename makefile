
export GENVER=400
export BIN=../njm_app_bin

export PROJBASE=$(PWD)

TARGETS=$(BIN)/g2_lib.42x

all: $(TARGETS)

$(BIN)/g2_lib.42x: g2_lib/*.4gl
	gsmake g2_lib$(GENVER).4pw

test:
	gsmake test.4pw

clean:
	gsmake -c g2_lib.4pw
	gsmake -c test.4pw
