
export GENVER=400

BIN = ../njm_app_bin
SRC = .
lib = g2_lib
lib_src = $(wildcard *.4gl)
lib_per = $(wildcard *.per)

include ./Make_g4.inc

#all: $(BIN)/g2_lib.42x

#$(BIN)/g2_lib.42x: src/*.4gl src/*.per
#	gsmake g2_lib.4pw

#test:
#	gsmake test.4pw

