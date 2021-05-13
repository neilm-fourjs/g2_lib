
export GENVER=400

BIN = ../njm_app_bin
SRC = g2_lib
lib = g2_lib
lib_src = $(wildcard g2_lib/*.4gl)
lib_per = $(wildcard g2_lib/*.per)

include ./Make_g4.inc

#$(BIN)/g2_lib.42x: src/*.4gl src/*.per
#	gsmake g2_lib.4pw

#test:
#	gsmake test.4pw

