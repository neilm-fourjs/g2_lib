
export GENVER=401
export BIN=../njm_app_bin$(GENVER)

export PROJBASE=$(PWD)

TARGETS=$(BIN)/g2_lib.42x

all: $(TARGETS)

$(BIN)/g2_lib.42x: g2_lib/*.4gl
	gsmake g2_lib$(GENVER).4pw

test:
	gsmake test.4pw

clean:
	find . -name \*.42? -delete
	find . -name \*.zip -delete
	find . -name \*.4pdb -delete
	gsmake -c g2_lib$(GENVER).4pw
