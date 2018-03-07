#!/bin/bash 

cd /home/jenkins/acme/scratch/HOMME_P24.f19_g16_rx1.A.melvin_gnu.C.jenkins_next_20170215_203221/bld/tests/swtc1

rm -f movies/*

# Pure MPI test 1
mpiexec -n 24  /home/jenkins/acme/scratch/HOMME_P24.f19_g16_rx1.A.melvin_gnu.C.jenkins_next_20170215_203221/bld/test_execs/swtcA/swtcA < /home/jenkins/slave/workspace/ACME_Basic_next/ACME_Climate/components/homme/test/reg_test/namelists/swtc1.nl > swtc1_1.out 2> swtc1_1.err

# Running cprnc to difference swtc11.nc against baseline 
mpiexec -n 1  /home/jenkins/acme/scratch/HOMME_P24.f19_g16_rx1.A.melvin_gnu.C.jenkins_next_20170215_203221/bld/utils/cime/tools/cprnc/cprnc /home/jenkins/acme/scratch/HOMME_P24.f19_g16_rx1.A.melvin_gnu.C.jenkins_next_20170215_203221/bld/tests/swtc1/movies/swtc11.nc /sems-data-store/ACME/baselines/gnu/next/HOMME_P24.f19_g16_rx1.A.melvin_gnu/tests/baseline/swtc1/movies/swtc11.nc > swtc1.swtc11.nc.out 2> swtc1.swtc11.nc.err

