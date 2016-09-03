stress=0
baudrate=3000000
vpcmd=/system/bin/vpcmd
download=`cat /sys/esxxx/uart_download`
firmware1=/etc/firmware/audience-es325-fw-init.bin
firmware2=/etc/firmware/audience-es325-fw.bin

for i in "$@"
do
  case $i in
    -f|--force)
    download=1
    ;;
    -l|--log)
    logwrapper=/system/bin/logwrapper
    ;;
    -s|--stress)
    stress=1
    ;;
  esac
done

if [ $stress -eq 1 ]
then
  while [ TRUE ]
  do
    $logwrapper $vpcmd -lh $firmware1 $firmware2 $baudrate
  done
elif [ $download -eq 1 ]
then
  $logwrapper $vpcmd -lh $firmware1 $firmware2 $baudrate
fi
