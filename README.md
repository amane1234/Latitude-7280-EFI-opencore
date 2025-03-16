# Dell Latitude 7280 - macOS Installation Guide

This guide provides detailed instructions for installing **macOS Ventura** on the **Dell Latitude 7280** using the **OpenCore bootloader**. It covers necessary prerequisites, including SMBIOS generation for iServices (iMessage, FaceTime, etc.), as well as key configurations to ensure smooth functionality post-installation.

### Important Notes:
- **Generate Your Own SMBIOS**: To ensure the proper functioning of iServices (iMessage, FaceTime, etc.), it’s critical to **generate your own valid SMBIOS**.
- **Wi-Fi Support**: This EFI uses `itlwm` (Intel Wi-Fi) for wireless connectivity. To enable Wi-Fi, download and install [HeliPort](https://github.com/OpenIntelWireless/HeliPort) for easier management.

---

## Laptop Specifications

| Component                  | Specification                         |
|----------------------------|---------------------------------------|
| **CPU**                     | Intel i5-7200U                       |
| **iGPU**                    | Intel® HD 620 Graphics                |
| **LAN**                     | Intel I219-LM                         |
| **Audio**                   | Realtek ALC256                       |
| **RAM**                     | Kingston 8 GB DDR4 2400 MHz           |
| **Wi-Fi + Bluetooth**       | DW1820 (Intel-8260NGW)                |
| **Storage**                 | SAMSUNG 128 GB NVMe                   |
| **SMBIOS**                  | MacBookPro 14,1                       |
| **Bootloader**              | OpenCore 1.0.3                        |
| **macOS Version**           | macOS Ventura 13.3                    |

---

## Creating a Bootable USB

To create a bootable USB installer for macOS with OpenCore, follow the official [Dortania OpenCore Installation Guide](https://dortania.github.io/OpenCore-Install-Guide/installer-guide/). This guide provides step-by-step instructions for setting up a USB installer, downloading necessary files, and configuring OpenCore for macOS installation.

---

## BIOS Settings

Before booting into macOS, it’s essential to configure specific BIOS settings to ensure macOS boots properly and functions optimally on the Dell Latitude 7280.

### Enable:
- **SATA Operation**: AHCI
- **Fastboot**: Minimal
- **Integrated NIC**: Enable

### Disable:
- **Secure Boot**
- **Absolute**
- **Intel SGX**
- **Wake on AC**
- **Wake on Dell USB-C Dock**
- **Enable UEFI Network Stack**

---

## ⚠️ Important! Hidden BIOS Setting Adjustments ⚠️

This EFI configuration does not enable `AppleXcpmCfgLock`, `framebuffer-fbmem`, or `framebuffer-stolenmem`. To address this, you'll need to use **modGRUBShell.efi** to make the necessary adjustments before installation. Make sure to follow these steps:

1. **Disable CFG Lock**  
   Run the following command in `modGRUBShell`:  
   ```
   setup_var 0x4ED 0x0
   ```

2. **Set DVMT Pre-Allocated Memory to 64MB**  
   To configure DVMT pre-allocated memory, run:  
   ```
   setup_var 0x795 0x2
   ```

3. **Set DVMT Total Graphics Memory to Maximum**  
   To allocate the maximum memory to the iGPU, run:  
   ```
   setup_var 0x796 0x3
   ```

These adjustments ensure compatibility with macOS and prevent boot issues related to graphics and power management.

---

## Post-Installation

After installing macOS and rebooting into the system, follow these steps to complete the installation and enable additional features:

1. **ComboJack Installation**  
   Open the terminal and run the `install.sh` script from the `TOOLS EFI MOD/ComboJack_Installer.zip` directory to enable the headphone jack functionality. After rebooting, the jack should appear as a usable device.

---

## (Experimental) Enable Hibernation (S4)

To enable **S4 Hibernation (Write-to-Disk)**, follow these steps:

1. Set `ThirdpartyDrives` to `true` in your `config.plist`.
2. Set `Hibernatemode` to `Auto` in the `config.plist`.
3. Open the terminal and run:  
   ```
   sudo pmset hibernatemode 3
   ```
If hibernation function is not working

4. Put `Hibernationfixup.kext` to your EFI and add `hbfx-ahbm=37` to your boot-args [Hibernationfixup](https://github.com/acidanthera/HibernationFixup)
5. Put `RTCMemoryFixup.kext` to your EFI and add `rtcfx_exclude=0x80-0xAB` to your boot-args [RTCMemoryFixup](https://github.com/acidanthera/RTCMemoryFixup)

**Note**: Hibernation functionality is experimental and may be unstable, especially when waking from S4. In some cases, issues like failure to reconnect the touchpad may occur.

---
