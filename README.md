### PXE-Boot-Server

This project automates the creation of a PXE Boot Server on a live CD. It supports RPM based distribution only.

### CREATING A PXE BOOT SERVER ON LIVE CD.

To spin a live CD, `livecd-creator` is needed on the host where live CD is being created.

Extract this package to a directory, exmaple in `$HOME`.

```bash
misc/mkpxeboot.sh <path to kickstart configuration>[:arch] targetCluster targetOS

where: targetCluster is one of OVM, OpenStack, and default.
       targetOS is one of FC, OEL7, and OEL6
       arch is i686 or x86_64 (default)
```

Example:

```bash
       misc/mkpxeboot.sh Oracle/kickstart/PXE-Boot-Server.ks:x86_64 default FC
```

Other rpm based distro can be added by simply creating `repo-<distro>.ks` in `Oracle/kickstart` directory which should contain the repository location of the distro.

The live CD can have a different OS than the OS it will serve out to pxe clients.

The `%post -=-nochroot` section of the file `PXE-Boot-Server/PXE-Boot-Server.ks` can be modified to include copying an iso into the live CD image which can be mounted to `/var/lib/tftpboot/os/<distro>/<version>/<arch>` on boot. This directory will serve as the installation source.

### USING THE LIVE CD PXE BOOT SERVER.

Creating a kickstart file can be interactive or batched. For interactive script, run the script `config-kickstart.sh`.

For batched, run the command `mass-ks.sh < inputfile`.

The input file is a csv with entries in the following format:

```
hostname,IPAddress,disk,MACaddr,other options available by running config-kickstart.sh -h such as -v <distro>/<ver>
```

Example:

```
mynewvm,192.168.1.40,xvda,00:16:3e:38:f2:40,-u -v oel/6.6
```

The `<distro>/<ver>` should match those served in `/var/lib/tftpboot/os` directory.
