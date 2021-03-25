
.SUFFIXES: .4gl .42m .per .42f .42r .str .42s .java .class

.4gl.42m:
	$(FGLCOMP) -c -o $(BIN) $^

.per.42f:
	$(FGLFORM) -M $^ && mv $(lib_dir)/src/*.42f $(BIN)

FGLCOMP = fglcomp -Dgenero$(GENVER) $(PPARG) --resolve-calls 
FGLLINK = fgl2p $(PPARG)
FGLFORM = fglform

export FGLSOURCEPATH=$(lib_dir):$(prg1_dir)
export FGLLDPATH=$(BIN):$(BIN)/$(lib_dir):$(GREDIR)/lib

lib_srcs = $(addprefix $(lib_dir)/, $(lib_src))
lib_obj = $(patsubst %.4gl, %.42m, $(lib_src))
lib_objs = $(addprefix $(BIN)/$(lib_dir)/, $(lib_obj))
lib_pers = $(addprefix $(lib_dir)/, $(lib_per))
lib_frm = $(patsubst %.per, %.42f, $(lib_per))
lib_frms = $(addprefix $(BIN)/, $(lib_frm))

all: $(lib_obj) $(lib_frm)

$(lib_objs)/%.42m : %.4gl
#	$(FGLCOMP) -c -o $(BIN) $<

$(lib_frms)/%.42f : %.per
#	$(FGLFORM) -M $^ && mv $(prg1_dir)/*.42f $(BIN)

clean:
	find $(BIN) -name \*.42? -delete
	find . -name \*.42? -delete
	find . -name \*.err -delete

debug: 
	@echo lib_dir=$(lib_dir)
	@echo lib_src=$(lib_src)
	@echo lib_per=$(lib_per)

