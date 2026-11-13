# Buildroot for Raspberry Pi 4 & Pi 5

Custom [Buildroot](https://buildroot.org/) configuration for building minimal Linux images targeting the **Raspberry Pi 4 (64-bit)** and **Raspberry Pi 5**.

The Pi 4 defconfig (`raspberrypi4_64_defconfig`) is already customised with all the packages below. The stock Pi 5 defconfig (`raspberrypi5_defconfig`) ships with Buildroot as a minimal base — this guide walks you through adding the same packages to it.

## Included Custom Packages (Pi 4)

| Package | Purpose |
|---------|---------|
| Pylon SDK | Basler machine-vision camera support |
| Python 3 | Scripting runtime |
| NumPy, Pillow | Image / numerical processing |
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

A **Linux x86_64** host is required (tested on Ubuntu 22.04+ / Debian 12+).

```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential gcc g++ sed make binutils \
    diffutils bash patch gzip bzip2 perl tar cpio \
    unzip rsync file bc findutils wget python3 \
    libncurses-dev libssl-dev
```

### Pylon SDK Tarball

```bash
mkdir -p ~/projects/downloads
# Copy or download pylon_linux-aarch64_26101.tar.gz into ~/projects/downloads/
```

---

## Clone the Repository

```bash
git clone git@github.com:PranavOG/buildroot-pi.git
cd buildroot-pi
```

---

## Building for Raspberry Pi 4 (64-bit)

The custom defconfig is ready to go — just load and build:

```bash
make raspberrypi4_64_defconfig
make -j$(nproc)
```

Output image: `output/images/sdcard.img`

---

## Building for Raspberry Pi 5

The stock `raspberrypi5_defconfig` is a minimal config. To build a Pi 5 image with the **same packages** as the Pi 4, you need to start from that defconfig and add packages via `menuconfig`.

### Step 1 — Load the Pi 5 base defconfig

```bash
# Clean any previous Pi 4 build first (required when switching targets)
make clean

make raspberrypi5_defconfig
```

### Step 2 — Add custom packages via menuconfig

```bash
make menuconfig
```

Navigate through the menus and enable each of the following:

#### System configuration
- `System configuration` → `Root password` → set to `root` (or your choice)
- `System configuration` → `/dev management` → select `Dynamic using devtmpfs + eudev`

#### Toolchain (required for C++ / Pylon)
The Pi 5 defconfig uses an **external Bootlin toolchain** by default. To enable C++ support with the internal toolchain instead (needed for Pylon):
- `Toolchain` → `Toolchain type` → select `Buildroot toolchain`
- `Toolchain` → `C++ support` → enable

> [!IMPORTANT]
> If you keep the external Bootlin toolchain, Pylon and other C++-dependent packages may not build. Switch to the Buildroot internal toolchain for full compatibility.

#### Target packages

| Menu path | Option to enable |
|-----------|-----------------|
| `Target packages` → `Libraries` → `Hardware handling` | `pylon` |
| `Target packages` → `Interpreter languages and scripting` | `python3` |
| `Target packages` → `Libraries` → `Other` | `python-numpy` |
| `Target packages` → `Libraries` → `Graphics` | `python-pillow` |
| `Target packages` → `Libraries` → `Networking` | `python-requests` |
| `Target packages` → `Hardware handling` | `python-serial` |
| `Target packages` → `Libraries` → `Hardware handling` | `libusb` |
| `Target packages` → `Networking applications` | `dropbear` |
| `Target packages` → `System tools` | `rsync` |
| `Target packages` → `System tools` | `kmod` → `kmod tools` |
| `Target packages` → `Text editors and viewers` | `nano` |
| `Target packages` → `Text editors and viewers` | `vim` |
| `Target packages` → `Compressors and decompressors` | `xz-utils` |

#### Filesystem
- `Filesystem images` → `ext2/3/4 root filesystem` → `ext4`
- `Filesystem images` → `ext2/3/4 root filesystem` → `exact size` → `2G` (increase from the default 120M)

#### Rootfs overlay (optional)
If you want the same static network config as the Pi 4 build:
- `System configuration` → `Root filesystem overlay directories` → set to `board/raspberrypi5/rootfs-overlay`
- Then copy the overlay files:
  ```bash
  mkdir -p board/raspberrypi5/rootfs-overlay/etc/network
  cp board/raspberrypi4-64/rootfs-overlay/etc/network/interfaces \
     board/raspberrypi5/rootfs-overlay/etc/network/
  cp board/raspberrypi4-64/rootfs-overlay/etc/resolv.conf \
     board/raspberrypi5/rootfs-overlay/etc/
  ```
  Edit the `interfaces` file to match your Pi 5's network adapter name.

Save and exit menuconfig.

### Step 3 — Save your custom Pi 5 defconfig

```bash
make savedefconfig
cp defconfig configs/custom_raspberrypi5_defconfig
```

Now you can reload this config in the future with:

```bash
make custom_raspberrypi5_defconfig
```

### Step 4 — Build

```bash
make -j$(nproc)
```

Output image: `output/images/sdcard.img`

> [!TIP]
> **Building both targets simultaneously** — use out-of-tree builds so you don't have to clean between targets:
> ```bash
> make O=output_pi4 raspberrypi4_64_defconfig
> make O=output_pi4 -j$(nproc)
>
> make O=output_pi5 raspberrypi5_defconfig   # or custom_raspberrypi5_defconfig
> make O=output_pi5 -j$(nproc)
> ```
> Images will be at `output_pi4/images/sdcard.img` and `output_pi5/images/sdcard.img`.

---

## Key Differences: Pi 4 vs Pi 5

| | Raspberry Pi 4 (64-bit) | Raspberry Pi 5 |
|---|---|---|
| **CPU** | Cortex-A72 (BCM2711) | Cortex-A76 (BCM2712) |
| **Kernel defconfig** | `bcm2711` | `bcm2712` |
| **Device trees** | `bcm2711-rpi-4-b`, `bcm2711-rpi-400`, `bcm2711-rpi-cm4`, `bcm2711-rpi-cm4s` | `bcm2712-rpi-5-b`, `bcm2712d0-rpi-5-b`, `bcm2712-rpi-500` |
| **Firmware config** | `board/raspberrypi4-64/config_4_64bit.txt` | `board/raspberrypi5/config_5.txt` |
| **Kernel fragment** | — | `board/raspberrypi/linux-4k-page-size.fragment` (4K page size) |
| **Board scripts** | `board/raspberrypi4-64/post-{build,image}.sh` | `board/raspberrypi5/post-{build,image}.sh` |

---

## Flashing to an SD Card

### Identify Your SD Card

Insert the SD card and find its device name:

```bash
lsblk
```

Look for the SD card (e.g., `/dev/sdX` or `/dev/mmcblkX`).

### Flash with `dd`

```bash
# Unmount any auto-mounted partitions
sudo umount /dev/sdX1 /dev/sdX2 2>/dev/null || true

# Write the image
sudo dd if=output/images/sdcard.img of=/dev/sdX bs=4M status=progress conv=fsync

# Ensure all data is flushed
sudo sync
```

> [!CAUTION]
> **Triple-check the `of=` device.** Writing to the wrong device (e.g., your system disk) will cause permanent data loss.

### Flash with Balena Etcher (GUI)

1. Download [Balena Etcher](https://etcher.balena.io/)
2. Select `output/images/sdcard.img`
3. Select your SD card
4. Click **Flash**

### Flash with Raspberry Pi Imager (GUI)

1. Open [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. Choose OS → **Use custom** → select `sdcard.img`
3. Choose your SD card
4. Click **Write**

---

## Booting

1. Insert the flashed SD card into your Raspberry Pi
2. Connect an Ethernet cable (DHCP is enabled on `eth0`)
3. Connect power

### Serial Console

```bash
# USB-to-serial adapter at 115200 baud
screen /dev/ttyUSB0 115200
# or
minicom -D /dev/ttyUSB0 -b 115200
```

The Pi 4 image also enables an HDMI console on `tty1`.

### SSH Access (Pi 4 image)

Dropbear SSH is enabled out of the box:

```bash
ssh root@<pi-ip-address>
```

| User | Password |
|------|----------|
| `root` | `root` |

> [!WARNING]
> Change the root password immediately after first boot: `passwd root`

---

## Network Configuration

The Pi 4 image includes a static IP configuration in the rootfs overlay. To change it, edit:

- [`board/raspberrypi4-64/rootfs-overlay/etc/network/interfaces`](board/raspberrypi4-64/rootfs-overlay/etc/network/interfaces)
- [`board/raspberrypi4-64/rootfs-overlay/etc/resolv.conf`](board/raspberrypi4-64/rootfs-overlay/etc/resolv.conf)

For DHCP on all interfaces, replace the interfaces file contents with:

```
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
```

---

## Customising the Configuration

```bash
# Load a defconfig
make raspberrypi4_64_defconfig   # or raspberrypi5_defconfig

# Interactive package/system configuration
make menuconfig

# Interactive kernel configuration
make linux-menuconfig

# Build
make -j$(nproc)

# Save changes back to a defconfig
make savedefconfig
cp defconfig configs/<your_defconfig_name>
```

---

## Rebuilding After Changes

```bash
# Incremental rebuild
make -j$(nproc)

# Rebuild a single package
make pylon-rebuild
make python3-rebuild

# Full clean rebuild (required when switching between Pi 4 and Pi 5)
make clean
make <defconfig_name>
make -j$(nproc)
```

---

## Project Structure

```
.
├── configs/
│   ├── raspberrypi4_64_defconfig   # Pi 4 (64-bit) — customised with all packages
│   └── raspberrypi5_defconfig      # Pi 5 — stock Buildroot base
├── package/
│   └── pylon/                      # Custom Pylon SDK package
│       ├── Config.in
│       ├── pylon.mk
│       └── pylon.hash
├── board/
│   ├── raspberrypi4-64/            # Pi 4 board support
│   │   ├── post-build.sh
│   │   ├── post-image.sh
│   │   ├── genimage.cfg.in
│   │   └── rootfs-overlay/
│   └── raspberrypi5/               # Pi 5 board support
│       ├── post-build.sh
│       ├── post-image.sh
│       └── genimage.cfg.in
└── ...                             # Standard Buildroot tree
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Build fails on missing Pylon tarball | Ensure `~/projects/downloads/pylon_linux-aarch64_26101.tar.gz` exists |
| `make` errors after switching between Pi 4 / Pi 5 | Run `make clean` before loading the other defconfig |
| Pylon won't build with external toolchain | Switch to the Buildroot internal toolchain and enable C++ support |
| SD card not booting | Verify `dd` targeted the correct device; try re-flashing |
| No network after boot | Check cable; verify `/etc/network/interfaces` matches your adapter |
| SSH connection refused | Confirm Dropbear was enabled in menuconfig |
| Root filesystem too small | Increase `BR2_TARGET_ROOTFS_EXT2_SIZE` in menuconfig (default is 120M for Pi 5) |

---

## License

Buildroot itself is licensed under [GPL-2.0+](COPYING). Individual packages carry their own licenses. The Pylon SDK is proprietary — see Basler's license terms.
