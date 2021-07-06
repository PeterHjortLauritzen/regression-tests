#!/bin/tcsh
if ( "$#argv" != 3) then
  echo "Wrong number of arguments specified:"
  echo "  -arg 1 file with energy diagnostics (averaged)"
  echo "  -arg 2 SE,FV,FV3,MPAS"
  echo "  -arg panel title"
  exit
endif
set n = 1
set file = "$argv[$n]" 

#if (`hostname` == "cheyenne1") then
  set data_dir = "/glade/$USER/pel/"
  set ncl_dir = "/glade/u/home/$USER/src/regression-tests/energy/"
#else
#  set data_dir = "/scratch/cluster/$USER/"
#  set ncl_dir = "/home/$USER/git-scripts/ncl_scripts/budgets"
#endif

set n = 2
set dycore = "$argv[$n]"
echo "Dycore="$dycore

set n = 3
set panelTitle = "$argv[$n]" 
echo "Panel title "$panelTitle

set supportedDycore="False"
set n = 2
if ($argv[$n] == "SE") then
  set supportedDycore=True
endif
if ($argv[$n] == "FV") then
  set supportedDycore=True
endif
if ($argv[$n] == "MPAS") then
  set supportedDycore=True
endif
if ($argv[$n] == "FV3") then
  set supportedDycore=True
endif

if ($supportedDycore == "False") then
  echo "The dycore you specified is not supported"
  echo "Supported options are FV, SE, MPAS and FV3"  
endif
ncl 'dir="'$PWD'"' 'fname="'$file'"' 'dycore="'$dycore'"' 'panelTitle="'$panelTitle'"' $ncl_dir/check_mass.ncl  

