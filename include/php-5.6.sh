#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# BLOG:  https://blog.linuxeye.com
#
# Notes: OneinStack for CentOS/RadHat 5+ Debian 6+ and Ubuntu 12+
#
# Project home page:
#       http://oneinstack.com
#       https://github.com/lj2007331/oneinstack

Install_PHP-5-6()
{
cd $oneinstack_dir/src
src_url=http://ftp.gnu.org/pub/gnu/libiconv/libiconv-$libiconv_version.tar.gz && Download_src
src_url=http://downloads.sourceforge.net/project/mcrypt/Libmcrypt/$libmcrypt_version/libmcrypt-$libmcrypt_version.tar.gz && Download_src
src_url=http://downloads.sourceforge.net/project/mhash/mhash/$mhash_version/mhash-$mhash_version.tar.gz && Download_src
src_url=http://downloads.sourceforge.net/project/mcrypt/MCrypt/$mcrypt_version/mcrypt-$mcrypt_version.tar.gz && Download_src
src_url=http://mirrors.linuxeye.com/oneinstack/src/fpm-race-condition.patch && Download_src
src_url=http://www.php.net/distributions/php-$php_6_version.tar.gz && Download_src

tar xzf libiconv-$libiconv_version.tar.gz
cd libiconv-$libiconv_version
./configure --prefix=/usr/local
[ "$Ubuntu_version" == '13' ] && sed -i 's@_GL_WARN_ON_USE (gets@//_GL_WARN_ON_USE (gets@' srclib/stdio.h 
[ "$Ubuntu_version" == '14' ] && sed -i 's@gets is a security@@' srclib/stdio.h 
make && make install
cd ..
rm -rf libiconv-$libiconv_version

tar xzf libmcrypt-$libmcrypt_version.tar.gz
cd libmcrypt-$libmcrypt_version
./configure
make && make install
ldconfig
cd libltdl
./configure --enable-ltdl-install
make && make install
cd ../../
rm -rf libmcrypt-$libmcrypt_version

tar xzf mhash-$mhash_version.tar.gz
cd mhash-$mhash_version
./configure
make && make install
cd ..
rm -rf mhash-$mhash_version

echo '/usr/local/lib' > /etc/ld.so.conf.d/local.conf
ldconfig
OS_CentOS='ln -s /usr/local/bin/libmcrypt-config /usr/bin/libmcrypt-config \n
if [ `getconf WORD_BIT` == 32 ] && [ `getconf LONG_BIT` == 64 ];then \n
        ln -s /lib64/libpcre.so.0.0.1 /lib64/libpcre.so.1 \n
else \n
        ln -s /lib/libpcre.so.0.0.1 /lib/libpcre.so.1 \n
fi'
OS_command

tar xzf mcrypt-$mcrypt_version.tar.gz
cd mcrypt-$mcrypt_version
ldconfig
./configure
make && make install
cd ..
rm -rf mcrypt-$mcrypt_version

id -u $run_user >/dev/null 2>&1
[ $? -ne 0 ] && useradd -M -s /sbin/nologin $run_user 

tar xzf php-$php_6_version.tar.gz
patch -d php-$php_6_version -p0 < fpm-race-condition.patch
cd php-$php_6_version
make clean
[ ! -d "$php_install_dir" ] && mkdir -p $php_install_dir
[ "$PHP_cache" == '1' ] && PHP_cache_tmp='--enable-opcache' || PHP_cache_tmp='--disable-opcache'
if [[ $Apache_version =~ ^[1-2]$ ]];then
    ./configure --prefix=$php_install_dir --with-config-file-path=$php_install_dir/etc \
--with-apxs2=$apache_install_dir/bin/apxs $PHP_cache_tmp --disable-fileinfo \
--with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd \
--with-iconv-dir=/usr/local --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib \
--with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-exif \
--enable-sysvsem --enable-inline-optimization --with-curl --enable-mbregex --enable-inline-optimization \
--enable-mbstring --with-mcrypt --with-gd --enable-gd-native-ttf --with-openssl \
--with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-ftp \
--with-gettext --enable-zip --enable-soap --disable-ipv6 --disable-debug
else
    ./configure --prefix=$php_install_dir --with-config-file-path=$php_install_dir/etc \
--with-fpm-user=$run_user --with-fpm-group=$run_user --enable-fpm $PHP_cache_tmp --disable-fileinfo \
--with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd \
--with-iconv-dir=/usr/local --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib \
--with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-exif \
--enable-sysvsem --enable-inline-optimization --with-curl --enable-mbregex --enable-inline-optimization \
--enable-mbstring --with-mcrypt --with-gd --enable-gd-native-ttf --with-openssl \
--with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-ftp \
--with-gettext --enable-zip --enable-soap --disable-ipv6 --disable-debug
fi
make ZEND_EXTRA_LIBS='-liconv'
make install

if [ -e "$php_install_dir/bin/phpize" ];then
    echo "${CSUCCESS}PHP install successfully! ${CEND}"
else
    rm -rf $php_install_dir
    echo "${CFAILURE}PHP install failed, Please Contact the author! ${CEND}"
    kill -9 $$
fi

[ -z "`grep ^'export PATH=' /etc/profile`" ] && echo "export PATH=$php_install_dir/bin:\$PATH" >> /etc/profile 
[ -n "`grep ^'export PATH=' /etc/profile`" -a -z "`grep $php_install_dir /etc/profile`" ] && sed -i "s@^export PATH=\(.*\)@export PATH=$php_install_dir/bin:\1@" /etc/profile
. /etc/profile

# wget -c http://pear.php.net/go-pear.phar
# $php_install_dir/bin/php go-pear.phar

/bin/cp php.ini-production $php_install_dir/etc/php.ini

sed -i "s@^memory_limit.*@memory_limit = ${Memory_limit}M@" $php_install_dir/etc/php.ini
sed -i 's@^output_buffering =@output_buffering = On\noutput_buffering =@' $php_install_dir/etc/php.ini
sed -i 's@^;cgi.fix_pathinfo.*@cgi.fix_pathinfo=0@' $php_install_dir/etc/php.ini
sed -i 's@^short_open_tag = Off@short_open_tag = On@' $php_install_dir/etc/php.ini
sed -i 's@^expose_php = On@expose_php = Off@' $php_install_dir/etc/php.ini
sed -i 's@^request_order.*@request_order = "CGP"@' $php_install_dir/etc/php.ini
sed -i 's@^;date.timezone.*@date.timezone = Asia/Shanghai@' $php_install_dir/etc/php.ini
sed -i 's@^post_max_size.*@post_max_size = 50M@' $php_install_dir/etc/php.ini
sed -i 's@^upload_max_filesize.*@upload_max_filesize = 50M@' $php_install_dir/etc/php.ini
sed -i 's@^;upload_tmp_dir.*@upload_tmp_dir = /tmp@' $php_install_dir/etc/php.ini
sed -i 's@^max_execution_time.*@max_execution_time = 5@' $php_install_dir/etc/php.ini
sed -i 's@^disable_functions.*@disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server,fsocket,popen@' $php_install_dir/etc/php.ini
sed -i 's@^session.cookie_httponly.*@session.cookie_httponly = 1@' $php_install_dir/etc/php.ini
sed -i 's@^mysqlnd.collect_memory_statistics.*@mysqlnd.collect_memory_statistics = On@' $php_install_dir/etc/php.ini
[ -e /usr/sbin/sendmail ] && sed -i 's@^;sendmail_path.*@sendmail_path = /usr/sbin/sendmail -t -i@' $php_install_dir/etc/php.ini
[ ! -d '/tmp/session' ] && { mkdir /tmp/session; chown -R ${run_user}.${run_user} /tmp/session; }
[ -z "`grep ^session.save_path $php_install_dir/etc/php.ini`" ] && sed -i "s@^;session.save_path.*@&\nsession.save_path = \"/tmp/session\"@" $php_install_dir/etc/php.ini 

if [ "$PHP_cache" == '1' ];then
    sed -i 's@^\[opcache\]@[opcache]\nzend_extension=opcache.so@' $php_install_dir/etc/php.ini
    sed -i 's@^;opcache.enable=.*@opcache.enable=1@' $php_install_dir/etc/php.ini
    sed -i "s@^;opcache.memory_consumption.*@opcache.memory_consumption=$Memory_limit@" $php_install_dir/etc/php.ini
    sed -i 's@^;opcache.interned_strings_buffer.*@opcache.interned_strings_buffer=8@' $php_install_dir/etc/php.ini
    sed -i 's@^;opcache.max_accelerated_files.*@opcache.max_accelerated_files=4000@' $php_install_dir/etc/php.ini
    sed -i 's@^;opcache.revalidate_freq.*@opcache.revalidate_freq=60@' $php_install_dir/etc/php.ini
    sed -i 's@^;opcache.save_comments.*@opcache.save_comments=0@' $php_install_dir/etc/php.ini
    sed -i 's@^;opcache.fast_shutdown.*@opcache.fast_shutdown=1@' $php_install_dir/etc/php.ini
    sed -i 's@^;opcache.enable_cli.*@opcache.enable_cli=1@' $php_install_dir/etc/php.ini
    sed -i 's@^;opcache.optimization_level.*@;opcache.optimization_level=0@' $php_install_dir/etc/php.ini
fi

if [[ ! $Apache_version =~ ^[1-2]$ ]];then
    # php-fpm Init Script
    /bin/cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
    chmod +x /etc/init.d/php-fpm
    OS_CentOS='chkconfig --add php-fpm \n
chkconfig php-fpm on'
    OS_Debian_Ubuntu='update-rc.d php-fpm defaults'
    OS_command

    cat > $php_install_dir/etc/php-fpm.conf <<EOF
;;;;;;;;;;;;;;;;;;;;;
; FPM Configuration ;
;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;
; Global Options ;
;;;;;;;;;;;;;;;;;;

[global]
pid = run/php-fpm.pid
error_log = log/php-fpm.log
log_level = warning 

emergency_restart_threshold = 30
emergency_restart_interval = 60s 
process_control_timeout = 5s
daemonize = yes

;;;;;;;;;;;;;;;;;;;;
; Pool Definitions ;
;;;;;;;;;;;;;;;;;;;;

[$run_user]
listen = /dev/shm/php-cgi.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = $run_user 
listen.group = $run_user
listen.mode = 0666
user = $run_user 
group = $run_user

pm = dynamic
pm.max_children = 12 
pm.start_servers = 8 
pm.min_spare_servers = 6 
pm.max_spare_servers = 12
pm.max_requests = 2048
pm.process_idle_timeout = 10s
request_terminate_timeout = 120
request_slowlog_timeout = 0

pm.status_path = /php-fpm_status
slowlog = log/slow.log
rlimit_files = 51200
rlimit_core = 0

catch_workers_output = yes
;env[HOSTNAME] = $HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp
EOF

    [ -d "/run/shm" -a ! -e "/dev/shm" ] && sed -i 's@/dev/shm@/run/shm@' $php_install_dir/etc/php-fpm.conf $oneinstack_dir/vhost.sh $oneinstack_dir/config/nginx.conf 

    if [ $Mem -le 3000 ];then
        sed -i "s@^pm.max_children.*@pm.max_children = $(($Mem/2/20))@" $php_install_dir/etc/php-fpm.conf
        sed -i "s@^pm.start_servers.*@pm.start_servers = $(($Mem/2/30))@" $php_install_dir/etc/php-fpm.conf
        sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = $(($Mem/2/40))@" $php_install_dir/etc/php-fpm.conf
        sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = $(($Mem/2/20))@" $php_install_dir/etc/php-fpm.conf
    elif [ $Mem -gt 3000 -a $Mem -le 4500 ];then
        sed -i "s@^pm.max_children.*@pm.max_children = 80@" $php_install_dir/etc/php-fpm.conf
        sed -i "s@^pm.start_servers.*@pm.start_servers = 50@" $php_install_dir/etc/php-fpm.conf
        sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 40@" $php_install_dir/etc/php-fpm.conf
        sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 80@" $php_install_dir/etc/php-fpm.conf
    elif [ $Mem -gt 4500 -a $Mem -le 6500 ];then
        sed -i "s@^pm.max_children.*@pm.max_children = 90@" $php_install_dir/etc/php-fpm.conf
        sed -i "s@^pm.start_servers.*@pm.start_servers = 60@" $php_install_dir/etc/php-fpm.conf
        sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 50@" $php_install_dir/etc/php-fpm.conf
        sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 90@" $php_install_dir/etc/php-fpm.conf
    elif [ $Mem -gt 6500 -a $Mem -le 8500 ];then
        sed -i "s@^pm.max_children.*@pm.max_children = 100@" $php_install_dir/etc/php-fpm.conf
        sed -i "s@^pm.start_servers.*@pm.start_servers = 70@" $php_install_dir/etc/php-fpm.conf
        sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 60@" $php_install_dir/etc/php-fpm.conf
        sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 100@" $php_install_dir/etc/php-fpm.conf
    elif [ $Mem -gt 8500 ];then
        sed -i "s@^pm.max_children.*@pm.max_children = 120@" $php_install_dir/etc/php-fpm.conf
        sed -i "s@^pm.start_servers.*@pm.start_servers = 80@" $php_install_dir/etc/php-fpm.conf
        sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 70@" $php_install_dir/etc/php-fpm.conf
        sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 120@" $php_install_dir/etc/php-fpm.conf
    fi

    #[ "$Web_yn" == 'n' ] && sed -i "s@^listen =.*@listen = $IPADDR:9000@" $php_install_dir/etc/php-fpm.conf 
    service php-fpm start

elif [[ $Apache_version =~ ^[1-2]$ ]];then
    service httpd restart
fi
cd ..
[ -e "$php_install_dir/bin/phpize" ] && rm -rf php-$php_6_version
cd ..
}
