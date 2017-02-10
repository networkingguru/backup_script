#!/usr/bin/env bash

#Universal Backup Script

#   USAGE
#   Read comments beside the user config section below, then complete the necessary config sections
#   chmod the script to give read and execute permissions to your account
#   Run the script (./backup.sh)
#   Answer the prompts

#   REQUIREMENTS
#   Debian-based Linux (Tested with Ubuntu 12.10, 13.04, and 13.10)
#   GNU Privacy Guard (http://www.gnupg.org/)
#   RAR for Usenet Backups (http://askubuntu.com/questions/244198/how-to-install-rar-no-installation-candidate)
#   PAR2 for Usenet Backups (sudo apt-get install par2)
#   grive should be installed and fully configured for Google Backups (http://www.lbreda.com/grive/)
#   Newsmangler (https://github.com/madcowfred/newsmangler) or Newspost (http://newspost.unixcab.org/) should be installed and fully configured for Usenet backups

#   RESTORING BACKUPS
#   Basically, you are going to have to do everything in reverse. I haven't found a good way to script this, 
#   largely because the process to pull the post down from Usenet and convert it back into a GPG is a bit convoluted.
#   Also, since the backup is the thing that you will do often, and a restore fairly rarely, I don't know that 
#   spending a lot of time on a restore script is really warranted. If there's a big demand, though, I will post up 
#   my notes on manually doing it so you can at least have a starting point. 
#   Cheers,
#   Brian 

#---------- user config start ----------
username="user"                     #Enter your Usenet Server Login Here
password="password"                 #Enter your Usenet Server Password Here
server="news.isp.net"               #Enter your Usenet Server Here
temppath="/backup/"                 #Path where all backup files should be stored. Should NOT be part of ~, and you will need full permissions to this path
newsgroup="alt.binaries.backup"     #Newsgroup to post to. The default is a good spot, usually.
email="not@telling.com"             #Poster email address. Helps you find the post to download it.
subject="${HOSTNAME} ${now} backup" #Subject line of newsgroup post. $now timestamps it with the date.
bin_path="/home/user"               #Path where backup.sh and restore.sh are kept
gpg_password='password'             #Password for GPG encryption. Single and double quote this password if it has spaces, otherwise single quote only.

#---------- user config end ----------

#---------- system config start ----------
now=$(date +"%m-%d-%Y")                         #Do not edit.
kernel="kernel.${now}"                          #Do not edit.
kernel_gpg="${kernel}.gpg"                      #Do not edit.
backup_tarball="backup.${now}.tar.gz"           #Do not edit.
input_file="${temppath}${backup_tarball}.gpg"   #Do not edit.
output_file="${temppath}${now}.cruft.rar"       #Do not edit.
input_file_to_keep="${backup_tarball}.gpg"      #Do not edit.
output_file_to_keep="${now}.cruft.rar.*.par2"   #Do not edit.
kernel_backup_path="${temppath}${kernel}/"      #Do not edit.
sys_username="$(whoami)/"                       #Do not edit.
#---------- system config end ----------

function kernel_bu {
    #Backup core components
    dpkg --get-selections > ~/Package.list
    sudo cp /etc/apt/sources.list ~/sources.list
    sudo apt-key exportall | tee -a ~/Repo.keys >/dev/null
    sudo mkdir "${kernel_backup_path}"
    sudo chown -R "${sys_username}" "${temppath}"
    cp $bin_path/backup.sh "${kernel_backup_path}"
    cp $bin_path/restore.sh "${kernel_backup_path}"
    cp ~/Package.list "${kernel_backup_path}"
    cp ~/sources.list "${kernel_backup_path}"
    cp ~/Repo.keys "${kernel_backup_path}"
    tar -zcvf "${temppath}${kernel}.tar.gz" "${kernel_backup_path}"

    #Encrypt core
    echo "${gpg_password}" | gpg --yes --batch --passphrase-fd 0 -c "${temppath}${kernel}.tar.gz"
}

