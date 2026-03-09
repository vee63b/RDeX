# RDeX

**RDeX (RedMagic Desktop eXperience)** is my attempt at a lightweight **XFCE desktop environment for Termux** designed to run natively on Android without proot or chroot.

RDeX transforms a RedMagic device into a **desktop host environment** when connected to an external display, or can even  work directly on the phone screen.

The project builds on the Termux ecosystem and integrates development tools, network services, Android storage access, and desktop utilities into a deterministic provisioning system.

---

# Core Components

RDeX is built around the following Termux ecosystem tools:

- **Termux** – Linux userspace environment
- **Termux:X11** – X server used to display the desktop
- **Termux:Widget** – optional launcher integration

These components work together to provide a **native desktop experience on Android**.

RDeX does **not use**:

- proot
- chroot
- containers

Everything runs directly inside the **Termux userspace**.

---

# Designed for RedMagic Devices

RDeX is specifically designed for **RedMagic phones** to take advantage of **Console Mode (Host Mode)**.

This allows the device to behave like a small desktop computer when connected to:

- external monitors
- TVs
- wireless casting displays
- USB-C display outputs

When connected to an external display, the phone acts as the **desktop host**, displaying the desktop on the external display and keeping your device usable as your mobile phone.

---

# Display Modes

Due to the nature of RedMagic devices, RDeX supports several display configurations.

---

## Mode 1 – On-Device Desktop

Run the desktop directly on the phone screen.

Requirements:

- Termux
- Termux:X11

Workflow:

1. Start **Termux:X11**
2. Open **Termux**
3. Run:

```
rdex
```

Features:

- full keyboard support
- full mouse support

---

## Mode 2 – Mirrored Display

Mirror the phone screen to a TV or monitor.

Requirements:

