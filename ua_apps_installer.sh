#!/bin/bash
# Automated installer for MySQL, phpMyAdmin and Wordpress on Uniform Access Clusters
# Nikky Southerland | nikky@uw.edu
# University of Washington Information Technology
# 2010
# For testing purposes and advanced users only. This script is not meant for general client use at this time.
# Initial Version 0.5: Core functionality in place. Runduncancy, sane checks, and automatic backups not yet implimented.
# 11/08/2010.
# 11/09/2010: Added support for users with both student and staff web publishing. Now checks and prompts user to choose where they want files installed.
#git commit

# Grabbing a few helpful things
netid=`exec whoami`


#First, let's make sure they're in the web dev environment.

hostname | grep dante
dantecheck=$?
if [ $dantecheck -eq 0 ] ;
then
  clear
  echo -e "It appears that you are currently using dante.\nYou must use your web development environment, vergil.\nAttempting to connect now.\nAfter connected, run this script again.\n\n"
  ssh $netid@vergil.u.washington.edu
  end
fi

hostname | grep homer
homercheck=$?
if [ $homercheck -eq 0 ] ;
then
  clear
  echo -e "It appears that you are currently using homer.\nYou must use your web development environment, ovid.\nAttempting to connect now\nAfter connected, run this script again.\n\n"
  ssh $netid@ovid.u.washington.edu
  end
fi

# Now that we've established that they're not in dante/homer, let's grab their actual host.
# Since the host occasionally changes, we'll have to be a little more general.
# hostname *would* work, but it returns ovid??.u.washington.edu, which changes.
# So it's better to just get ovid.u.washington.

hostname | grep vergil
vergilcheck=$?
if [ $vergilcheck -eq 0 ] ;
then
  hostname=vergil
fi

hostname | grep ovid
vergilcheck=$?
if [ $vergilcheck -eq 0 ] ;
then
  hostname=ovid
fi





# Beginning the long list of functions #
# Since this is in bash, you need to declare them before you use 'em


# Remove a Few Leftovers...

function cleanup {

rm ~/.sqlpwd
rm ~/.port
rm ~/$directory latest.tar.gz

}

# Pseudo-random number generator for wordpress install needs.

function mkpw { 
head /dev/urandom | uuencode -m - | sed -n 2p | cut -c1-${1:-64}; 
}


# Take user input, check against conditions, and continue to telnet_test#
# While technically the port range is between 1024 and 65655, we might as well use whole numbers. Plus most ports under 2000 are used anyway. #


function telnet_check {
echo -e "\nType in a random number between 2000 and 65000 and then press [Enter].\nSome text will appear, and it will then tell you if your port is free or not."
unset port
read -e port
if
  [ $port -lt 2000 ];
then
  echo "You have picked a number that is smaller than 2000. Try again."
  telnet_check
else
  if
    [ $port -gt 65000 ]; then
    echo "You have picked a number that is greater than 65000. Try again."
    telnet_check
  fi
fi
telnet_test
      }


      #Check to see if user has a MySQL Database running#

      function mysql_check {
      clear
      ps uxww | grep mysql
      wcstatus=$?
      mysql=$wcstatus
    }


    #Parse results. Sometimes we want thisk, sometimes we don't.#

    function mysql_check_results {
    if [ $wcstatus = 0 ] ;
    then
      echo -e "\n\nYou have a MySQL database running.\n\n"
    else
      echo -e "\n\nYou do not have a MySQL database running.\n\n"
    fi

  }


  #Use netstat to check to see if a port is open.#

  function telnet_test {
  netstat -tulnap | grep $port | grep -i listen 
  wcstatus=$?
  if
    [ $wcstatus = 1 ] ; then
    clear
    echo -e "\n\nSuccess! Port $port is open and can be used.\n Be sure to write this number down for future reference."
    echo -e "\nPress [enter] when ready to move on."
    read
  else
    echo -e "\n\n\nUh-oh! It looks like port $port is already in use by someone else!\nGo ahead and pick another to try.\n"
    telnet_check
  fi

}

