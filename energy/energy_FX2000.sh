#!/bin/tcsh
if ( "$#argv" != 1) then
  echo "Wrong number of arguments specified:"
  echo "  -arg 1 res"
  echo "supported resolutions/dycores are"
  echo "se-cslam: ne30pg3_ne30pg3_mg17"
  echo "se      : ne30_ne30_mg17"         #not tested
  echo "fv3     : C96_C96_mg17"           #not tested
  echo "fv      : f09_f09_mg17"           #not tested
  echo "mpas    : mpasa120_mpasa120"      #not tested
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
set stopoption="nsteps"
set steps="2"
set walltime = "00:10:00"
set cset="FX2000"

if ($res == "C96_C96_mg17") then
  set pecount="384"
else
  set pecount="450"
endif
if ($res == "mpasa120_mpasa120") then
#  set pecount = "576x1" #"36x1"
  set pecount = "36x1"
endif
set pw=`pwd`
source machine_settings.sh startup
set PBS_ACCOUNT="P93300642"
echo $PBS_ACCOUNT

set caze=regr_energy_${cset}_${res}
$homedir/$USER/src/$src/cime/scripts/create_newcase --case $scratch/$USER/$caze --compset $cset --res $res  --q $queue --walltime $walltime --pecount $pecount  --project $PBS_ACCOUNT --compiler $compiler --run-unsupported

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
  echo "se_statefreq       = 144"                     >> user_nl_cam
  echo "interpolate_output = .true.,.false.,.true."    >> user_nl_cam
  echo "interpolate_nlat   = 96 , 96, 96"             >> user_nl_cam
  echo "interpolate_nlon   = 192,192,192"             >> user_nl_cam
endif
if ($res == "mpasa120_mpasa120") then
  if ($cset == "FKESSLER") then
    echo "ncdata='/project/amp/pel/inic/x1.40962.init.umjs.dry.32levels.nc'" >> user_nl_cam
  endif
endif

if ($res == "mpasa120_mpasa120") then
    if ($cset == "QPC6") then
      echo "drydep_srf_file = '/glade/p/cesmdata/inputdata/atm/cam/chem/trop_mam/atmsrf_mpasa120_c090720.nc'"    >> user_nl_cam
    endif
endif

if ($stopoption == "nmonths") then
  echo "avgflag_pertape(1) = 'A'" >> user_nl_cam
  echo "avgflag_pertape(2) = 'A'" >> user_nl_cam
  echo "nhtfrq             = 0,0,0,0,0" >> user_nl_cam
else
  echo "avgflag_pertape(1) = 'I'" >> user_nl_cam
  echo "avgflag_pertape(2) = 'I'" >> user_nl_cam
  echo "avgflag_pertape(3) = 'I'" >> user_nl_cam
  echo "nhtfrq             = 1,1,0,0,0" >> user_nl_cam
endif
echo "mfilt = 10,10,10,10,10,10,10,10,10,10,10" >> user_nl_cam
echo "empty_htapes       = .true."   >> user_nl_cam
echo "ndens              = 2,1,2,2                                            ">> user_nl_cam
echo "fincl1 = 'TEINP','TEOUT','TEFIX','EFIX','DTCORE','PS','U','T','Q','PRECT','OMEGA500'" >> user_nl_cam
if ( $res == "ne30pg3_ne30pg3_mg17" || $res == "ne30_ne30_mg17" ) then
  echo "fincl2 =   'WV_pBF','WL_pBF','WI_pBF','SE_pBF','KE_pBF',  ">> user_nl_cam
  echo "           'WV_pBP','WL_pBP','WI_pBP','SE_pBP','KE_pBP',  ">> user_nl_cam
  echo "           'WV_pAP','WL_pAP','WI_pAP','SE_pAP','KE_pAP',  ">> user_nl_cam
  echo "           'WV_pAM','WL_pAM','WI_pAM','SE_pAM','KE_pAM',  ">> user_nl_cam
  echo "           'WV_dED','WL_dED','WI_dED','SE_dED','KE_dED',  ">> user_nl_cam
  echo "           'WV_dAF','WL_dAF','WI_dAF','SE_dAF','KE_dAF',  ">> user_nl_cam
  echo "           'WV_dBD','WL_dBD','WI_dBD','SE_dBD','KE_dBD',  ">> user_nl_cam
  echo "           'WV_dAD','WL_dAD','WI_dAD','SE_dAD','KE_dAD',  ">> user_nl_cam
  echo "           'WV_dAR','WL_dAR','WI_dAR','SE_dAR','KE_dAR',  ">> user_nl_cam
  echo "           'WV_dBF','WL_dBF','WI_dBF','SE_dBF','KE_dBF',  ">> user_nl_cam
  echo "           'WV_dBH','WL_dBH','WI_dBH','SE_dBH','KE_dBH',  ">> user_nl_cam
  echo "           'WV_dCH','WL_dCH','WI_dCH','SE_dCH','KE_dCH',  ">> user_nl_cam
  echo "           'WV_dAH','WL_dAH','WI_dAH','SE_dAH','KE_dAH',  ">> user_nl_cam
  echo "           'WV_dBS','WL_dBS','WI_dBS','SE_dBS','KE_dBS',  ">> user_nl_cam
  echo "           'WV_dAS','WL_dAS','WI_dAS','SE_dAS','KE_dAS',  ">> user_nl_cam
  echo "           'WV_p2d','WL_p2d','WI_p2d','SE_p2d','KE_p2d',  ">> user_nl_cam
  echo "           'WV_PDC','WL_PDC','WI_PDC'      ">> user_nl_cam
