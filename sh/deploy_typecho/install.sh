#! /bin/bash
#=================================================================#
#   System Required:  CentOS 7  v0.0.1                            #
#   Description: Deploy Typecho Blog Shell Script                 #
#   Author: Linka <https://t.me/vneedu>                           #
#=================================================================#

clear
echo
echo "###################################################################"
echo "#                                                                 #"
echo "# Deploy Typecho Blog In Centos7 v0.0.1                           #"
echo "# Content: Apache、MySQL5.7、Php7、Typecho                         #"
echo "# Author: Linka <https://t.me/vneedu>                             #"
echo "#                                                                 #"
echo "###################################################################"
echo

# Commands
commands=(
    "一键安装"
    "安装Apache"
    "卸载Apache"
    "安装MySQL5.7"
    "卸载MySQL5.7"
    "安装Php7"
    "卸载Php7"
    "安装Typecho"
    "修改数据库密码"
    "服务检测"
    "退出"
)
# Colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

echo_commands() {
    for ((i=1;i<${#commands[@]}+1;i++))
      do
          echo -e "${green}${i}${plain}) ${commands[$i-1]}"
      done
    echo
    read -p "请选择一个命令: " command
    excute_command $command
}
check_package_is_installed(){
    which $1 &> /dev/null
    if [ $? -eq 0 ]; then
        echo -e "${green}$2 已安装${plain}"
        return 0
    else
        return 1
    fi
}
install_apache(){
    echo
    echo "======================= 🧡 安装Apache ======================="
    echo
    if [ $1 ]; then
        uninstall_package httpd
    fi
    check_package_is_installed httpd Apache
    if [[ $? != 0 || $1 ]]; then
        yum install -y httpd
        systemctl start httpd
        systemctl enable httpd
    fi
}
install_mysql() {
    echo
    echo "======================= 🧡 安装MySQL5.7 ====================="
    echo
    if [ $1 ]; then
        uninstall_package mysql5.7
    fi
    check_package_is_installed mysql mysql5.7
    if [[ $? != 0 || $1 ]]; then
        wget -i http://dev.mysql.com/get/mysql57-community-release-el7-10.noarch.rpm
        yum -y install mysql57-community-release-el7-10.noarch.rpm
        yum -y install mysql-community-server
        systemctl start mysqld.service
        systemctl status mysqld.service
    fi
}
install_php() {
    echo
    echo "======================= 🧡 安装Php7 ========================="
    echo
    if [ $1 ]; then
        uninstall_package Php7
    fi
    check_package_is_installed php Php7
    if [[ $? != 0 || $1 ]]; then
        rpm -Uvh https://mirror.webtatic.com/yum/el7/epel-release.rpm
        rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
        yum install -y php70w.x86_64 php70w-cli.x86_64 php70w-common.x86_64 php70w-gd.x86_64 php70w-ldap.x86_64 php70w-mbstring.x86_64 php70w-mcrypt.x86_64 php70w-mysql.x86_64 php70w-pdo.x86_64 php70w-fpm
        yum -y install php-mysql php-gd php-imap php-ldap php-odbc php-mbstring php-devel php-soap php-cli php-pdo
        yum -y install php-mcrypt php-tidy php-xml php-xmlrpc php-pear
        yum -y install php-pecl-memcache php-eaccelerator
    fi
}
install_typecho(){
    echo
    echo "======================= 🧡 安装typecho ======================"
    echo
    link=$(curl -s http://typecho.org/download | grep downloads | sed -r 's/.*?(http:.*?\.tar\.gz).*?/\1/g')
    filename="typecho.tar.gz"
    if [ $link ]; then
        wget $link -O $filename
        tar xzvf $filename -C /var/www/html
        mv /var/www/html/build/* /var/www/html -bf
        rm /var/www/html/build -rf
    fi
}
uninstall_package(){
    echo -e "\n${red}开始卸载: $1${plain}\n"
    list=$(rpm -qa | grep $1 | sed -r 's/\\n//g')
    for name in $list
    do
        echo -e "[${green}Info${plain}] 正在卸载$name"
        rpm -e --nodeps $name
    done
    echo
}
write_root_mysql_conf(){
    password=$1
    if [[ -z ${password} ]]; then
        grepStr=$(grep "password" /var/log/mysqld.log)
        sedStr=$(echo $grepStr | sed -r 's/.*?root@localhost: (.*?)/\1/g')
        password=$(echo $sedStr | awk '{print substr($1, 0, 12)}')
    fi
    echo -e "[client]\nuser=root\nport=3306\nhost=127.0.0.1\npassword=$password" > /root/.my.cnf
}
update_mysql_password(){
    cat /root/.my.cnf &> /dev/null
    if [ $? == 0 ]; then
        echo
        echo -n "请输入数据库密码(包含字母、数字、特殊符号): "
        read -s oldpassword
        echo
        write_root_mysql_conf $oldpassword
    else
        write_root_mysql_conf
    fi
    echo
    echo -n "请输入新的数据库密码(包含字母、数字、特殊符号): "
    read -s password
    echo
    mysql --connect-expired-password <<EOF
    ALTER USER 'root'@'localhost' IDENTIFIED BY '$password';
EOF
}
check_service_status(){
    httpd_status=$(systemctl status httpd | grep "Active:" | sed -r 's/Active: (.*?\)).*?/\1/g')
    echo -e "${green}Apache:    $httpd_status${plain}"
    mysql_status=$(systemctl status mysqld | grep "Active:" | sed -r 's/Active: (.*?\)).*?/\1/g')
    echo -e "${green}MySQL:     $mysql_status${plain}"
    # Check Php
    echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php
    code=$(curl -m 20 -I -s -o /dev/null -w %{http_code}"\n" http://localhost/phpinfo.php)
    if [[ $code == "200" ]]; then
        echo -e "${green}Php:          访问正常${plain}"

    else
        echo -e "${red}Php:            访问失败${plain}"
    fi
    rm /var/www/html/phpinfo.php -rf
    # Typecho
    code=$(curl -m 20 -I -s -o /dev/null -w %{http_code}"\n" http://localhost/install.php)
    if [ $code == "200" ];
    then
        echo -e "${green}Typecho:      部署成功${plain}"
    else
        echo -e "${red}Typecho:        部署失败${plain}"
    fi
}
excute_command(){
    case $1 in
    1)
        install_apache
        install_mysql
        install_php
        update_mysql_password
        install_typecho
    ;;
    2) install_apache
    ;;
    3) uninstall_package httpd
    ;;
    4) install_mysql
    ;;
    5)
        uninstall_package mariadb
        uninstall_package mysql
    ;;
    6) install_php
    ;;
    7) uninstall_package php7
    ;;
    8) install_typecho
    ;;
    9) update_mysql_password
    ;;
    10) check_service_status
    ;;
    11) exit
    ;;
    *) echo -e "\n[${yellow}$1${plain}] 命令不存在"
    ;;
    esac
    echo
    echo
    echo_commands 1
}

echo -e "${red}* 请勿在安装过程中按下[Enter]键${plain}\n"
echo_commands
