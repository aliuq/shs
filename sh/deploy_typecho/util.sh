#!/bin/bash

function readIni() {
    awk -F '=' '/\['$2'\]/{a=1}a==1&&$1~/'$3'/{print $2;exit}' $1
}

function writeIni() {
    sed -i "/^\[$2\]/,/^\[/ {/^\[$2\]/b;/^\[/b;s/^$3*=.*/$3=$4/g;}" $1  
}

function uninstallMySQL() {
    # 卸载mariab
    mariadbExist=$(rpm -qa | grep mariadb | sed -r 's/\\n//g')
    for cmd in $mariadbExist
    do
        echo "正在卸载$cmd"
        rpm -e --nodeps $cmd
    done

    # 卸载MySQL
    mysqlList=$(rpm -qa | grep mysql | sed -r 's/\\n//g')
    for cmd in $mysqlList
    do
        echo "正在卸载$cmd"
        rpm -e --nodeps $cmd
    done
}

function installMySQL() {
    wget -i http://dev.mysql.com/get/mysql57-community-release-el7-10.noarch.rpm    
    yum -y install mysql57-community-release-el7-10.noarch.rpm
    yum -y install mysql-community-server

    systemctl start mysqld.service
    systemctl status mysqld.service
}

function writeMyConf() {
    defaultPwd=$1
    if [[ -z ${defaultPwd} ]];
    then
        # Get Mysql Default Password
        grepStr=$(grep "password" /var/log/mysqld.log)
        sedStr=$(echo $grepStr | sed -r 's/.*?root@localhost: (.*?)/\1/g')
        defaultPwd=$(echo $sedStr | awk '{print substr($1, 0, 12)}')
        echo "默认数据库密码是：" $defaultPwd
    fi
    # 写入/root/.my.cnf
    echo -e "[client]\nuser=root\nport=3306\nhost=127.0.0.1\npassword=$defaultPwd" > /root/.my.cnf
}

function resetMySQLPassword() {
    read -p "请输入数据库密码：" password
    echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '$password';\nexit;" > /root/reset_pwd.sql
    echo $password
    mysql </root/reset_pwd.sql
    exit
    rm /root/reset_pwd.sql
}

function installPhp7() {
    rpm -Uvh https://mirror.webtatic.com/yum/el7/epel-release.rpm 
    rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
    yum install -y php70w.x86_64 php70w-cli.x86_64 php70w-common.x86_64 php70w-gd.x86_64 php70w-ldap.x86_64 php70w-mbstring.x86_64 php70w-mcrypt.x86_64 php70w-mysql.x86_64 php70w-pdo.x86_64 php70w-fpm
    yum -y install php-mysql php-gd php-imap php-ldap php-odbc php-mbstring php-devel php-soap php-cli php-pdo
    yum -y install php-mcrypt php-tidy php-xml php-xmlrpc php-pear
    yum -y install php-pecl-memcache php-eaccelerator
}

function uninstallPhp7() {
    # 卸载mariab
    php7Exist=$(rpm -qa | grep php7 | sed -r 's/\\n//g')
    for cmd in $php7Exist
    do
        echo "正在卸载$cmd"
        rpm -e --nodeps $cmd
    done
}