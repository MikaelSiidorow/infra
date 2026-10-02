# Home Network Setup

OpenWrt build for a one-bedroom flat in Helsinki. DNA taloyhtiö ethernet, 600 Mbps, DHCP, no ONT or modem.

## Hardware

| Device                    | Chip / target           | Flash / RAM          | Role                               | Final location        |
| ------------------------- | ----------------------- | -------------------- | ---------------------------------- | --------------------- |
| Netgear R6220             | MT7621, `ramips/mt7621` | 128 MB NAND / 128 MB | Router, radios off                 | Hallway jakamo        |
| TP-Link Archer C6 v2 (EU) | QCA9563, `ath79`        | **8 MB** / 128 MB    | Dumb AP + switch                   | Living room, TV stand |
| Netgear EX6120            | —                       | —                    | Unused spare                       | Drawer                |
| Mini PC                   | —                       | —                    | Home server, Home Assistant, media | TV stand              |

OpenWrt version: **25.12.5** (current stable, released 2026-06-29).
Note: 25.12 replaced `opkg` with **`apk`**. Package commands are `apk add <pkg>`, not `opkg install`.

## Target topology

```
Building feed
    |
  [R6220]  hallway jakamo — routing, DHCP, DNS, firewall, AdGuard
    |-- MH DATA --> desktop PC (bedroom)
    |-- OH DATA --> spare, unused
    |-- raceway  --> [Archer C6] living room
                        |-- mini PC
                        |-- TV
                        |-- Chromecast
                        |-- spare x2
```

Subnet `192.168.1.0/24` — R6220 `192.168.1.1`, Archer `192.168.1.2`

---

# Step 0 — Right now: fill the USB stick

Do all of this on the good laptop. The old Pop!\_OS laptop has no working package manager and should never touch the internet for this.

## Downloads

Use the **OpenWrt Firmware Selector** rather than guessing filenames — it gives the exact image plus its SHA256:

<https://firmware-selector.openwrt.org>

Search each device, select version 25.12.5, download the **factory** image (not sysupgrade — sysupgrade is for devices already running OpenWrt and flashing it from stock will brick them).

1. **Netgear R6220** → `...ramips-mt7621-netgear_r6220-squashfs-factory.img`
2. **TP-Link Archer C6 v2** → `...ath79-generic-tplink_archer-c6-v2-squashfs-factory.bin`

Also grab from the device pages, and note the SHA256 sums file for each target directory.

## Stock firmware (for reverting)

3. **Netgear R6220** stock firmware from netgear.com support.
4. **Archer C6 v2 (EU)** stock firmware from tp-link.com. Take the **oldest** version offered, not the newest — newer stock images sometimes refuse to flash back over OpenWrt.

## Tools

5. **tftpd64** (if the old laptop is Windows) — the Pop!\_OS laptop likely has `tftpd-hpa` or can use `atftpd`, but may not be installable without working apt. Check before relying on it; if apt is dead, a Windows machine or a live USB is the fallback for TFTP recovery.

## Verify and copy

```bash
# In the download directory
sha256sum -c sha256sums --ignore-missing
```

Format the stick FAT32 if the old laptop might not mount exFAT. Images are 10–30 MB.

```bash
# Example — adjust device node, check with lsblk first
sudo mkfs.vfat -F 32 -n OPENWRT /dev/sdX1
```

Copy all four firmware files plus the sums files. Copy this document too.

---

# Step 1 — Bench setup

Everything on the floor with live WAN. Nothing mounted, nothing in the raceway yet.

- Photograph the jakamo before unplugging anything.
- Patch OH DATA through in the jakamo so the wall jack carries the building feed.
- Cable from OH wall jack → R6220 WAN port.
- Old laptop → R6220 LAN port.
- Archer alongside, to be flashed second.
- Phone hotspot on standby for reading recovery docs.

---

# Step 2 — Flash the R6220

1. Power on, connect to `routerlogin.net` or `192.168.1.1`, log in to stock firmware.
2. Advanced → Administration → Firmware Update → upload the `.img` factory image.
3. Wait for reboot, ~3 minutes. Do not power cycle.
4. Reach LuCI at `192.168.1.1`. No password by default — set one immediately.

**Recovery if it fails:** nmrpflash, or TFTP with the laptop on static `192.168.1.10` pushing to `192.168.1.1`.

## Configure