- Termux
- Termux:X11
- screen casting in mirror mode (Connect SmartCast and simply don't switch your device into Game Space mode) or USB-C output

The desktop runs on the device while the external display mirrors it.

Features:

- full keyboard support
- full mouse support

---

## Mode 3 – RedMagic Console Mode (Recommended)

RedMagic devices support **Console Mode**, which turns the phone into a desktop host.

Requirements:

- Termux
- Termux:X11
- external display
- keyboard and mouse

## Entering RedMagic Console Mode

---

### Method 1 — SmartCast Extended Mode

This method works on most displays but may result in incorrect resolution.

Steps:

1. Open **SmartCast**
2. Connect to an external display
3. Launch **Termux:X11**
4. Tap the **SmartCast floating icon**
5. Select **Extended Mode**

Behavior:

- The phone detaches into a **touchpad for the external screen**
- The phone can still be used normally

Limitations:

- The external display may run at an **incorrect resolution**
- Some displays show **banding** because most RedMagic devices use **ultrawide aspect ratios**

---

### Method 2 — Game Space Console Mode (Recommended)

This is the preferred method for RDeX.

Steps:

1. Open **SmartCast**
2. Connect to an external display
3. Flip the **Game Space switch** on the device
4. The device automatically enters **Console Mode**
5. Launch **Termux:X11** from the Console launcher
6. Start the desktop on your device using either the Termux rdex command, or Termux:widget 

Input behavior in Console Mode:

| Device | Behavior |
|------|------|
| Mouse | right-click not available |
| Keyboard | Super / Meta key unavailable |

I've baked in 2 alternate mappings to right click:

```
CTRL + .
ALT + .
```

These both function as right-click wherever your mouse cursor is at.

---

# Installation

## Prerequisites

Install the following applications:

- Termux
- Termux:X11
- Termux:Widget (recommended)

I shouldn't need to say this, but avoid the Play Store version of Termux unless you want Scoped Storage issues. Use F-Droid or GitHub version, no mixing and matching. Either all 3 from F-Droid, or all 3 from GitHub

---

## Repository Location

The **RDeX directory must exist at the root of internal storage** so the scripts can locate required assets.

Example location:

```
/storage/emulated/0/RDeX
```

This is accessed inside Termux as:

```
~/storage/shared/RDeX
```

---

## Install RDeX

Inside Termux:

```
termux-setup-storage
pkg install git
cd ~/storage/shared
git clone https://github.com/vee63b/RDeX.git
cd RDeX
bash initial_bootstrap.sh
```

The bootstrap script prepares the Termux environment and, optionally, installs the desktop. There are a few prompts during installation, so please keep an eye on it.

---

# Installation Pipeline

RDeX uses a **two-stage provisioning system**.

```
initial_bootstrap.sh
        ↓
install_RDeX.sh
        ↓
launch_rdex.sh
```

---

## Stage 1 – Bootstrap

`initial_bootstrap.sh`

This prepares the Termux environment.

Tasks performed:

- repository configuration
- package installation
- SSH setup
- Samba file sharing
- optional code-server
- Android storage integration
- shortcut deployment
- alias configuration

It also installs:

```
Termai CLI AI assistant
```

---

## Stage 2 – Desktop Provisioning

`install_RDeX.sh`

This installs the runtime desktop environment:

- XFCE
- Termux:X11 integration
- pulseaudio
- browsers
- system utilities

---

# Deterministic Desktop Restore

RDeX restores a **preconfigured XFCE desktop snapshot** instead of scripting configuration.

Location:

```
assets/base_state/rdex-base.zip
```

During provisioning the script:

1. stops XFCE processes
2. clears runtime cache
3. removes existing configuration
4. restores the base desktop state
5. fixes permissions
6. rebuilds the desktop database

This ensures **identical desktop configuration across installs**.

---

# Launching the Desktop

Start the desktop with:

```bash
rdex
```

The launcher script:

```
~/.shortcuts/launch_rdex.sh
```

This script:

- attempts to starts Termux:X11, if it doesn't you'll have to manually open x11
- initializes pulseaudio
- optionally launches code-serverif you opted to install it
- starts XFCE
- monitors the session
- performs cleanup when the session ends

---

# Termux Widget Integration

RDeX installs scripts to:

```
~/.shortcuts
```

This directory is used by **Termux:Widget**.

This allows launching RDeX directly from the Android home screen without opening Termux; you simply need to add a termux:widget shortcut on your home screen, selecting one of the existing shortcuts.

---

# Available Commands

After installation, the following commands are available after refreshing or restarting Termux:

```
rdex           -> Launch RDeX desktop
config-recap   -> Show connection & service status
start-smb      -> Start Samba server
stop-smb       -> Stop Samba server
sdcard         -> Open shared storage
shortcuts      -> Open shortcut directory
ai             -> Invoke CLI AI assistant
```

---

# Management Tools

RDeX includes several desktop utilities.

### SMB Server Control

Start / stop Samba:

```
start-smb
stop-smb
```

or use the terminal interface:

```
~/.shortcuts/smb_tui.sh
```

---

### Status Dashboard

```
config-recap
```

Displays:

- SSH connection command
- SMB address
- code-server URL
- service status

---

### Application Generator

Tool:

```
url_to_app.sh
```

Creates XFCE launchers for:

- web apps
- Android applications
- custom scripts

Applications appear in the XFCE menu.

---

# Project Structure

```
RDeX
├── assets
│   └── base_state
│       └── rdex-base.zip
├── initial_bootstrap.sh
├── install_RDeX.sh
├── shortcuts
│   ├── Start-SMB.sh
│   ├── Stop-SMB.sh
│   ├── launch_rdex.sh
│   ├── smb_tui.py
│   ├── smb_tui.sh
│   ├── status.sh
│   └── url_to_app.sh
└── smb.conf
```

---

It's currently 3 AM and I feel like I am making typos in this readme, so I'll call it a night and update this later with images as well as try to condense it to not be so convoluted.

# License

GPL-3.0
