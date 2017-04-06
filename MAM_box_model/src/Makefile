# Makefile for pegasus.2.6.1
#
#----------------------------------------------------------------------
#
# includes
#
include ./cambox_config.make.in
include ./cambox_config.cpp.in

all: test1 test2 test3 test4 test5 

#
# Suffix rules...
#
.SUFFIXES : .F .f .F90 .f90 .o

.F.o:
	$(CPP) $(CPPFLAGS) $*.F $*.f ;  $(FC) -c $(FCFLAGS) $*.f

.F.f:
	$(CPP) $(CPPFLAGS) $*.F $*.f

.f.o:
	$(CPP) $(CPPFLAGS) $*.F $*.f ;  $(FC) -c $(FCFLAGS) $*.f

.F90.o:
	$(FC) $(CPPFLAGS) -c $(FCFLAGS) $*.F90

.F90.f90:
	$(RM) $*.mod ; $(CPP) $(CPPFLAGS) $*.F90 

.f90.o:
	$(RM) $*.mod ; $(CPP) $(CPPFLAGS) $*.F90 ;  $(FC) -c $(FCFLAGS) $*.f90

#
# Object lists...
#
# OBJ1, OBJ2, and OBJ4 files 
#    These files are special versions of the equivalent CAM5 modules.
#    They provide the functionality needed by the cambox offline code
#    that is used for development and testing of the modal aerosol module (MAM),
#    but (in most cases) not all the functionality of the equivalent CAM5 module.
#    Also, they may have been taken from a version of CAM5 that was older
#    than ACME-V0 (i.e., pre 2014).
# OBJ3 and OBJ5 files
#    These files should be identical to the equivalent CAM5 module (or almost so).
# OBJ9 files 
#    These are specific to the offline test code and have no CAM equivalents.

CONFIGINFO = \
	./cambox_config.make.in  \
	./cambox_config.cpp.in

OBJ1 = \
	shr_kind_mod.o  \
	shr_const_mod.o

OBJ2 = \
	cam_logfile.o  \
	spmd_utils.o  \
	abortutils.o  \
	cam_abortutils.o  \
	ppgrid.o  \
	pmgrid.o  \
	constituents.o  \
	radconstants.o  \
	physconst.o  \
	cam_history.o  \
	units.o  \
	ref_pres.o  \
	physics_buffer.o  \
	physics_types.o  \
	phys_control.o  \
	mo_constants.o  \
	chem_mods.o  \
	mo_tracname.o  \
	mo_chem_utls.o  \
	gffgch.o  \
	wv_saturation.o  \
	error_function.o  \
	shr_spfn_mod.o  \
	infnan.o \
	seasalt_model.o  \
	time_manager.o  \
	aerodep_flx.o  \
	modal_aero_convproc.o  \
	modal_aero_deposition.o 

OBJ3 = \
	modal_aero_data.o

OBJ4 = \
	rad_constituents.o

OBJ5 = \
	modal_aero_rename.o  \
	modal_aero_calcsize.o  \
	modal_aero_gasaerexch.o  \
	modal_aero_newnuc.o  \
	modal_aero_coag.o  \
	modal_aero_amicphys.o \
	modal_aero_wateruptake.o \
	modal_aero_initialize_data.o \
	driver_utilities.o \
	driver_init.o 

OBJ9 = \
	gaschem_simple.o  \
	cloudchem_simple.o  \
	driverT1.o  \
	main.o

OBJ10 = \
	gaschem_simple.o  \
	cloudchem_simple.o  \
	driverT2.o  \
	main.o

OBJ11 = \
	gaschem_simple.o  \
	cloudchem_simple.o  \
	driverT3.o  \
	main.o

OBJ12 = \
	gaschem_simple.o  \
	cloudchem_simple.o  \
	driverT4.o  \
	main.o

OBJ13 = \
	gaschem_simple.o  \
	cloudchem_simple.o  \
	driverT5.o  \
	main.o


#-----------------------------------------------------------------------------
# WARNING: Don't touch anything below this line unless you exactly know it !!!
#-----------------------------------------------------------------------------


#
# Dependancies...
#
test1 : $(OBJ1) $(OBJ2) $(OBJ3) $(OBJ4) $(OBJ5) $(OBJ9) $(CONFIGINFO)
	$(FC) -o $@ $(FCFLAGS) $(LDFLAGS) $(OBJ1) $(OBJ2) $(OBJ3) $(OBJ4) $(OBJ5) $(OBJ9) $(LDLIBS)

test2 : $(OBJ1) $(OBJ2) $(OBJ3) $(OBJ4) $(OBJ5) $(OBJ10) $(CONFIGINFO)
	$(FC) -o $@ $(FCFLAGS) $(LDFLAGS) $(OBJ1) $(OBJ2) $(OBJ3) $(OBJ4) $(OBJ5) $(OBJ10) $(LDLIBS)

test3 : $(OBJ1) $(OBJ2) $(OBJ3) $(OBJ4) $(OBJ5) $(OBJ11) $(CONFIGINFO)
	$(FC) -o $@ $(FCFLAGS) $(LDFLAGS) $(OBJ1) $(OBJ2) $(OBJ3) $(OBJ4) $(OBJ5) $(OBJ11) $(LDLIBS)

test4 : $(OBJ1) $(OBJ2) $(OBJ3) $(OBJ4) $(OBJ5) $(OBJ12) $(CONFIGINFO)
	$(FC) -o $@ $(FCFLAGS) $(LDFLAGS) $(OBJ1) $(OBJ2) $(OBJ3) $(OBJ4) $(OBJ5) $(OBJ12) $(LDLIBS)

test5 : $(OBJ1) $(OBJ2) $(OBJ3) $(OBJ4) $(OBJ5) $(OBJ13) $(CONFIGINFO)
	$(FC) -o $@ $(FCFLAGS) $(LDFLAGS) $(OBJ1) $(OBJ2) $(OBJ3) $(OBJ4) $(OBJ5) $(OBJ13) $(LDLIBS)


$(OBJ1):  $(CONFIGINFO)

$(OBJ2):  $(OBJ1)

$(OBJ3):  $(OBJ2)

$(OBJ4):  $(OBJ3)

$(OBJ5):  $(OBJ4)

$(OBJ9):  $(OBJ5)

$(OBJ10):  $(OBJ5)

$(OBJ11):  $(OBJ5)

$(OBJ12):  $(OBJ5)

$(OBJ13):  $(OBJ5)


rad_constituents.o: modal_aero_data.o

clean:
	/bin/rm  test1 test2 test3 test4 test5  *.o  *.f  *.f90  *.mod


cleanmod:
	/bin/rm  *.x  *.mod  module*.o  module*.f90  module*.f

