#!/bin/tcsh
if ( "$#argv" != 3) then
  echo "Wrong number of arguments specified:"
  echo "  -arg 1 time index to plot"
  echo "  -arg 2 date file"
  echo "  -arg 3 dycore (e.g. mpas,fv3,se,se-cslam)"
endif  
set n = 1
set time_idx = "$argv[$n]"
set n = 2
set hfile = "$argv[$n]"
set n = 3
set model = "$argv[$n]"
echo $model
set vname = "(/"\"PS\"","\"PRECL\""/)"
if ($model == "mpas") then
  set reffile = "/glade/p/cgd/amp/pel/regression-tests/FKESSLER/regr_FKESSLER_mpasa120_mpasa120//regr_FKESSLER_mpasa120_mpasa120.h0.0001-01-01-00000.nc"
else
  echo "no reffile"
  exit
endif
#set hfile = "h0"
#source set_datafile_location.sh
module load ncl
module load nco
if ( ! -f $hfile ) then
  echo $hfile" does not exist"
  exit
endif
if ( ! -f $reffile ) then
  echo $reffile" does not exist"
  exit
endif
set titles = "(/"\"New\"","\"Reference\"","\"New-Reference\""/)"
echo $titles

ln -s $hfile tmpAnew.h99.nc
ln -s $reffile tmpBref.h99.nc
echo "Computing diff between new data and ref (may take a while)"
ncdiff tmpAnew.h99.nc tmpBref.h99.nc tmpCdiff.h99.nc
ncl 'time_idx="'$time_idx'"' 'vname='$vname''  'titles='$titles'' 'hnum="h99"' 'model="'$model'"'  'outfname="'PS_PRECT.pdf'"'  /glade/u/home/pel/src/regression-tests/FKESSLER/plot_2column_panel.ncl
rm tmp*.h99.nc
#cd work/
#pdfcrop --margins 25 PS_PRECT.pdf
#ls PS_PRECT-crop.pdf
#mv PS_PRECT.pdf ../plots/PS_PRECT.pdf
#cd ..

