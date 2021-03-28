#! /bin/bash
#
# description：一键部署Typecho博客网站
# version: 0.0.1
# via 偏向技术
# 

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
    mysql --connect-expired-password </root/reset_pwd.sql
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

echo "🧡 一键部署Typecho博客网站"

echo 
echo "🧡 安装Apache"
echo 

type httpd >/dev/null 2>&1
if [[ $? == 0 ]];
then
    echo "Apache已安装"
    echo $(httpd -v)
else
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
fi

echo 
echo "🧡 安装MySQL数据库"
echo 

type mysql >/dev/null 2>&1
if [[ $? == 0 ]];
then
    echo "MySQL已安装"
    echo $(mysql -V)
    read -p "是否卸载，重新安装? 默认为N [Y/N]" isDeleteMySQL
    if [[ $isDeleteMySQL = 'y' || $isDeleteMySQL = 'Y' ]];
    then
        uninstallMySQL
        installMySQL
        writeMyConf
        resetMySQLPassword
    else
        # 新建表
        read -p "是否需要新建一张表？默认为Y [Y/N]" isNeedNewTable
        if [[ -z ${isNeedNewTable} || $isNeedNewTable = 'y' || $isNeedNewTable = 'Y' ]];
        then
            read -p "请输入表名(默认blog)：" tableName
            tableName=${tableName:-blog}
            echo $tableName
            echo "create database $tableName;\nexit;" > /root/new_table.sql
            read -p "请输入数据库密码：" password
            writeMyConf $password
            mysql </root/new_table.sql
            rm /root/new_table.sql
        fi
    fi
else
    installMySQL
    writeMyConf
    resetMySQLPassword
fi

echo 
echo "🧡 安装php7"
echo 

type php >/dev/null 2>&1
if [[ $? == 0 ]];
then
    echo "php7已安装"  
    echo $(php -v)
    read -p "是否卸载，重新安装? 默认为N [Y/N]" isDeleteMySQL
    if [[ $isDeleteMySQL = 'y' || $isDeleteMySQL = 'Y' ]];
    then
        uninstallPhp7
        installPhp7
    fi
else
    installPhp7
    systemctl restart httpd.service
    systemctl enable httpd.service
fi

echo 
echo "🧡 检测php服务"
echo 
echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php
code=$(curl -m 20 -I -s -o /dev/null -w %{http_code}"\n" http://localhost/phpinfo.php)
if [[ $code == "200" ]];
then
    echo "检测正常"
    rm /var/www/html/phpinfo.php -rf
else
    echo "检测失败"
fi

echo 
echo "🧡 部署Typecho"
echo 
# 获取官网稳定版本
typechoLink=$(curl -s http://typecho.org/download | grep downloads | sed -r 's/.*?(http:.*?\.tar\.gz).*?/\1/g')
filename="typecho.tar.gz"
if [[ $typechoLink ]];
then
    wget $typechoLink -O $filename
    tar xzvf $filename -C /var/www/html
    mv /var/www/html/build /var/www/html/blog -f
    code=$(curl -m 20 -I -s -o /dev/null -w %{http_code}"\n" http://localhost/blog/install.php)
    if [[ $code == "200" ]];
    then
        echo "检测正常"
        mv /var/www/html/blog/* /var/www/html -f
        rm /var/www/html/blog -rf
    else
        echo "检测失败"
    fi
fi

echo "部署成功，请前往浏览器继续操作！！"