#Install MySQL.#

function mysql_install {
echo -e "\n\nNow that we have a suitable port, the MySQL installer will now run.\nThis may take a few minutes.\nBe sure to type in \"yes\" when it asks you to.\n"
read -p "Press any key to continue..."
clear
mysql-local-setup
echo -e "[mysqld]
port=$port
socket=$HOME/mysql.sock
basedir=$HOME/mysql
datadir=$HOME/mysql/data
skip-innodb

[client]
port=$port
socket=$HOME/mysql.sock" > ~/.my.cnf
echo -e "\n\nYour .my.cnf file has been written in your ~ (home) directory.\n"

}

#Start MySQL#

function mysql_start {
echo -e "\n\nFilling initial MySQL tables. This may take a while.\n\n"
cd ~/mysql
scripts/mysql_install_db 
echo -e "\n\nStarting your MySQL server now...\n\n "
echo -e "\n\nMySQL doesn't automatically return to a command line. Press enter to resume the program.\n\n"
$HOME/mysql/bin/mysqld_safe &
}

# Run some commands to actually get the MySQL Database a Password#

function mysql_password {
clear
unset $sqlpwd
echo -e "Your MySQL Server has Successfully Started!\nNow you need to create a MySQL \"root\" password.\n\nThink of a good password, type it in, and then press enter.\n\n"
echo -e "[Type Password and Press Enter]:" 

read sqlpwd

echo -e "\nYou have entered in '$sqlpwd' as your password. Do you wish to change it? [y/n]\n"
read change
if [ $change = "y" ] ; then
  mysql_password
fi
echo -e "\n\nYou entered in the following as your password. Be sure to write it down!:\n\n"
echo $sqlpwd
echo -e "\n\nEntering password into the MySQL Server now...\n\n"
~/mysql/bin/mysqladmin -u root password "$sqlpwd"
echo -e "\n\nYour MySQL Database on port $port now has a root account and the password $sqlpwd.\n\nThe script will now enter in some additional permissions to your database. This should only take a minute...\n\n"
~/mysql/bin/mysql -u root --password=$sqlpwd mysql -e "delete from user where Host like \"%\"; grant all privileges on *.* to root@\"%.washington.edu\" identified by '$sqlpwd' with grant option; grant all privileges on *.* to root@localhost identified by '$sqlpwd' with grant option; flush privileges;"
clear
echo -e "Congratulations! Your MySQL database on `hostname` is now running!\n\nPort: $port\n\nUser: root\n\nPassword: $sqlpwd\n\n\n\nAccess your command line client by running ~/mysql/bin/mysql -u root -p"
echo $sqlpwd > ~/.sqlpwd
echo $port > ~/.port
}

#Drop in a wordpress database#

