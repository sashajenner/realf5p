ansible all -m shell -a "service f5p_daemon stop" -K -b
ansible all -m copy -a "scripts/f5p_daemon.service dest=/etc/systemd/system/f5p_daemon.service mode=0644" -K -b
ansible all -m shell -a "service f5p_daemon start" -K -b