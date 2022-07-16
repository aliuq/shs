#! /bin/bash
#=================================================================#
#   System Required:  CentOS 7  v0.0.1                            #
#   Description: Update kernel                                    #
#   Description: CentOS系统内核                                    #
#=================================================================#

clear

# Colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

kernel=$(uname -sr)

echo ""
echo -e "Current kernel version: ${yellow}$kernel${plain}"
echo ""
read -n2 -p "Are you sure to update kernel [Y/N]?" answer

case $answer in
(Y | y)
  echo ""
  echo -e "${green}- Update kernel${plain}"
  echo ""
  rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
  rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
  yum --disablerepo="*" --enablerepo="elrepo-kernel" list available

  echo ""
  echo -e "${green}- Install kernel${plain}"
  echo ""
  yum --enablerepo=elrepo-kernel install kernel-lt -y

  echo ""
  echo -e "${green}- Set default${plain}"
  echo ""
  sed -i 's/GRUB_DEFAULT=saved/GRUB_DEFAULT=0/g' /etc/default/grub

  echo ""
  echo -e "${green}- Regenerate the grub configuration file${plain}"
  echo ""
  grub2-mkconfig -o /boot/grub2/grub.cfg

  echo ""
  echo -e "${green}- Remove old tools${plain}"
  yum remove -y kernel-tools-libs.x86_64 kernel-tools.x86_64

  echo ""
  echo -e "${green}- Install new tools${plain}"
  yum --disablerepo=\* --enablerepo=elrepo-kernel install -y kernel-lt-tools.x86_64

  echo ""
  echo -e "${green}- Reboot wait 5s${plain}"
  echo ""
  sleep 5s

  reboot
;;
esac
