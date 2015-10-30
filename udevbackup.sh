#!/bin/bash

# Tested on Ubuntu 14.04 Server

# requirements
# sudo apt-get install cifs-utils at ntfs-3g

UDEVBACKUP_LOG_FILE=/var/log/udevbackup.log
UDEVBACKUP_RUN_PID=/var/run/udevbackup.run
AT_CMD=/usr/bin/at

# change to fit your needs
SMB_SHARE=[[SMB_SHARE]]
SMB_DOMAIN=[[SMB_DOMAIN]]
SMB_USER=[[SMB_USER]]
SMB_PASSWORD='[[SMB_PASSWORD]]'

MOUNT_POINT=/mnt/win_share_backup

log()
{
    local cur_time=$(date -R)
    local separator=" | "
    echo "$cur_time$separator$1" >> $UDEVBACKUP_LOG_FILE
}

is_plug()
{
    if [[ $ACTION = 'add' ]]; then
        return 0
    else
        return 1
    fi
}

change_state_to_unplugged()
{
    unlink $UDEVBACKUP_RUN_PID
}

change_state_to_plugged()
{
    echo "plugged" > $UDEVBACKUP_RUN_PID
}

is_running()
{
    if [[ -f $UDEVBACKUP_RUN_PID ]]; then
        return 0
    else
        return 1
    fi
}

mount_smb_share()
{

    local mounted=$(mount | grep $MOUNT_POINT)
    [[ ! -z $mounted ]] && umount $MOUNT_POINT

    [[ ! -d $MOUNT_POINT ]] && mkdir $MOUNT_POINT

    mount -t cifs -o uid=`id -u`,domain=$SMB_DOMAIN,username=$SMB_USER,password=$SMB_PASSWORD $SMB_SHARE $MOUNT_POINT
    log "INFO: smb share is mounted"
}

create_copy_job()
{
    echo "rm -rf $DEST_DIR/* && cp -rf $MOUNT_POINT/* $DEST_DIR" | $AT_CMD 23:00 saturday
    log "INFO: job for copying backups is created"
    log "INFO: `atq`"
}

set_mount_point()
{
    DEST_DIR=/mnt/backup_drive

    local mounted=$(mount | grep $DEST_DIR)
    [[ ! -z $mounted ]] && umount $DEST_DIR


    [[ ! -d $DEST_DIR ]] && mkdir $DEST_DIR 
    mount -t ntfs -v $DEVNAME $DEST_DIR
    log "INFO: mount point found at: $DEST_DIR"
}

clear_on_unplug()
{
    rmdir $DEST_DIR
    rmdir $win_share_backup
}

usage()
{
    log "Usage: $0 [dest_dir]"
}



if [[ $1 = "--help" ]]; then 
    usage
    exit 1
fi    


# main
if $(is_plug); then

    if [[ ! -f $UDEVBACKUP_LOG_FILE ]]; then
       touch $UDEVBACKUP_LOG_FILE;
    fi

    if [[ ! -f $AT_CMD && ! -e $AT_CMD ]]; then
       log "ERROR: /usr/bin/at command not found."
       exit 1
    fi


    change_state_to_plugged
    log "INFO: **** backup device is plugged ****"
    log "INFO: ------------------------------------"

    mount_smb_share
    set_mount_point
    create_copy_job    
fi

if ! $(is_plug); then
    change_state_to_unplugged
    log "INFO: **** backup device is unplugged ****"
    log "INFO: ------------------------------------"

    clear_on_unplug
fi
