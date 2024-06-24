#!/bin/sh

### Default values for UID, GID, USERNAME and PASSWORD
UID=${UID:-1000}
GID=${GID:-1000}
USERNAME=${USERNAME:-xo}
PASSWORD=${PASSWORD:-password}

### Create the user and group with specified UID and GID
groupadd -g $GID $USERNAME
useradd -u $UID -g $GID -d /home/$USERNAME -s /bin/sh $USERNAME
mkdir -p /home/$USERNAME
chown -R $USERNAME:$USERNAME /home/$USERNAME
chmod 777 /home/$USERNAME

### Update the smb.conf file
sed "s/{{USERNAME}}/$USERNAME/g" /etc/samba/smb.conf.template > /etc/samba/smb.conf

### Set the Samba password
echo "$USERNAME:$PASSWORD" | chpasswd
(echo "$PASSWORD"; echo "$PASSWORD") | smbpasswd -a -s $USERNAME

### Start the Samba service
exec smbd -F --no-process-group
