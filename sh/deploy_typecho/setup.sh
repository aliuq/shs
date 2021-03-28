#! /bin/bash

set -E

. ./util.sh

echo "🧡 一键部署博客网站"

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
    # wget $typechoLink -O $filename
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