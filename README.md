# backup_script

Universal Free Backup Script for Linux

#### CI Status

[![Build Status](https://travis-ci.org/networkingguru/backup_script.svg?branch=master)](https://travis-ci.org/networkingguru/backup_script)

##  USAGE

Read comments beside the user config section below, then complete the necessary config sections
chmod the script to give read and execute permissions to your account
Run the script (./backup.sh)
Answer the prompts

## REQUIREMENTS

* Debian-based Linux (Tested with Ubuntu 12.10, 13.04, and 13.10)
* GNU Privacy Guard (http://www.gnupg.org/)
* RAR for Usenet Backups (http://askubuntu.com/questions/244198/how-to-install-rar-no-installation-candidate)
* PAR2 for Usenet Backups (sudo apt-get install par2)
* grive should be installed and fully configured for Google Backups (http://www.lbreda.com/grive/)
* Newsmangler (https://github.com/madcowfred/newsmangler) or Newspost (http://newspost.unixcab.org/) should be installed and fully configured for Usenet backups

## RESTORING BACKUPS

Basically, you are going to have to do everything in reverse. I haven't found a good way to script this, 
largely because the process to pull the post down from Usenet and convert it back into a GPG is a bit convoluted.
Also, since the backup is the thing that you will do often, and a restore fairly rarely, I don't know that 
spending a lot of time on a restore script is really warranted. If there's a big demand, though, I will post up 
my notes on manually doing it so you can at least have a starting point. 
Cheers,
Brian (runningones@gmail.com)
