
#!/bin/tcsh
if ( "$#argv" != 1) then
  echo "Wrong number of arguments specified:"
  echo "  -arg 1 res"
  echo "supported resolutions/dycores are"
  echo "se-cslam: ne30pg3_ne30pg3_mg17"
  echo "se      : ne30_ne30_mg17"
  echo "fv3     : C96_C96_mg17"
  echo "fv      : f09_f09_mg17"
  echo "mpas    : mpasa120_mpasa120"
endif
set n = 1
unset res
set res = "$argv[$n]" 
#
# source code (assumed to be in /glade/u/home/$USER/src)
#
#if ($res == "ne30_ne30_mg17" || $res == "ne30pg3_ne30pg3_mg17" || $res == "f09_f09_mg17") then
#  set src="CESM2.2-updates"
#else
set src="mpas_fixes"
#set src="cam_development"
#endif
#
# number of test tracers
#
set NTHRDS="1"
set pw=`pwd`
set stopoption="ndays"
set steps="1"
set walltime = "00:10:00"
#set cset="QPC6"
set cset="F2000climo"
#set cset="FX2000"

if ($res == "C96_C96_mg17") then
  set pecount="384"
else
  set pecount="900"
endif
if ($res == "mpasa120_mpasa120") then
#  set pecount = "576x1" #"36x1"
#  set pecount = "36x1"
  set pecount = "1800x1"
endif
set pw=`pwd`
source machine_settings.sh startup
set PBS_ACCOUNT="P93300642"
echo $PBS_ACCOUNT

set caze=20210428_${cset}_${res} #b4brtest_john_cam_development_${cset}_${res}
#$homedir/$USER/src/$src/cime/scripts/create_newcase --case $scratch/$USER/$caze --compset $cset --res $res  --q $queue --walltime $walltime --pecount $pecount  --project $PBS_ACCOUNT --compiler $compiler --run-unsupported
#/glade/scratch/pel/mpas_phl/cime/scripts/create_newcase --case $scratch/$USER/$caze --compset $cset --res $res  --q $queue --walltime $walltime --pecount $pecount  --project $PBS_ACCOUNT --compiler $compiler --run-unsupported
#$/glade/scratch/pel/john-CESM2.2-updates/cime/scripts/create_newcase --case $scratch/$USER/$caze --compset $cset --res $res  --q $queue --walltime $walltime --pecount $pecount  --project $PBS_ACCOUNT --compiler $compiler --run-unsupported
#/glade/work/hannay/cesm_tags/CAM_jet_20210423/cime/scripts/create_newcase --case $scratch/$USER/$caze --compset $cset --res $res  --q $queue --walltime $walltime --pecount $pecount  --project $PBS_ACCOUNT --compiler $compiler --run-unsupported
/glade/work/hannay/cesm_tags/CAM_pel_20210428/cime/scripts/create_newcase --case $scratch/$USER/$caze --compset $cset --res $res  --q $queue --walltime $walltime --pecount $pecount  --project $PBS_ACCOUNT --compiler $compiler --run-unsupported
cd $scratch/$USER/$caze
./xmlchange STOP_OPTION=$stopoption,STOP_N=$steps
./xmlchange DOUT_S=FALSE
./xmlchange NTHRDS=$NTHRDS
./xmlchange TIMER_LEVEL=10
if ($res == "C96_C96_mg17") then
  ./xmlchange --append CAM_CONFIG_OPTS="-cppdefs -DCALC_ENERGY"
endif
if ($res == "mpasa120_mpasa120") then
  if ($cset == "QPC6") then
    ./xmlchange OCN_DOMAIN_FILE=domain.ocn.mpasa120_gx1v7.201215.nc
  #  ./xmlchange CAM_CONFIG_OPTS='-phys cam6 -aquaplanet -nlev 32'
  endif
endif

./case.setup

if ( $res == "ne30pg3_ne30pg3_mg17" || $res == "ne30_ne30_mg17" ) then
  echo "se_statefreq       = 144"                      >> user_nl_cam
  echo "interpolate_output = .true.,.false.,.true."    >> user_nl_cam
  echo "interpolate_nlat   = 180 , 180, 180"           >> user_nl_cam
  echo "interpolate_nlon   = 360 ,360 , 360"           >> user_nl_cam
endif
if ($res == "mpasa120_mpasa120") then
  if ($cset == "FKESSLER") then
    echo "ncdata='/project/amp/pel/inic/x1.40962.init.umjs.dry.32levels.nc'" >> user_nl_cam
  endif
endif

if ($res == "mpasa120_mpasa120") then
    if ($cset == "F2000climo") then
      echo "ncdata = '/glade/work/mcurry/meshes/cam-mpas/mpasa120.CFSR.L32.nc'" >> user_nl_cam
      echo "fsurdat = '/glade/p/cesmdata/inputdata/lnd/clm2/surfdata_map/surfdata_mpasa480_hist_78pfts_CMIP6_simyr2000_c201001.nc'" >> user_nl_clm
    endif
    if ($cset == "QPC6") then
      echo "drydep_srf_file = '/glade/p/cesmdata/inputdata/atm/cam/chem/trop_mam/atmsrf_mpasa120_c090720.nc'"    >> user_nl_cam
    endif
endif

if ($stopoption == "nmonths") then
  echo "avgflag_pertape(1) = 'I'" >> user_nl_cam
  echo "avgflag_pertape(2) = 'I'" >> user_nl_cam
  echo "nhtfrq             = -6,-6,0,0,0" >> user_nl_cam
else
  echo "avgflag_pertape(1) = 'I'" >> user_nl_cam
  echo "avgflag_pertape(2) = 'I'" >> user_nl_cam
  echo "avgflag_pertape(3) = 'I'" >> user_nl_cam
  echo "nhtfrq             = 1,1,0,0,0" >> user_nl_cam
endif
#echo "empty_htapes       = .true."   >> user_nl_cam
#echo "ndens              = 2,1,2,2                                            ">> user_nl_cam
echo "fincl1 = 'PRECT','OMEGA500','ABS_dPSdt'" >> user_nl_cam

#echo "inithist           = 'MONTHLY'"   >> user_nl_cam
source $pw/machine_settings.sh cleanup
qcmd -- ./case.build
./case.submit

