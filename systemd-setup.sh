#!/usr/bin/env bash

systemd_state=$(systemctl is-system-running 2> /dev/null)
if [ "$systemd_state" == "degraded" ] || [ "$systemd_state" == "running" ]
then
    >&2 echo "Systemd already running."
    exit
fi

sudo sh -c """
chmod 1777 /tmp/.X11-unix
mount --bind -o remount,ro /mnt/wslg/.X11-unix/ /tmp/.X11-unix/
[ -d /run/user/1000 ] || mkdir -p /run/user/1000
mount --bind /mnt/wslg/runtime-dir/ /run/user/1000
echo ':WSLInterop:M::MZ::/init:PF' > /etc/binfmt.d/WSLInterop.conf
"""

systemd_state=$(systemctl is-system-running 2> /dev/null)
if [ "$systemd_state" == "offline" ]
then
    sudo -Eb unshare --kill-child -fp --propagation shared --mount-proc -- systemd multiuser.target
fi

systemd_state=$(systemctl is-system-running 2> /dev/null)
while [ "$systemd_state" != "degraded" ] && [ "$systemd_state" != "running" ]
do
    >&2 echo Systemd: $systemd_state
    sleep 1
    systemd_state=$(systemctl is-system-running 2> /dev/null)
done

systemd_state=$(systemctl is-system-running 2> /dev/null)
>&2 echo Systemd: $systemd_state

#sudo -E machinectl shell --setenv=WSL_INTEROP=$WSL_INTEROP --set-env=WSL_DISTRO_NAME=$WSL_DISTRO_NAME --setenv=WSLENV=$WSLENV --setenv=DISPLAY=$DISPLAY --setenv=WAYLAND_DISPLAY=$WAYLAND_DISPLAY $USER@
#or
#sudo -E machinectl login .host
