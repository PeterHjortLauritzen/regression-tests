#!/bin/tcsh
#
# reference run in git repo: https://github.com/PeterHjortLauritzen/regression-tests
#
set ref_dir_git = "~/src/regression-tests/FKESSLER"
#
# netCDF files for reference solution (too large for git)
#
set ref_dir = "/glade/p/cgd/amp/pel/regression-tests/FKESSLER/"

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
endif
set n = 1
unset res
set res = "$argv[$n]" 

set cset = "FKESSLER"

set caze=regr_${cset}_${res}
set hloop   = ("h0" "h1")
#
# cprnc nc files
#
foreach h ($hloop)
  set nc  = "cam."$h".0001-01-01-00000.nc"
  set ref_file = $ref_dir/$caze/$caze.$nc
  set file     = $caze.$nc
  set difffile = diff.$h.txt

  if (-e $difffile ) then
    rm $difffile
  endif

  /glade/p/cesm/cseg/tools/cprnc/cprnc -v -m $file $ref_file > $difffile
  grep -q 'the two files seem to be IDENTICAL' $difffile
  if ( $status == 0 ) then
    echo "PASS "$h
  else
    echo "FAIL! Check: "$difffile
  endif
end
#
# diff log files
#
gunzip atm.log.*
diff atm.log* $ref_dir_git/$caze/atm.log > diff.atm.log
echo "atm log file diff: diff.atm.log"
#
# diff setup
#
set setup_files_loop   = ("atm_in" "docn_in"  "drv_flds_in"  "drv_in")
foreach f ($setup_files_loop)
  set difffile = diff.$f.txt
  if (-e $difffile ) then
    rm $difffile
  endif
  diff $f $ref_dir_git/$caze/$f > $difffile
  if ($status == 0) then
     echo 'PASS '$f
  else
     echo 'FAIL '$f' (see diff.'$difffile')'
  endif
end
