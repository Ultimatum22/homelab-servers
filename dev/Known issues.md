
## Hostnamectl

### Issue

$ sudo strace -f hostnamectl
...snipped...
connect(3, {sa_family=AF_UNIX, sun_path="/var/run/dbus/system_bus_socket"}, 33) = -1 ENOENT (No such file or directory)
...

Failed to create bus connection: No such file or directory

### Fix

`sudo service systemd-logind start`
