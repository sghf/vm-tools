#!/bin/bash

# credits to bento project

echo "--- Begin cleanup.sh ---"

#echo "Locking user: packer"
#sudo passwd -l packer

echo "cloud-init"
cloud-init clean

echo "remove obsolete networking packages"
apt-get -y purge ppp pppconfig pppoeconf;

echo "remove packages we don't need"
apt-get -y purge popularity-contest command-not-found friendly-recovery laptop-detect motd-news-config usbutils grub-legacy-ec2

# 22.04+ don't have this
echo "remove the fonts-ubuntu-font-family-console"
apt-get -y purge fonts-ubuntu-font-family-console || true;

# 21.04+ don't have this
echo "remove the installation-report"
apt-get -y purge popularity-contest installation-report || true;

echo "remove the console font"
apt-get -y purge fonts-ubuntu-console || true;

echo "removing command-not-found-data"
# 19.10+ don't have this package so fail gracefully
apt-get -y purge command-not-found-data || true;

# Exclude the files we don't need w/o uninstalling linux-firmware
echo "Setup dpkg excludes for linux-firmware"
cat <<_EOF_ | cat >> /etc/dpkg/dpkg.cfg.d/excludes
#BENTO-BEGIN
path-exclude=/lib/firmware/*
path-exclude=/usr/share/doc/linux-firmware/*
#BENTO-END
_EOF_

echo "delete the massive firmware files"
rm -rf /lib/firmware/*
rm -rf /usr/share/doc/linux-firmware/*

echo "autoremoving packages and cleaning apt data"
apt-get -y autoremove;
apt-get -y clean;

echo "remove /usr/share/doc/"
rm -rf /usr/share/doc/*

rm -rf /opt/archives

echo "remove /var/cache"
find /var/cache -type f -exec rm -rf {} \;

echo "truncate any logs that have built up during the install"
find /var/log -type f -exec truncate --size=0 {} \;

echo "blank netplan machine-id (DUID) so machines get unique ID generated on boot"
truncate -s 0 /etc/machine-id
if test -f /var/lib/dbus/machine-id
then
  truncate -s 0 /var/lib/dbus/machine-id  # if not symlinked to "/etc/machine-id"
fi

echo "remove the contents of /tmp and /var/tmp"
rm -rf /tmp/* /var/tmp/*

echo "force a new random seed to be generated"
rm -f /var/lib/systemd/random-seed

echo "clear the history so our install isn't there"
rm -f /root/.wget-hsts
export HISTSIZE=0

dd if=/dev/zero of=/EMPTY bs=1M || /bin/true
rm -f /EMPTY

sync; sync

echo "--- End cleanup.sh ---"

exit 0
