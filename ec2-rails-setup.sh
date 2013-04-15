#!/bin/bash
# Note that this script requires GNU sed, as it makes use of the -i flag

# EDIT: add folder path to your Rails app (including app name)
# Used later to help set up Passenger.
rails_app=PATH_TO_YOUR_APP

echo "Prep AWS EC2 Ubuntu instance for Rails deployment"

echo "Add .vimrc for better editing later"
cat > ~/.vimrc << EOF
set nu
syntax on
filetype indent on
set autoindent
set wrap
colo slate
set shiftwidth=2
set tabstop=2
set softtabstop=2
set expandtab
set visualbell
set noerrorbells
set nobackup
set noswapfile
EOF


echo "Run apt-get to fetch required packages"
sudo apt-get -y update && sudo apt-get -y upgrade

# EDIT: apply appropriate timezone
sudo mv /etc/localtime /etc/localtime.bkp
sudo ln -s /usr/share/zoneinfo/CST6CDT /etc/localtime

sudo apt-get -y install curl git-core build-essential openssl libreadline6 libreadline6-dev zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev libgdbm-dev ncurses-dev automake libtool bison subversion pkg-config libffi-dev apache2 libcurl4-openssl-dev libapr1-dev libaprutil1-dev apache2-prefork-dev mysql-client nodejs


echo "Disable extra Apache modules, tighten configs"
sudo a2dismod autoindex cgid env negotiation setenvif status

sudo sed -i 's/ServerSignature [a-zA-Z]*/ServerSignature Off/' /etc/apache2/conf.d/security
sudo sed -i 's/ServerTokens [a-zA-Z]*/ServerTokens Prod/' /etc/apache2/conf.d/security
sudo sed -i 's/TraceEnable [a-zA-Z]*/TraceEnable Off/' /etc/apache2/conf.d/security


echo "Install rbenv, Ruby, and Rails"
git clone git://github.com/sstephenson/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source /home/ubuntu/.bashrc
git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
# Verbose install used to prevent disconnection of PuTTy shell
# EDIT: if you want a different version of ruby, change the install and global lines
rbenv install -v 1.9.3-p392
rbenv rehash
rbenv global 1.9.3-p392


gem install rails --no-ri --no-rdoc
gem install passenger --no-ri --no-rdoc

echo "Install Passenger Apache2 module"
~/.rbenv/versions/1.9.3-p392/bin/passenger-install-apache2-module -a 
~/.rbenv/versions/1.9.3-p392/bin/passenger-install-apache2-module --snippet >> ~/passenger_install.log

# Parse output of Passenger Apache2 module install, update relevant files
p_log=~/passenger_install.log
{
  read load_module
  read passenger_root
  read passenger_ruby
} < $p_log

sudo sh -c "echo $load_module > /etc/apache2/mods-available/passenger.load"

sudo sh -c "cat > /etc/apache2/mods-available/passenger.conf << EOF
<IfModule passenger_module>
  $passenger_root
  $passenger_ruby
</IfModule>
EOF"

# Enable installed Passenger module
sudo a2enmod passenger

# EDIT: Add your ServerName
# Adds the following VirtualHost code to /etc/apache2/conf.d/virtual.conf
sudo sh -c "cat > /etc/apache2/conf.d/virtual.conf << EOF
<VirtualHost *:80>
   ServerName www.selectrehab.com
   # !!! Be sure to point DocumentRoot to 'public'!
   DocumentRoot $rails_app/public
   <Directory $rails_app/public>
      # This relaxes Apache security settings.
      AllowOverride all
      # MultiViews must be turned off.
      Options -MultiViews
   </Directory>
</VirtualHost>
EOF"

sudo service apache2 restart

echo "All done!"
