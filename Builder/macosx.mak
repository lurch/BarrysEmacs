#
#	macosx.mak
#
#	build emacs for Mac OS X
#
PYTHON=python${PYTHON_VERSION}

BEMACS_LIB_DIR=$(BUILDER_TOP_DIR)/Kits/MacOSX/pkg/be_main.app/Contents/Resources/emacs_library
BEMACS_DOC_DIR=$(BUILDER_TOP_DIR)/Kits/MacOSX/pkg/be_main.app/Contents/Resources/documentation

usage:
	@ echo "Usage: make -f macosx.mak build"
	@ echo "Usage: make -f macosx.mak clean"
	exit 1

build: brand editor mlisp describe language quick_info docs MacOSX_pkg

brand:
	$(PYTHON) brand_version.py version_info.txt ..

editor:
	@ echo Info: Building BEmacs images...
	cd ../Editor; PATH=.:$$PATH; ./build.sh all
	@ echo Info: Building BEmacs application...
	cd ../Editor/PythonBEmacs; PATH=.:$$PATH; ./build.sh --package
	@ echo Info: Copy db utils...
	cp ../Editor/darwin/obj-utils/dbadd $(BEMACS_LIB_DIR)
	cp ../Editor/darwin/obj-utils/dbcreate $(BEMACS_LIB_DIR)
	cp ../Editor/darwin/obj-utils/dbdel $(BEMACS_LIB_DIR)
	cp ../Editor/darwin/obj-utils/dbprint $(BEMACS_LIB_DIR)
	cp ../Editor/darwin/obj-utils/dblist $(BEMACS_LIB_DIR)
	cp ../Editor/darwin/obj-utils/mll2db $(BEMACS_LIB_DIR)

mlisp:
	@ echo Info: Copying Mlisp files...
	cp -f ../MLisp/emacsinit.ml	$(BEMACS_LIB_DIR); chmod ugo=r $(BEMACS_LIB_DIR)/emacsinit.ml
	cp -f ../MLisp/emacs_profile.ml	$(BEMACS_LIB_DIR); chmod ugo=r $(BEMACS_LIB_DIR)/emacs_profile.ml
	cd ../MLisp; $(PYTHON) create_library.py common,unix,motif $(BEMACS_LIB_DIR)/emacslib $(BEMACS_LIB_DIR)


describe:
	@ echo Info: Making describe...
	@ $(BEMACS_LIB_DIR)/dbcreate $(BEMACS_LIB_DIR)/emacsdesc -c
	@ $(BEMACS_LIB_DIR)/mll2db ../Describe/em_desc.mll $(BEMACS_LIB_DIR)/emacsdesc

language:
	@ echo Info: Making language...
	@ $(BEMACS_LIB_DIR)/dbcreate $(BEMACS_LIB_DIR)/emacslang -c
	@ $(BEMACS_LIB_DIR)/mll2db ../Language/language.mll $(BEMACS_LIB_DIR)/emacslang

quick_info:
	@ echo Info: Making quick info...
	@ $(BEMACS_LIB_DIR)/dbcreate $(BEMACS_LIB_DIR)/emacs_qinfo_c -c
	@ $(BEMACS_LIB_DIR)/mll2db ../Describe/qi_cc.mll $(BEMACS_LIB_DIR)/emacs_qinfo_c

docs:
	@ echo Info: Copying documentation...
	cp -f ../Kits/readme.txt $(BEMACS_DOC_DIR);chmod ugo=r $(BEMACS_DOC_DIR)/readme.txt
	cp -f ../HTML/*.html	$(BEMACS_DOC_DIR); chmod ugo=r $(BEMACS_DOC_DIR)/*.html
	cp -f ../HTML/*.gif	$(BEMACS_DOC_DIR); chmod ugo=r $(BEMACS_DOC_DIR)/*.gif
	cp -f ../HTML/*.css	$(BEMACS_DOC_DIR); chmod ugo=r $(BEMACS_DOC_DIR)/*.css
	cp -f ../HTML/*.js	$(BEMACS_DOC_DIR); chmod ugo=r $(BEMACS_DOC_DIR)/*.js

MacOSX_pkg:
	@ echo Info: MacOSX package creation...
	#cd $(BUILD_KIT_DIR); chmod +x ./make-macosx-kit.sh; ./make-macosx-kit.sh

clean:
	cd ../Editor; PATH=.:$$PATH; export BUILD_KIT_DIR=$(BEMACS_LIB_DIR); ./build.sh clean
	rm -rf $(BEMACS_DOC_DIR)
	rm -rf $(BEMACS_LIB_DIR)