5. **Flow offloading** — Network → Firewall → Routing/NAT Offloading. Enable **software** and **hardware**. Without this MT7621 caps near 300 Mbps and you lose half your line.
6. WAN interface: DHCP client. No credentials needed for DNA.
   - Dead WAN after the hardware swap = MAC binding. Unplug WAN 15 min, or set `option macaddr` on the wan device to the previous router's MAC.
7. **Do not install wireless packages.** Radios stay off — the jakamo is a metal box behind a mirror door, effectively a Faraday cage. Leaving out `wpad`/`hostapd` saves space and removes attack surface.
8. Speed test. Should be near 600 Mbps before proceeding.

---

# Step 3 — Flash the Archer C6 v2

Try the web UI first:

1. Advanced → System Tools → Firmware Upgrade → upload the `.bin` factory image.

**If it rejects the file as "Invalid file type"** — common on this model — use TFTP recovery:

2. Set the laptop's ethernet to static **`192.168.0.66`**, mask `255.255.255.0`, no gateway.
3. **Force the NIC to 100 Mbps full duplex, auto-negotiation off.** This fixes most cases where the router never requests the file.
4. Disable the laptop firewall temporarily. Unplug the WAN cable from the router.
5. Rename the factory image to **`ArcherC6v2_tp_recovery.bin`**, place it in the TFTP server root, start the server.
6. Connect laptop to a **LAN** port. Hold reset, apply power, keep holding until the WPS LED lights.
7. Wait ~150 seconds. Do not interrupt.

**No UART header on this board** — serial recovery means soldering. TFTP is the only practical safety net, so get steps 2–4 right.

## Configure as dumb AP

8. Reach LuCI, set root password.
9. LAN interface: static `192.168.1.2`, gateway `192.168.1.1`, DNS `192.168.1.1`.
10. **Disable DHCP server** — tick "Ignore interface" under the LAN DHCP settings.
11. Add the WAN port to the `br-lan` bridge for a 5th usable port.
12. WiFi: one SSID across both bands, WPA2. Radios enabled.
13. Connect **LAN → LAN** to the R6220. Never WAN.

## 8 MB flash constraints

- Install nothing optional here. No statistics, no VPN, no AdGuard — all of that lives on the R6220.
- WPA3 needs `wpad-openssl` with force flags and is a real squeeze at 8 MB. WPA2 is fine for a home LAN; skip it.

---

# Step 4 — Verify before relocating

- A client on the Archer's WiFi gets a `192.168.1.x` lease from the R6220.
- Speed test over WiFi and over a wired Archer port.
- Only then move hardware to the jakamo and TV stand. No config depends on physical position.

---

# Step 5 — Services

- **AdGuard Home** on the R6220: `apk add adguardhome`. The 128 MB NAND has room. Point DHCP-advertised DNS at it.
- **Mini PC**: Debian/Ubuntu base (or Proxmox), Home Assistant in Docker, Jellyfin or Plex, Kodi as the TV frontend. HDMI direct to the TV. Zigbee dongle on a short USB extension to avoid USB3 interference.

---

# Step 6 — Later, optional

- **VLANs** for IoT and guest: defined on the R6220, tagged trunk to the Archer, bridged to separate SSIDs. Only after flat networking works end to end. Debugging routing and VLAN tagging at the same time is how people give up.
- **802.11r**: not needed. Single AP, nothing to roam between.
- **Second AP** only if MH coverage fails. Options: EX6120 on MH DATA (needs a switch since the desktop uses that jack; its 100 Mbps port caps clients at ~95 Mbps), or re-enable the R6220 radios.

---

# Notes

- Heat: check R6220 case temperature after a day in the closed cabinet. Thermal throttling in a sealed box is a real failure mode. Vent holes or door ajar if needed.
- Archer placement: wall-mount behind the TV. A closed drawer full of metal chassis and coiled cables is a poor RF environment even in a wooden stand.
- SQM/QoS is incompatible with flow offloading. At 600 Mbps on fibre, skip SQM.
- Hardware offloading disables per-device traffic accounting. Trade-off accepted.
- Budget three hours for the first session. Most of it is reading and waiting on reboots.

# Open items

- Hirschmann AFC 1041 S: trace which coax cables are actually connected and whether the input is live. Test with a temporary cable and a channel scan **before** building the raceway.
- Measure the raceway route (jakamo → above ET door → down to TV) to size the coax and mains extension, and check whether the 10 m Cat cable reaches.
- Coax needed: F-male (jakamo end) to IEC-male (TV end), 10–15 m, not the 5 m listing.
