#!/bin/bash +e

#check if container is running in privileged mode
ip link add dummy0 type dummy >/dev/null 2>&1
if [[ -z `grep "dummy0" /proc/net/dev` ]]; then
  echo "Container not running in privileged mode. Sure you configured privileged mode? Container stopped."
  exit 143
else
  # clean the dummy0 link
  ip link delete dummy0 >/dev/null 2>&1
fi

#check if container is running in host mode
if [[ -z `grep "docker0" /proc/net/dev` ]]; then
  echo "Container not running in host mode. Sure you configured host network mode? Container stopped."
  exit 143
fi


# catch signals as PID 1 in a container
# SIGNAL-handler
term_handler() {

  echo "terminating ssh ..."
  /etc/init.d/ssh stop

  echo "terminating dbus ..."
  /etc/init.d/dbus stop

  exit 143; # 128 + 15 -- SIGTERM
}

# on callback, stop all started processes in term_handler
trap 'kill ${!}; term_handler' SIGINT SIGKILL SIGTERM SIGQUIT SIGTSTP SIGSTOP SIGHUP

# run applications in the background
echo "starting ssh ..."
/etc/init.d/ssh start

# start Node-RED as background task
/usr/bin/node-red &


# wait forever not to exit the container
while true
do
  tail -f /dev/null & wait ${!}
done

exit 0