endif
if ( $res == "f09_f09_mg17" ) then
  echo "fincl2 =   'WV_pBF','WL_pBF','WI_pBF','SE_pBF','KE_pBF',  ">> user_nl_cam
  echo "           'WV_pBP','WL_pBP','WI_pBP','SE_pBP','KE_pBP',  ">> user_nl_cam
  echo "           'WV_pAP','WL_pAP','WI_pAP','SE_pAP','KE_pAP',  ">> user_nl_cam
  echo "           'WV_pAM','WL_pAM','WI_pAM','SE_pAM','KE_pAM'   ">> user_nl_cam

endif
if ( $res == "mpasa120_mpasa120") then
  echo "fincl2 = 'WV_pBF','SE_pBF','KE_pBF',  ">> user_nl_cam
  echo "         'WV_pBP','SE_pBP','KE_pBP',  ">> user_nl_cam
  echo "         'WV_pAP','SE_pAP','KE_pAP',  ">> user_nl_cam
  echo "         'WV_pAM','SE_pAM','KE_pAM',  ">> user_nl_cam
  echo "         'WV_dDP','SE_dDP','KE_dDP',  ">> user_nl_cam
  echo "         'WV_dPD','SE_dPD','KE_dPD',  ">> user_nl_cam
  echo "         'WV_dDM','SE_dDM','KE_dDM',  ">> user_nl_cam
  echo "         'WV_dBD','SE_dBD','KE_dBD',  ">> user_nl_cam
  echo "         'WV_dED','SE_dED','KE_dED',  ">> user_nl_cam
  echo "         'WV_dBF','SE_dBF','KE_dBF'   ">> user_nl_cam
endif
if ($res == "C96_C96_mg17") then
  echo " fincl2 =  'WV_pBF','WL_pBF','WI_pBF','SE_pBF','KE_pBF',">> user_nl_cam
  echo "           'WV_pBP','WL_pBP','WI_pBP','SE_pBP','KE_pBP',">> user_nl_cam
  echo "           'WV_pAP','WL_pAP','WI_pAP','SE_pAP','KE_pAP',">> user_nl_cam
  echo "           'WV_pAM','WL_pAM','WI_pAM','SE_pAM','KE_pAM',">> user_nl_cam
  echo "           'WV_dED','WL_dED','WI_dED','SE_dED','KE_dED',">> user_nl_cam
  echo "           'WV_dAF','WL_dAF','WI_dAF','SE_dAF','KE_dAF',">> user_nl_cam
  echo "           'WV_dAD','WL_dAD','WI_dAD','SE_dAD','KE_dAD',">> user_nl_cam
  echo "           'WV_dAR','WL_dAR','WI_dAR','SE_dAR','KE_dAR',">> user_nl_cam
  echo "           'WV_dBF','WL_dBF','WI_dBF','SE_dBF','KE_dBF' ">> user_nl_cam
endif
#
# get rid of error with SE: 
#
#    ERROR: 
#    setup_interpolation_and_define_vector_complements: No meridional match for UTGW
#    _TOTAL

#
echo "fincl3 = 'PS'">>user_nl_cam
echo "fincl4 = 'PS'">>user_nl_cam
echo "fincl5 = 'PS'">>user_nl_cam
echo "fincl6 = 'PS'">>user_nl_cam
echo "fincl7 = 'PS'">>user_nl_cam
echo "fincl8 = 'PS'">>user_nl_cam
#echo "inithist           = 'MONTHLY'"   >> user_nl_cam
source $pw/machine_settings.sh cleanup
qcmd -- ./case.build
./case.submit

