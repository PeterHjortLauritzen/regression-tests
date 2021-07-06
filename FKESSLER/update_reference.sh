#!/bin/tcsh
#
# reference run in git repo: https://github.com/PeterHjortLauritzen/regression-tests
#
set ref_dir_git = "~/src/regression-tests/energy"
#
# netCDF files for reference solution (too large for git)
#
set ref_dir = "/glade/p/cgd/amp/pel/regression-tests/energy/"

if ( "$#argv" != 2) then
  echo "Wrong number of arguments specified:"
  echo "  -arg 1 res COMPSET"
  echo "supported resolutions/dycores are"
  echo "se-cslam: ne30pg3_ne30pg3_mg17"
  echo "se      : ne30_ne30_mg17"
  echo "fv3     : C96_C96_mg17"
  echo "fv      : f09_f09_mg17"
  echo "mpas    : mpasa120_mpasa120"
  echo " "
  echo "COMPSET: QPC6 or FX2000"
endif
set n = 1
unset res
set res = "$argv[$n]" 
set n = 2
unset cset
set cset = "$argv[$n]" 
gunzip *.log.*.gz
set log   = ("atm" "cesm" "ocn" "cpl" "lnd" "ice" "rof")
foreach h ($log)
  mv $h.log* $h.log
end
cp *log *_in ../user_nl_cam $ref_dir_git/$caze/
cp *.cam.h0.*.nc $ref_dir/$caze/
cp *.cam.h1.*.nc $ref_dir/$caze/

