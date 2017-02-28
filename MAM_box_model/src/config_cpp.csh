# config_cpp.csh

echo " "
echo 'Doing "ls -lt cambox_config.cpp.in*"'
ls -lt cambox_config.cpp.in*

echo " "
echo "Enter  3 to use cambox_config.cpp.in.mam3.pcols12"
echo "Enter  4 to use cambox_config.cpp.in.mam4.pcols12"
echo "Enter  7 to use cambox_config.cpp.in.mam7.pcols12"
echo "Enter 77 to use cambox_config.cpp.in.mam7.pcols12.mos_spec"

set itmpa = $<
if      ( $itmpa == 3 ) then
   /bin/cp -p cambox_config.cpp.in.mam3.pcols12 cambox_config.cpp.in
else if ( $itmpa == 4 ) then
   /bin/cp -p cambox_config.cpp.in.mam4.pcols12 cambox_config.cpp.in
else if ( $itmpa == 7 ) then
   /bin/cp -p cambox_config.cpp.in.mam7.pcols12 cambox_config.cpp.in
else if ( $itmpa == 77 ) then
   /bin/cp -p cambox_config.cpp.in.mam77.pcols12.mos_spec cambox_config.cpp.in
else
   echo "*** bad value -- try again"
   exit
endif

echo " "
echo 'Doing "ls -lt cambox_config.cpp.in*" again'
ls -lt cambox_config.cpp.in*

echo " "

