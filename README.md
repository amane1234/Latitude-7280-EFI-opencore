# Dell Latitude 7280 - macOS Installation Guide

This guide provides step-by-step instructions for installing macOS Ventura 13.3 on the **Dell Latitude 7280** using the **OpenCore bootloader**. It covers essential prerequisites, including setting up SMBIOS for iServices (iMessage, FaceTime, etc.), and configurations to ensure optimal functionality.

### Important Notes:
- **Generate Your Own SMBIOS**: Before proceeding, **generate your own valid SMBIOS** to ensure full functionality of iServices like iMessage, FaceTime, etc.
- **Wi-Fi Support**: This EFI uses `itlwm` (Intel Wi-Fi) for wireless connectivity. To enable Wi-Fi functionality, you'll also need to download and install [HeliPort](https://github.com/OpenIntelWireless/HeliPort).

---

## Laptop Specifications

| Component                  | Specification                        |
|----------------------------|--------------------------------------|
| **CPU**                     | Intel i5-7200U                      |
| **iGPU**                    | Intel® HD 620 Graphics               |
| **LAN**                     | Intel I219-LM                        |
| **Audio**                   | Realtek ALC256                       |
| **RAM**                     | Kingston 8 GB DDR4 2400 MHz          |
| **Wi-Fi + Bluetooth**       | DW1820 (Intel-8260NGW)               |
| **Storage**                 | SAMSUNG 128 GB NVMe                  |
| **SMBIOS**                  | MacBookPro 14,1                      |
| **Bootloader**              | OpenCore 1.0.3                       |
| **macOS Version**           | macOS Ventura 13.3                   |

---

## Creating a Bootable USB

To create a bootable USB drive for macOS, follow the official [Dortania OpenCore Installation Guide](https://dortania.github.io/OpenCore-Install-Guide/installer-guide/). This guide offers detailed, step-by-step instructions on preparing a USB installer with OpenCore, including downloading the necessary files and configuring the bootloader.

---

## BIOS Settings

Before booting macOS, you need to adjust specific BIOS settings. These configurations are essential for macOS to boot and function smoothly on your Dell Latitude 7280.

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

## (Important) BIOS Value Adjustments

This EFI does not include the necessary patches for `AppleXcpmCfgLock`, `framebuffer-fbmem`, or `framebuffer-stolenmem`. Therefore, you need to manually adjust certain BIOS settings using **modGRUBShell.efi** before installation. Follow the instructions below to set the required values:

1. **Disable CFG Lock**  
   Run the following command in modGRUBShell:  
   ```bash
   setup_var 0x4ED 0x0
   ```

2. **Set DVMT Pre-Allocated Memory to 64MB**  
   To configure DVMT pre-allocated memory, run:  
   ```bash
   setup_var 0x795 0x2
   ```

3. **Set DVMT Total Graphics Memory to Maximum**  
   To allocate maximum memory to the iGPU, run:  
   ```bash
   setup_var 0x796 0x3
   ```

These adjustments are essential for ensuring stable graphics performance and smooth booting with macOS.

---

## Troubleshooting Tips

- **Wi-Fi Issues**: If Wi-Fi isn't working after installation, make sure you have downloaded and installed [HeliPort](https://github.com/OpenIntelWireless/HeliPort) as it provides necessary tools to manage Intel Wi-Fi cards.
- **Verbose Mode**: If you're facing boot issues, add `-v` to the boot-args in OpenCore to enable verbose booting. This will help diagnose problems by displaying detailed log output.
- **BIOS Variations**: Keep in mind that different business configurations of the Latitude 7280 may vary slightly in terms of hardware, so ensure your specific system is fully compatible with the EFI provided here.
