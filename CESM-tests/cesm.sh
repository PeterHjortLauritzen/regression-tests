set CESMDIR=/glade/scratch/pel/cam_mpas_dev_pel/
#set TESTNAME=ERC_D_Ln9.ne16_ne16_mg17.FADIAB.cheyenne_intel.cam-terminator
#set TESTNAME=SMS_Ld1.ne30pg3_ne30pg3_mg17.FC2010climo.cheyenne_intel.cam-outfrq1d
#set TESTNAME=ERP_D_Ln9.f19_f19_mg17.QPC6.cheyenne_intel.cam-outfrq9s
set TESTNAME=ERS_Ln9.f19_f19_mg17.FSPCAMS.cheyenne_intel.cam-outfrq9s
set TEST_ID=pel-bfb-revert-exp-namelistfix
set WORKDIR=/glade/scratch/$USER
set COMPARE_TAG=cam6_3_020

cd $CESMDIR/cime/scripts
qcmd -- "./create_test --xml-category aux_cam --xml-machine cheyenne --retry 2 --xml-compiler intel --queue regular --test-root $WORKDIR/$TEST_ID --output-root $WORKDIR/$TEST_ID --project P93300642 --test-id $TEST_ID --compare /glade/p/cesm/amwg/cesm_baselines/$COMPARE_TAG $TESTNAME"

#
# If you run the create_test command with --xml-category=aux_cam and do not add a specific $TESTNAME it will run all the aux_cam regression tests (takes a few hours).  There is an easier way to execute the full regression suite using the test_driver.sh script.
#
#The XXXX below is the tag name that you will compare to in order to make sure all new tests are bfb with that baseline tag.  We run the regression tests on Izumi for pgi and nag and Cheyenne using intel.
#
#On Izumi: Run <root>/test/system/test_driver.sh with CAM_FC=pgi and CAM_FC=nag and BL_TESTDIR=/fs/cgd/csm/models/atm/cam/pretag_bl/XXXX (where XXXX is the name of the previous baseline)
#env BL_TESTDIR=/fs/cgd/csm/models/atm/cam/pretag_bl/XXXX_nag CAM_FC=NAG ./test_driver.sh -f
#env BL_TESTDIR=/fs/cgd/csm/models/atm/cam/pretag_bl/XXXX_pgi CAM_FC=PGI ./test_driver.sh -f
#On Cheyenne: Run <root>/test/system/test_driver.sh (on cheyenne the command defaults to intel) and BL_TESTDIR=/glade/p/cesm/amwg/cesm_baselines/XXXX (where XXXX is the name of the previous baseline)
#env BL_TESTDIR=/glade/p/cesm/amwg/cesm_baselines/XXXX ./test_driver.sh -f
#

#
#The test directories under $WORKDIR/$TEST_ID are just CASE directories.  You can go into them and add modified code to SourceMods/src.cam rebuilt and rerun using
#./*.build
#./*.submit
#
#All the tests that are run for cam are defined in cime_config/testdefs/testlist_cam.xml.  The tests marked with a category of aux_cam are the regression tests that must all pass before a PR can be given a tag.  You can see all the tests using the cime/scripts/query_testlists command.  For instance, to see all the aux_cam tests that are run on Cheyenne you would run:
#
#./query_testlists --xml-category aux_cam   --xml-machine cheyenne
#
# Just FYI.  Your tests could have been BFB because some compilers initialize all variables to 0.  That not a standard and different compilers will just leave variables  with whatever crap is in that memory location at the beginning of a run.  Using those compilers you're FV and FV3 tests may have failed if those variables were used without being initialized properly.
#
