sudo cp disable-devices-as-wakeup.service /etc/systemd/system/
sudo cp disable-devices-as-wakeup.sh /etc/systemd/system/

systemctl enable disable-devices-as-wakeup.service
systemctl status disable-devices-as-wakeup.service
