# archlinux-install

The collection of scripts for automated ArchLinux Installation.

## How-to use

### Prepeare USB drive with ArchLinux Live installation

Pre-Installation Steps

### Installation on a disk

Check internet conection
```bash
ping -c 5 archlinux.org
```
If no success, configure WiFi network, if required, with  `iwctl`

```
device list
device <interface> show
station <interface> show
station <interface> scan
station <interface> connect <SSID>
station <interface> show
quit
```

Synchronize package databases
```bash
pacman -Sy
```

Install Git
```bash
pacman -S git
```

Clone Git repo for installation scripts
```bash
cd ~
git clone --depth 1 git://github.com/ownport/archlinux-install.git
cd archlinux-install
```


## Documentation

- [https://wiki.archlinux.org/index.php/installation_guide](https://wiki.archlinux.org/index.php/installation_guide)
- [Grub](https://wiki.archlinux.org/index.php/GRUB)
