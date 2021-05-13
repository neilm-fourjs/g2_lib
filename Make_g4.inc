
#.SUFFIXES: .4gl .42m .per .42f .42r .str .42s .java .class

FGLCOMP = fglcomp -Dgenero$(GENVER) $(PPARG) --resolve-calls 
FGLLINK = fgl2p $(PPARG)
FGLFORM = fglform

export FGLSOURCEPATH=$(lib)
export FGLLDPATH=$(BIN):$(GREDIR)/lib

lib_srcs = $(notdir $(lib_src))
lib_obj = $(patsubst %.4gl, %.42m, $(lib_srcs))
lib_objs = $(addprefix $(BIN)/$(lib)/, $(lib_obj))
lib_pers = $(notdir $(lib_per))
lib_frm = $(patsubst %.per, %.42f, $(lib_pers))
lib_frms = $(addprefix $(BIN)/$(lib)/, $(lib_frm))

all: lib $(lib_objs) $(lib_frms)

lib: $(lib_src)
	fglcomp --resolve-calls --verbose -c -o $(BIN) --make $(lib_src)

$(BIN)/$(lib)/%.42f: $(lib)/%.per
	$(FGLFORM) -M $< && mv $(lib)/*.42f $(BIN)/$(lib)

clean:
	find $(BIN) -name \*.42? -delete
	find . -name \*.42? -delete
	find . -name \*.err -delete

debug: 
	@echo lib=$(lib)
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