function wordpress_database
{
  clear
  echo -e "I will now install a new database called 'wordpress' for you.\n"
  read -p "Press any [ Enter ] to continue..."
  ~/mysql/bin/mysql -u root --password=`exec cat .sqlpwd` mysql -e "create database wordpress;"
  echo -e "\n\nDatabase configured successfully. Now installing wordpress files..."
  cd $directory
  wget http://wordpress.org/latest.tar.gz
  tar -xzvf latest.tar.gz
  clear
  cd ~
  echo -e "Wordpress files uncompressed!"
  #Visit the following website and fill in the values below:\n\n"
  #echo -e "http://ACCOUNT_TYPE.washington.edu/$netid/wordpress/wp-admin/setup-config.php\n\nNOTE: Replace \"ACCOUNT_TYPE\" with \"student, staff, faculty, courses, or depts,\" depending on your affiliation.\n"
  #echo -e "For example, if your NetID was \"test\" and you were a student, you would visit:\nhttp://students.washington.edu/test/wordpress/wp-admin/setup-config.php"
  #echo -e "**Enter the following into the Wordpress Install Page**"
  #echo -e "\n\nDatabase name: wordpress\n\nUser name: root\n\nPassword: `exec cat .sqlpwd`\n\nDatabase Host: $hostname.u.washington.edu :`exec cat .port`\n\nTable Prefix: (leave Empty)" 
  echo -e "\n\n\nI will now also try to create this file myself...\n"
  echo "<?php
  /** The name of the database for WordPress */
  define('DB_NAME', 'wordpress');

  /** MySQL database username */
  define('DB_USER', 'root');

  /** MySQL database password */
  define('DB_PASSWORD', '`exec cat ~/.sqlpwd`');

  /** MySQL hostname */
  define('DB_HOST', '$hostname.u.washington.edu:`exec cat ~/.port`');

  /** Database Charset to use in creating database tables. */
  define('DB_CHARSET', 'utf8');

  /** The Database Collate type. Do not change this if in doubt. */
  define('DB_COLLATE', '');

  define('AUTH_KEY',         '`exec head /dev/urandom | uuencode -m - | sed -n 2p | cut -c1-${1:-64};`');
  define('SECURE_AUTH_KEY',  '`exec head /dev/urandom | uuencode -m - | sed -n 2p | cut -c1-${1:-64};`');
  define('LOGGED_IN_KEY',    '`exec head /dev/urandom | uuencode -m - | sed -n 2p | cut -c1-${1:-64};`');
  define('NONCE_KEY',        '`exec head /dev/urandom | uuencode -m - | sed -n 2p | cut -c1-${1:-64};`');
  define('AUTH_SALT',        '`exec head /dev/urandom | uuencode -m - | sed -n 2p | cut -c1-${1:-64};`');
  define('SECURE_AUTH_SALT', '`exec head /dev/urandom | uuencode -m - | sed -n 2p | cut -c1-${1:-64};`');
  define('LOGGED_IN_SALT',   '`exec head /dev/urandom | uuencode -m - | sed -n 2p | cut -c1-${1:-64};`');
  define('NONCE_SALT',       '`exec head /dev/urandom | uuencode -m - | sed -n 2p | cut -c1-${1:-64};`');

  \$table_prefix  = 'wp_';
  define ('WPLANG', '');
  define('WP_DEBUG', false);

  /** Absolute path to the WordPress $directory. */
  if ( !defined('ABSPATH') )
    define('ABSPATH', dirname(__FILE__) . '/');

    /** Sets up WordPress vars and included files. */
    require_once(ABSPATH . 'wp-settings.php');

    " >> ~/$directory/wordpress/wp-config.php

  echo -e "Looks like the file was created succesfully, yay! Visit the following site to finish:\n"
 if [ $directory == "student_html" ] ; then
  echo -e "http://students.washington.edu/$netid/wordpress"
else
  echo -e "http://staff.washington.edu/$netid/wordpress"
fi

  }
  function phpmyadmin {
  mysql_check

  if [ $mysql -eq 1 ] ;
  then
    clear
    echo -e "It does not appear that you have a MySQL Database running.\nPlease set up a database before continuing."
    exit
  fi

  clear
  echo -e "I will now download phpmyadmin, untar the file, and create a link to it.\n"
  read -p "Press any key to start..."
  cd ~/$directory
  wget http://washington.edu/itconnect/web/publishing/phpMyAdmin-3.3.7-english.tar.gz
  tar zxvf phpMyAdmin-3.3.7-english.tar.gz
  ln -s phpMyAdmin-3.3.7-english phpmyadmin
  clear
  echo -e "\n\nFiles installed. I will now protect phpmyadmin using\nNetID-based authentication.\nBy default, phpmyadmin will only\nbe accessable by you, $netid, the site owner.\nYou can edit ~/$directory/phpmyadmin/.htaccess to add more users"
  echo -e "\n"
  read -p "Press any key to continue..."
  cd phpmyadmin
  echo "AuthType UWNetID
require user $netid" > .htaccess

  echo "
  <?php
  /*
  * Generated configuration file
  * Generated by: phpMyAdmin 3.3.7 setup script by Piotr Przybylski <piotrprz@gmail.com>
  * Date: Wed, 06 Oct 2010 14:11:06 -0700
  */

  /* Servers configuration */
  \$i = 0;

  /* Server: ovid.u.washington.edu [1] */
  \$i++;
  \$cfg['Servers'][\$i]['verbose'] = '';
  \$cfg['Servers'][\$i]['host'] = '$hostname.u.washington.edu';
  \$cfg['Servers'][\$i]['port'] = `exec cat ~/.port`;
  \$cfg['Servers'][\$i]['socket'] = '';
  \$cfg['Servers'][\$i]['connect_type'] = 'tcp';
  \$cfg['Servers'][\$i]['extension'] = 'mysqli';
  \$cfg['Servers'][\$i]['auth_type'] = 'config';
  \$cfg['Servers'][\$i]['user'] = 'root';
  \$cfg['Servers'][\$i]['password'] = '`exec cat ~/.sqlpwd`';

  /* End of servers configuration */

  \$cfg['DefaultLang'] = 'en-utf-8';
  \$cfg['ServerDefault'] = 1;
  \$cfg['UploadDir'] = '';
  \$cfg['SaveDir'] = '';
  ?>

  " > config.inc.php

  clear
  echo -e "phpmyadmin is now installed!"

 if [ $directory == "student_html" ] ; then
     echo -e "http://students.washington.edu/$netid/phpmyadmin"
   else
       echo -e "http://staff.washington.edu/$netid/phpmyadmin"
     fi



  exit
}




