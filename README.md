ec2-rails-setup
===============

Bash script for prepping a fresh AWS EC2 Ubuntu instance for Rails deployment.

This script will install packages and config files necessary to deploy a MySQL-backed Rails app utilizing Apache2 and Phusion Passenger.

To run:
-------

    curl -O https://raw.github.com/ilunderskov/ec2-rails-setup/master/ec2-rails-setup.sh 
    sudo vi ec2-rails-setup.sh
Edit the bash script's user-defined fields, identified by EDIT comments

    sudo ec2-rails-setup.sh


What the script does:
--------------------

* Updates the EC2 instance
* Changes the time zone
* Installs Rails-related apt-get packages (see script for specifics)
* Disables some Apache mods, edits Apache config file
* Installs RVM running 1.9.3 latest patch level
* Installs MySQL cilent
* Installs Rails and Passenger gems
* Install Passenger Apache2 module
* Adds Passenger config files


Remember to <code>touch tmp/restart.txt</code> within your Rails app once you have the code loaded up to restart the Passenger module.
