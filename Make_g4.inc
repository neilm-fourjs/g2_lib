
#.SUFFIXES: .4gl .42m .per .42f .42r .str .42s .java .class

FGLCOMP = fglcomp -Dgenero$(GENVER) $(PPARG) --resolve-calls 
FGLLINK = fgl2p $(PPARG)
FGLFORM = fglform

#VPATH = $(SRC)

export FGLSOURCEPATH=$(SRC)
export FGLLDPATH=$(BIN):$(GREDIR)/lib

lib_srcs = $(notdir $(lib_src))
lib_obj = $(patsubst %.4gl, %.42m, $(lib_srcs))
lib_objs = $(addprefix $(BIN)/$(lib)/, $(lib_obj))
lib_pers = $(notdir $(lib_per))
lib_frm = $(patsubst %.per, %.42f, $(lib_pers))
lib_frms = $(addprefix $(BIN)/, $(lib_frm))

all: $(lib_objs) $(lib_frms)

$(BIN)/$(lib)/%.42m: %.4gl
	$(FGLCOMP) -c -o $(BIN) $<

$(BIN)/%.42f: %.per
	$(FGLFORM) -M $< && mv $(SRC)/*.42f $(BIN)

clean:
	find $(BIN) -name \*.42? -delete
	find . -name \*.42? -delete
	find . -name \*.err -delete

debug: 
	@echo SRC=$(SRC)
	@echo
	@echo lib_src=$(lib_src)
	@echo
	@echo lib_srcs=$(lib_srcs)
	@echo
	@echo lib_obj=$(lib_obj)
	@echo
	@echo lib_objs=$(lib_objs)
	@echo
	@echo lib_per=$(lib_per)

