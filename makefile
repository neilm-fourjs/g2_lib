
export GENVER=400
export BIN=../njm_app_bin

lib_dir = .
lib_src = $(wildcard src/*.4gl)
lib_per = $(wildcard src/*.per)

include ./Make_g4.inc

#all: $(BIN)/g2_lib.42x

#$(BIN)/g2_lib.42x: src/*.4gl src/*.per
#	gsmake g2_lib.4pw

#test:
#	gsmake test.4pw

