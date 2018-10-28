#!/usr/bin/env bash

sudo cat <<EOT >> /etc/network/interfaces

allow-hotplug wlan0
iface wlan0 inet manual
	wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
EOT


sudo cat <<EOT > /etc/wpa_supplicant/wpa_supplicant.conf
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

network={
        ssid="FBI Surveillance Van"
        key_mgmt=NONE
}
EOT