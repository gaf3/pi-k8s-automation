# pi-k8s-automation

Home automation using Raspberry Pi's running Kubernetes

# Projects

- [Chore Speech v1](/chore-speech-v1.md)
- [Nandy v2](/nandy-v2.md)

# Installation of cluster

Just want to document the steps used to get things up and running.  Automating the automation making these repeatable, all that's outside the scope here.  Better to have steps with cut and paste than over do it.  We just want to know what'll it take to get things work and stable. 

Using this: https://kubecloud.io/setup-a-kubernetes-1-9-0-raspberry-pi-cluster-on-raspbian-using-kubeadm-f8b3b85bc2d1

This image looks promising: https://hub.docker.com/r/resin/raspberry-pi-alpine-python/

## Flashing the Drive

- Get image: https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2018-11-15/
- Get etcher: https://etcher.io/
- Flash it
- Remove and reinsert
- On Mac in pi-k8s/automation/
  - Enable ssh `touch /Volumes/boot/ssh` (on Mac)
  - Copy over setup `cp -r bin/ /Volumes/boot/pi-k8s/`
- Eject Card from Finder (boot)
- Remove it and place it in Pi

## Enable Networking

- Boot Pi
- On Pi (connect monitor and keyboard)
  - Change pi@ password `passwd`
  - Become root `sudo -i`
  - Set keyboard `raspi-config`
    - Localisation Options (return)
    - Change Keyboard Layout (return)
    - Generic 105-key (Intl) PC (default / return)
    - Other (return)
    - English (US) (return)
    - English (US) (return)
    - (tab, return)
    - (tab, return)
    - (tab, tab, return)
  - Set Hostname `/boot/pi-k8s/hostname.sh pi-k8s-node00+`
  - Enable tmpfs `/boot/pi-k8s/tmpfs.sh` (Increase card life)
  - Enable Wifi `/boot/pi-k8s/wifi.sh` (If Wifi)
  - Get wlan0 (wifi) or eth0 (no wifi) MAC address `ifconfig`
  - Force HMDI On in /boot/config.txt
    - hdmi_force_hotplug=1
    - hdmi_group=2
    - hdmi_mode=68
- On Router
  - Reserve IP in Router for 192.168.1.100+
- Reboot Pi `shutdown -r now`
- On Mac

## Install Kubernetes

- Update firmware:
  - `sudo apt-get install rpi-update`
  - `sudo rpi-update`
- Reboot Pi
- Whether master or worker `/boot/pi-k8s/kubernetes.sh`
- Reboot Pi

## Initialize Kubernetes Master

- On master node
  - Init `sudo kubeadm init --token-ttl=0 --apiserver-advertise-address=<master ip> --pod-network-cidr=10.244.0.0/16`
  - If it fails
    - `kubeadm reset`
    - `systemctl daemon-reload`
    - `systemctl restart kubelet.service`
    - Redo Init
  - Save join command: `echo "<command>" > join.txt`
  - Set up kubectl
    - `mkdir -p $HOME/.kube`
    - `sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config`
    - `sudo chown $(id -u):$(id -g) $HOME/.kube/config`
  - Set up network
    - `curl -sSL https://rawgit.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml | sed "s/amd64/arm/g" | kubectl create -f -`
  - Check for nodes
    - `kubectl get nodes`
  - Rename cluster/user/context
    - `nano ~/.kube/config`
    - Change all names to `pi-k8s`
- On worker nodes
  - Paste the join instruction given
  - Set up kubectl
    - `mkdir -p $HOME/.kube`
    - `scp pi@<master ip>:/home/pi/.kube/config /home/pi/.kube/config`
  - Check for nodes
    - `kubectl get nodes`

# Development Setup

## Add Netatalk

- On Raspberry Pi:
  - `sudo apt-get install netatalk`
  - Checkout repo
  - Get IP `ifconfig`

## Connect and develop

- On Mac
  - `open afp://<ip>`
  - Open into VSCode
  - Open shell
  - `ssh pi@<ip>`
  