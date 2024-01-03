# Debugging-starlink-dishy

Our project focused on the binary named ``user_terminal_frontend``. This binary is the core one that handles all the grpc communication going on between the starlink dishy and the user area devices. So once we got the emulator working we tried to run the binary on it and tried to debug what's going on inside it.

## 1. ``user_terminal_frontend`` Setting
To get the ``user_terminal_frontend`` binary working, you will have to do some networking jobs in your emulator. The source code can be found at [quarks lab blog post](https://blog.quarkslab.com/starlink.html). 

### 1-1. Network Interface Setup
We've created a file named ``network.sh`` inside the rootfs folder.(It is uploaded in our repository)
```
#!/bin/sh

ip link set dev eth0 name eth_user
ip link set dev eth_user up
ip addr add 192.168.100.1/24 dev eth_user

route add -net 0.0.0.0 netmask 0.0.0.0 gw 192.168.100.2 dev eth_user
```
And to be able to log in by ssh, we modified some parts in ``rootfs/etc/ssh/sshd_config``.
```
Include /etc/ssh/sshd_host_keys -> comment it out
PasswordAuthentication -> change it to 'yes'
```
**!Make sure that every time you change something in rootfs, you have to do ``build-rootfs.sh`` to get the modification applied to your emulator!**

With that, all the network setting is done and you are good to go!

### 1-2. Usage
To run the ``user_terminal_frontend`` binary, network configuration we'd just set up is needed. So you can execute the binary following these rules.
```
1. start the emulator
2. do the following commands
   cd /
   sh network.sh
3. ./sx/local/runtime/bin/user_terminal_frontend
```
And it will work perfectly😊

## 2. Debugger Setting
To run debugger in you emulation, we had to get statically linked gdb binary and put it inside our ``rootfs``. We found it on github and put it in our rootfs with the following commands.
```
cd rootfs
git clone https://github.com/hugsy/gdb-static
cd ../
./build-rootfs.sh
```

Once you have done that, there will be a ``gdb-static`` folder at ``/`` directory in your emulator. You can now use gdb at this point but to make it easier, we've done some environment path settings.

### 2-1. Environment Path Settings
First of all, we tried to figure out which path the emulator was using by using ``echo $PATH`` command.
```
[root@user1 ]# echo $PATH
/bin:/sbin:/usr/bin:/usr/sbin:/usr/bin/ashfuncs%func
```

It seemed that the default path is ``/bin/``, so we needed to put our gdb binary inside that directory.

Among the binaires in ``gdb-static`` folder, we've decided to use ``gdbserver-8.1.1-aarch64-le`` and ``gdb-8.3.1-aarch64-le`` binary since the core binaries in starlink dishy was using 64 bit mode. So we moved those two binaries to ``rootfs/bin`` and re-builed rootfs.

### 2-2. Usage
If you want to debug right inside the emulator, you can do it by simply typing command ``gdb-8.3.1-aarch64-le [binary name]`` inside the emulator. But in our case, what we wanted to do was execute gdbserver inside the emulator and debug it in our local computer.

Here are specific instructions.
1. start up the emulator and execute ``network.sh`` inside it.
2. move to ``sx/local/runtime/bin``
3. use the command ``gdbserver-8.1.1-aarch64-le localhost:10000 user_terminal_frontend``(10000 is a portnumber I randomly used for the connection. You can use any number you want)
4. open up another terminal in your local pc and type the following commands
   ```
   gdb-multiarch
   target remote 192.168.100.1:10000
   ```

And that is it! Now you can see what's going on inside ``user_terminal_frontend``!

## 3. Giving Symbols to ``user_terminal_frontend``
We needed symbols in ``user_terminal_frontend`` binary to get work done easily. So we used a ida plugin called ``sym2elf`` and ``go plugin`` for it.

This is how it goes.
### 3-1. ``Go`` plugin
1. download zip file from [go plugin github](https://github.com/SentineLabs/AlphaGolang)
2. execute ida pro with ``user_terminal_frontend`` binary
3. choose ``File -> Script -> script file``
You will see 6 script files. Execute all and you will see symbols getting on inside the binary

### 3-2. ``sym2elf`` plugin
1. download the plugin file from [sym2elf github](https://github.com/danigargu/syms2elf)
2. move ``sym2elf.py`` file into ida plugin folder
3. execute ida pro
4. choose ``EDIT -> plugins -> sym2elf`` and choose where and name to generate a symbol-generated binary

Now you have the symbols not stripped ``user_terminal_frontend`` binary in your hand😁
