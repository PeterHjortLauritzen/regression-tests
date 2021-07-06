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

#if ($res == "ne30_ne30_mg17" || $res == "ne30pg3_ne30pg3_mg17") then
#  set src="CESM2.2-updates"
#else
#  set src="mpas_john_version"
#endif
#set src="cam_development"
set src="new_CESM2.2"
set cset="FHS94"
set NTHRDS="1"
if ($res == "C96_C96_mg17") then
  set pecount="384"
else
  set pecount="450"
endif
if ($res == "mpasa120_mpasa120") then
  set pecount = "576x1" 
endif
set stopoption="nmonths"
set steps="6"
set walltime="01:45:00"
#set stopoption="ndays"
#set steps="1800"
#set walltime="05:00:00"
source machine_settings.sh startup
set PBS_ACCOUNT="P93300642"

set pw=`pwd`

set caze=topo_${cset}_${src}_${res}
#$homedir/$USER/src/$src/cime/scripts/create_newcase --case $scratch/$USER/$caze --compset $cset --res $res  --q $queue --walltime $walltime --pecount $pecount  --project $PBS_ACCOUNT --compiler $compiler --machine $machine --run#-unsupported
/glade/scratch/pel/new_CESM2.2/cime/scripts/create_newcase --case $scratch/$USER/$caze --compset $cset --res $res  --q $queue --walltime $walltime --pecount $pecount  --project $PBS_ACCOUNT --compiler $compiler --machine $machine --run#-unsupported
cd $scratch/$USER/$caze
./xmlchange STOP_OPTION=$stopoption,STOP_N=$steps
./xmlchange DOUT_S=FALSE
./xmlchange CAM_CONFIG_OPTS="-analytic_ic -phys held_suarez -nlev 32 -cppdefs -Dtracer_diags" #very important: otherwise you get PS=1000hPa initial condition
./xmlchange NTHRDS=$NTHRDS
./xmlquery CASEROOT
#./xmlchange REST_N=12
./xmlchange REST_OPTION=nmonths
./case.setup
echo "use_topo_file          =  .true." >> user_nl_cam
echo "analytic_ic_type ='us_standard_atmosphere'"  >> user_nl_cam
if ($res == "ne30_ne30_mg17" || $res == "ne30pg3_ne30pg3_mg17") then
  echo "se_statefreq       = 256"        >> user_nl_cam
  echo "interpolate_output = .false.,.false.,.false.,.false.,.true." >> user_nl_cam      
  echo "interpolate_nlat = 192,192,192"               >> user_nl_cam
  echo "interpolate_nlon = 288,288,288"               >> user_nl_cam
endif
if ($res == "mpasa120_mpasa120") then
  echo "ncdata='$inputdata/atm/cam/inic/mpas/mpasa120_L32_topo_grid_c201022.nc'" >> user_nl_cam
  echo "bnd_topo = '$inputdata/atm/cam/topo/mpas/mpas_120_nc3000_Co060_Fi001_MulG_PF_Nsw042_c200921.nc'" >> user_nl_cam
endif
echo "fincl1 = 'PMID','PS','T','U','V','OMEGA500','OMEGA850'  " >> user_nl_cam
echo "empty_htapes       = .true."   >> user_nl_cam
#
# reduce number of output fields
#
#echo "fincl2 = 'MR_pBF', 'MR_pBP', 'MR_pAP', 'MR_pAM', 	" >> user_nl_cam
#echo "         'MO_pBF', 'MO_pBP', 'MO_pAP', 'MO_pAM'  	" >> user_nl_cam
#echo "fincl3 = 'MR_pBF', 'MR_pBP', 'MR_pAP', 'MR_pAM', 	" >> user_nl_cam
#echo "         'MO_pBF', 'MO_pBP', 'MO_pAP', 'MO_pAM'  	" >> user_nl_cam
#echo "fincl4 = 'PS','TT_SLOT','TT_EM8'"                   >> user_nl_cam #for mass conservation diagnostics
#echo "fincl5 = 'PS','TT_SLOT','TT_EM8'"                   >> user_nl_cam #for mass conservation diagnostics
echo "avgflag_pertape(1) = 'A'"                           >> user_nl_cam
echo "avgflag_pertape(2) = 'A'"                           >> user_nl_cam
echo "avgflag_pertape(3) = 'A'"                           >> user_nl_cam
echo "avgflag_pertape(4) = 'I'"                           >> user_nl_cam
echo "avgflag_pertape(5) = 'I'"                           >> user_nl_cam
echo "nhtfrq             = 0,   0, 0, -720,-720  	" >> user_nl_cam
echo "mfilt		 = 1,   1, 1,  30  		" >> user_nl_cam
echo "ndens		 = 2,   1, 1,   1  		" >> user_nl_cam
echo "inithist           =  'YEARLY'"                     >> user_nl_cam
#echo "test_tracer_names  = 'TT_SLOT','TT_EM8'"            >>user_nl_cam
cd SourceMods/src.cam/
ln -s $pw/src.cam/cam_diagnostics.F90 .
cd ../../
source $pw/machine_settings.sh cleanup
if(`hostname` == 'hobart.cgd.ucar.edu') then
  ./case.build
endif
if(`hostname` == 'izumi.unified.ucar.edu') then
 ./case.build
endif
if(`hostname` == 'cheyenne1.ib0.cheyenne.ucar.edu' || `hostname` == 'cheyenne1' || `hostname` == 'cheyenne2' || `hostname` == 'cheyenne3' || `hostname` == 'cheyenne4' || `hostname` == 'cheyenne5' || `hostname` == 'cheyenne6') then
  qcmd -- ./case.build
endif
./case.submit