function gen_bu {
#If the gpg exists, then exit   
    if [ -f "${temppath}${input_file}" ]; then
        echo "GPG Present, skipping general backup"
        echo "Deleting old junk"
        find "/backup" -maxdepth 1 -type f -not -name "${backup_tarball}" -not -name "${input_file_to_keep}" -not -name "${output_file_to_keep}" -not -name "${kernel_gpg}" | xargs -0 rm

#Else if the tar exists, create the gpg, then exit
    elif [ -f "${temppath}${backup_tarball}" ]; then
        echo "Tarball Present, creating gpg"
        echo "Deleting old junk"
        cd "${temppath}" || exit 1
        find "/backup" -maxdepth 1 -type f -not -name "${backup_tarball}" -not -name "${input_file_to_keep}" -not -name "${output_file_to_keep}" -not -name "${kernel_gpg}" | xargs -0 rm
        echo "${gpg_password}" | gpg --yes --batch -z0 --passphrase-fd 0 -c "${backup_tarball}"

#Else if the backup folder exists, create the tar, then the gpg, then exit
    elif [ -f "${temppath}${sys_username}" ]; then
        echo "Folder Present, creating tarball and gpg"
        echo "Deleting old junk"
        cd "${temppath}" || exit 1
        find "/backup" -maxdepth 1 -type f -not -name "${backup_tarball}" -not -name "${input_file_to_keep}" -not -name "{$output_file_to_keep}" -not -name "${kernel_gpg}" | xargs -0 rm
        tar -zcvf "${temppath}${backup_tarball}" "${temppath}${sys_username}"
        echo "${gpg_password}" | gpg --yes --batch -z0 --passphrase-fd 0 -c "${backup_tarball}"

#Else do everything
    else
        echo "Nothing found, performing full backup"
        kernel_bu
        echo "Kernel Backup complete"
        rsync --progress -ra --exclude '*.iso' --exclude '*.ISO' "/home/$(whoami)" "${temppath}"
        echo "Deleting old junk"
        cd "${temppath}" || exit 1
        find "${temppath}" -maxdepth 1 -type f -not -name "${backup_tarball}" -not -name "${input_file_to_keep}" -not -name "${output_file_to_keep}" -not -name "${kernel}" -not -name "${kernel_gpg}" | xargs -0 rm
        tar -zcvf "${temppath}${backup_tarball}" "${temppath}${sys_username}"
        echo "${gpg_password}" | gpg --yes --batch -z0 --passphrase-fd 0 -c "${backup_tarball}"
    fi
}

function mu_bu {
    echo "Beginning Usenet backup"
    if [ ! -f "${temppath}${output_file_to_keep}" ]; then
        rar a "${output_file}" "${input_file}"
        par2 c -s2250000 -r10 "${output_file}"
    fi

    echo "Posting Kernel"
    python /usr/local/bin/mangler/mangler.py -f "${subject} kernel" "${temppath}${kernel}"

    echo "Posting main backup"
    python /usr/local/bin/mangler/mangler.py -f  "${subject}" "${temppath}${output_file_to_keep}"
    python  /usr/local/bin/mangler/mangler.py -f  "${subject}" "${output_file}"
}

function nu_bu {
    echo "Beginning Usenet backup"
    if [ ! -f "${temppath}${output_file_to_keep}" ]; then
        rar a "${output_file}" "${input_file}"
        par2 c -s2250000 -r10 "${output_file}"
    fi

    echo "Posting Kernel"
    newspost -i "${server}" -u "${username}" -p "${password}" -f "${email}" -n "${newsgroup}" -y -z 119 -s "${subject}" "${temppath}${kernel}"

    echo "Posting main backup"
    newspost -i "${server}" -u "${username}" -p "${password}" -f "${email}" -n "${newsgroup}" -y -z 119 -s "${subject}" "${temppath}/*.par2"
    newspost -i "${server}" -u "${username}" -p "${password}" -f "${email}" -n "${newsgroup}" -y -z 119 -s "${subject}" "${output_file}"
}

function g_bu {
    echo "Beginning Google backup"
    rm ~/google_drive/*.gpg
    echo "Deleted old gpg, now syncing"
    grive
    cp $temppath*.gpg ~/google_drive/
    echo "Copied new gpg, syncing"
    cd "~/google_drive" || exit 1
    grive
}


while true; do
    read -p -r "Type of backup (Usenet/Google)" type
    case $type in
        [Uu]*)
        read -p -r "Type is Usenet, Choose a Method (Mangler/Newspost)" method
        case $method in
                [Mm]*) echo "Method is Mangler, beginning backup";
                gen_bu; mu_bu; exit;;
                [Nn]*) echo "Method is Newspost, beginning backup"; gen_bu; nu_bu; exit;;
                *) echo "Please answer M or N.";;
        esac;;
        [Gg]*) echo "Type is Google, beginning general backup"; gen_bu; g_bu; exit;;
        *) echo "Please answer U or G.";;
    esac
done
