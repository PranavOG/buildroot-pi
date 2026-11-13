# Buildroot for Raspberry Pi 4 & Pi 5

Custom [Buildroot](https://buildroot.org/) configuration for building minimal Linux images targeting the **Raspberry Pi 4 (64-bit)** and **Raspberry Pi 5**.

The build includes a curated set of packages on top of the stock Buildroot Pi defconfigs:

| Package | Purpose |
|---------|---------|
| Pylon SDK | Basler machine-vision camera support |
| Python 3 | Scripting runtime |
| NumPy, Pillow | Image/numerical processing |
| pySerial, Requests | Serial & HTTP communication |
| libusb | USB device access |
| Dropbear | Lightweight SSH server |
| rsync | File synchronisation |
| nano, vim | Text editors |
| kmod | Kernel module tools |

> [!NOTE]
> The **Pylon SDK** is proprietary. You must place the aarch64 tarball at `~/projects/downloads/pylon_linux-aarch64_26101.tar.gz` before building. Obtain it from [Basler's download page](https://www.baslerweb.com/en/downloads/software-downloads/).

---

## Prerequisites

### Host System

A **Linux x86_64** host is required. Tested on Ubuntu 22.04+/Debian 12+.

Install the required build dependencies:

```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential gcc g++ sed make binutils \
    diffutils bash patch gzip bzip2 perl tar cpio \
    unzip rsync file bc findutils wget python3 \
    libncurses-dev libssl-dev
```

### Pylon SDK Tarball

Place the Basler Pylon aarch64 tarball so Buildroot can find it:

```bash
mkdir -p ~/projects/downloads
# Copy or download pylon_linux-aarch64_26101.tar.gz into ~/projects/downloads/
```

---

## Building

### Clone the Repository

```bash
git clone git@github.com:PranavOG/buildroot-pi.git
cd buildroot-pi
```

### Raspberry Pi 4 (64-bit)

```bash
# Load the Pi 4 defconfig
make raspberrypi4_64_defconfig

# Build (takes 30-90 min depending on your machine)
make -j$(nproc)
```

The output image will be at `output/images/sdcard.img`.

### Raspberry Pi 5

```bash
# IMPORTANT: Buildroot requires a clean output directory when switching targets.
# Either clean first, or use an out-of-tree build (recommended).

# Option A: Clean build (in-tree)
make clean
make raspberrypi5_defconfig
make -j$(nproc)

# Option B: Out-of-tree build (lets you keep both builds simultaneously)
make O=output_pi5 raspberrypi5_defconfig
make O=output_pi5 -j$(nproc)
```

The output image will be at `output/images/sdcard.img` (Option A) or `output_pi5/images/sdcard.img` (Option B).

> [!TIP]
> **Building for both targets simultaneously** — use out-of-tree builds so you don't have to clean between targets:
> ```bash
> make O=output_pi4 raspberrypi4_64_defconfig
> make O=output_pi4 -j$(nproc)
>
> make O=output_pi5 raspberrypi5_defconfig
> make O=output_pi5 -j$(nproc)
> ```

### Customising the Configuration

To interactively tweak packages or kernel options:

```bash
# For Pi 4
make raspberrypi4_64_defconfig
make menuconfig          # interactive package/system configuration
make linux-menuconfig    # interactive kernel configuration
make -j$(nproc)

# Save your changes back to the defconfig
make savedefconfig
cp defconfig configs/raspberrypi4_64_defconfig
```

Repeat with the Pi 5 defconfig as needed.

---

## Flashing to an SD Card

### Identify Your SD Card

Insert the SD card and find its device name:

```bash
lsblk
```

Look for the SD card device (e.g., `/dev/sdX` or `/dev/mmcblkX`). **Double-check you have the correct device** — writing to the wrong one will destroy data.

### Flash with `dd`

```bash
# Unmount any auto-mounted partitions first
sudo umount /dev/sdX1 /dev/sdX2 2>/dev/null || true

# Write the image (adjust the path if using out-of-tree builds)
sudo dd if=output/images/sdcard.img of=/dev/sdX bs=4M status=progress conv=fsync

# Ensure all data is written
sudo sync
```

> [!CAUTION]
> **Triple-check the `of=` device.** Writing to the wrong device (e.g., your system disk) will result in permanent data loss.

### Flash with Balena Etcher (GUI alternative)

1. Download [Balena Etcher](https://etcher.balena.io/)
2. Select `output/images/sdcard.img`
3. Select your SD card
4. Click **Flash**

### Flash with Raspberry Pi Imager

1. Open [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. Choose OS → **Use custom** → select `sdcard.img`
3. Choose your SD card
4. Click **Write**

---

## Booting

1. Insert the flashed SD card into your Raspberry Pi
2. Connect an Ethernet cable (the image is configured for DHCP on `eth0`)
3. Connect power

### Serial Console

The Pi 4 image enables a console on HDMI (`tty1`) and the default serial console. Connect via:

```bash
# USB-to-serial adapter at 115200 baud
screen /dev/ttyUSB0 115200
# or
minicom -D /dev/ttyUSB0 -b 115200
```

### SSH Access

Dropbear SSH is enabled. Once booted and on the network:

```bash
ssh root@<pi-ip-address>
```

Default credentials:

| User | Password |
|------|----------|
| `root` | `root` |

> [!WARNING]
> Change the root password immediately after first boot: `passwd root`

---

## Network Configuration

The Pi 4 image ships with a static IP configuration in the rootfs overlay for a specific USB-Ethernet adapter. To change it, edit:

- **Static IP**: [`board/raspberrypi4-64/rootfs-overlay/etc/network/interfaces`](board/raspberrypi4-64/rootfs-overlay/etc/network/interfaces)
- **DNS**: [`board/raspberrypi4-64/rootfs-overlay/etc/resolv.conf`](board/raspberrypi4-64/rootfs-overlay/etc/resolv.conf)

Or, for DHCP on all interfaces, replace the interfaces file with:

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
```

---

## Project Structure

```
.
├── configs/
│   ├── raspberrypi4_64_defconfig   # Pi 4 (64-bit) with custom packages
│   └── raspberrypi5_defconfig      # Pi 5 stock defconfig
├── package/
│   └── pylon/                      # Custom Pylon SDK package
│       ├── Config.in
│       ├── pylon.mk
│       └── pylon.hash
├── board/
│   ├── raspberrypi4-64/            # Pi 4 board support files
│   │   ├── post-build.sh
│   │   ├── post-image.sh
│   │   ├── genimage.cfg.in
│   │   └── rootfs-overlay/         # Files overlaid onto the rootfs
│   └── raspberrypi5/               # Pi 5 board support files
│       ├── post-build.sh
│       ├── post-image.sh
│       └── genimage.cfg.in
└── ...                             # Standard Buildroot tree
```

---

## Rebuilding After Changes

```bash
# Rebuild everything after a config change
make -j$(nproc)

# Rebuild a single package (e.g., pylon)
make pylon-rebuild

# Full clean rebuild
make clean
make raspberrypi4_64_defconfig   # or raspberrypi5_defconfig
make -j$(nproc)
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Build fails on missing Pylon tarball | Ensure `~/projects/downloads/pylon_linux-aarch64_26101.tar.gz` exists |
| `make` errors after switching defconfigs | Run `make clean` before loading a different defconfig |
| SD card not booting | Verify `dd` targeted the correct device; try reflashing |
| No network after boot | Check Ethernet cable; verify `/etc/network/interfaces` matches your setup |
| SSH connection refused | Confirm Dropbear is running: `ps aux \| grep dropbear` |

---

## License

Buildroot itself is licensed under [GPL-2.0+](COPYING). Individual packages carry their own licenses. The Pylon SDK is proprietary — see Basler's license terms.