#Set default choice
choice=9
clear
echo -e "Welcome to the semi-automated software installer!\nReport any errors to nikky@cac.washington.edu\n\nPlease choose what you would like to do:"
echo "1. Install MySQL"
echo "2. Install Wordpress"
echo "3. Install phpmyadmin"
echo "4. View if you already have a MySQL Database Running"
echo "5. Remove leftover files"
echo -e "\n\n\nChoose [1,2,3,4 or 5] and press enter."

read choice

if [ $choice -eq 1 ] ; then
  echo "You have decided to install MySQL"
  telnet_check
  mysql_install
  mysql_start
  mysql_password
else
  if [ $choice -eq 2 ] ; then
    echo "You have decided to install Wordpress"
    directory=public_html
    ls ~/student_html &> /dev/null
    wcstatus=$?
    if [ $wcstatus -eq 0 ] ; then
      echo -e "\nIt appears that you have the following services activated:\n\n[1] Student Web Publishing\n\n[2] Staff Web Publishing"
      echo -e "\nWhere would you like wordpress installed?\nType in \"1\" or \"2\" and then press enter.\n\n"
      read dd
      if [ $dd -eq 2 ] ; then
        echo -e "\nFiles will be published to your staff website."
        directory=public_html
      else
        echo -e "\nFiles will be published to your student website."
        directory=student_html
      fi
    fi
    wordpress_database
    #  wordpress_install
  else
    if [ $choice -eq 3 ] ; then
      echo "You have decided to install phpmyadmin"
      directory=public_html
      ls ~/student_html &> /dev/null
      wcstatus=$?
      if [ $wcstatus -ne 1 ] ; then
        echo -e "\nIt appears that you have the following services activated:\n\n[1] Student Web Publishing\n\n[2] Staff Web Publishing"
        echo -e "\nWhere would you like phpMyAdmin installed?\nType in \"1\" or \"2\" and then press enter.\n\n"
        read dd
        if [ $dd -eq 2 ] ; then
          echo -e "\nFiles will be published to your staff website."
          directory=public_html
        else
          echo -e "\nFiles will be published to your student website."
          directory=student_html
        fi
      fi

      phpmyadmin
    else
      if [ $choice -eq 4 ] ; then
        echo "You would like to see if you have a MySQL Database"
        mysql_check
        mysql_check_results
        if [ $choice -eq 5 ] ; then
          cleanup
          echo "Leftover files removed."
          exit
        fi
      fi
    fi
  fi
fi
# Go Huskies!
