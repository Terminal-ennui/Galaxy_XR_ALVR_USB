# Galaxy XR ALVR USB — Beta 0.1

A proof of concept for streaming Windows SteamVR content to Samsung Galaxy XR over a USB data cable. It combines a small Galaxy XR client compatibility patch with an unmodified ALVR server and Android Debug Bridge (ADB) USB forwarding.

This is **compressed USB VR streaming**, not DisplayPort input. It still uses SteamVR; it does not bypass SteamVR with a standalone Windows OpenXR runtime. No firmware downgrade, bootloader unlock, or calibration extraction is required.

## Start here

This is an early beta, not a polished installer. The basic USB display test passed on one Galaxy XR with an RTX 3090 PC. Read the signing warning before replacing an existing ALVR app.

### 1. Download the files

- [This project's releases](https://github.com/Terminal-ennui/Galaxy_XR_ALVR_USB/releases): get `Galaxy-XR-ALVR.apk` and the Beta 0.1 setup ZIP containing `Connect-USB.ps1` and instructions.
- [Matching official Windows ALVR server ZIP](https://github.com/alvr-org/ALVR-nightly/releases/download/v21.0.0-dev13%2Bnightly.2026.09.16/alvr_streamer_windows.zip). Extract it into its own folder and open `ALVR Dashboard.exe`.
- [Official ALVR nightly release page](https://github.com/alvr-org/ALVR-nightly/releases/tag/v21.0.0-dev13%2Bnightly.2026.09.16), if you need to find the download under Assets. Choose `alvr_streamer_windows.zip`, not Linux or the debug ZIP.
- [Google Android platform-tools for Windows](https://developer.android.com/tools/releases/platform-tools). Extract the `platform-tools` folder beside `Connect-USB.ps1` and the APK.

Use **our patched APK**, not `alvr_client_android.apk` from upstream's release page. The server version is `21.0.0-dev13`; the official nightly records the same upstream commit as our patch. The official server binary itself has not yet been tested here; the demonstrated unmodified server was locally built from that commit. Do not assume a different ALVR version is compatible.

You also need Steam, SteamVR, a VR-capable Windows gaming PC, the headset's battery, and a USB data cable. For high bitrate, use a USB 3 cable and PC port. A charge-only cable will not work. Other GPUs have not been verified by this project.

### 2. Enable USB debugging and install the APK

Enable Developer options and USB debugging in the headset's settings. Connect the headset's **data USB port** directly to the PC. Wear it and accept the USB debugging prompt for your own PC.

Open PowerShell in the folder containing the downloaded files. Run:

```powershell
.\platform-tools\adb.exe devices -l
.\platform-tools\adb.exe install -r .\Galaxy-XR-ALVR.apk
```

The device must show `device`, not `unauthorized` or `offline`.

**Signing warning:** Beta 0.1 is debug-signed with a temporary CI key. Android may reject installation over an APK signed by a different key. Do not blindly uninstall a working client: uninstalling deletes its app data. Save settings first if you choose to remove the old development client. Future CI builds may also require reinstalling until retained release signing is configured. Our headset test used a locally re-signed copy of the CI APK solely to update the existing app without clearing its data; the published APK retains the original CI signature.

The package is `alvr.client.dev`. If another stable ALVR app is installed, the launcher icons may look alike. This opens the correct development client:

```powershell
.\platform-tools\adb.exe shell monkey -p alvr.client.dev -c android.intent.category.LAUNCHER 1
```

### 3. Create the USB connection

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Connect-USB.ps1
```

The script finds one authorized Galaxy XR and forwards PC ports 9943 and 9944 to the headset. It does not install an APK, change image quality, or disable sleep. Read it before running it. Administrator privileges are not required; this execution-policy bypass affects only that process.

**Run it again whenever USB is disconnected or the PC, headset, or ADB restarts.**

### 4. Connect ALVR and start SteamVR

1. Open the PC ALVR dashboard and our patched headset client.
2. In the dashboard's Devices section, select the physical headset and choose **Trust**.
3. Edit its manual IP/address to **`127.0.0.1`**.
4. Select **TCP** streaming in the server connection settings.
5. Start SteamVR from ALVR. Wear the headset during startup and complete any normal permission or boundary prompts.
6. Confirm the dashboard says **Streaming** and you can see SteamVR in both eyes.

The IP shown in the headset lobby may be its Wi-Fi address. **Do not copy that address for USB.** `127.0.0.1` on the PC connects through the ADB forwards.

Use the Windows local desktop/console. Active Remote Desktop previously reproduced a green image in this setup. You can charge the external battery separately during use; the headset's data port does not charge it.

### 5. Check the picture before increasing quality

Start conservatively with HEVC, 72 Hz, 1440 × 1440 **per eye**, 60 Mbps target, SDR, and foveated encoding disabled. This is a suggested starting point, not a stability guarantee.

Adjust quality in the **PC ALVR dashboard**, one setting at a time. Codec and resolution changes may require restarting the stream. Stop if the picture is uncomfortable or badly aligned.

The visually accepted high setting was HEVC, 72 Hz, 2560 × 2560 per eye, 200 Mbps **target**, SDR, with foveated encoding disabled. The combined encoded stereo frame is 5120 × 2560; do not enter that as a per-eye size. Actual sustained bitrate, long-duration gaming, and 500 Mbps have not been established.

## Troubleshooting

| Symptom | What to try |
| --- | --- |
| Waiting for streamer / asks to Trust | Open the PC dashboard, trust the physical headset, rerun the USB script, and check `127.0.0.1` plus TCP. |
| No headset found | Use a known data cable/direct PC port, turn the headset on, and accept USB debugging. `unauthorized` needs approval; `offline` means it is not ready. |
| Starting headset / black screen | Wear it normally with the sensor uncovered, check system prompts, and reopen the client. A normal reboot resolved this stall during our test; rerun the USB script afterward. |
| Green picture | Leave the active Windows Remote Desktop session and use the local PC console. |
| Disconnects after removal | Put the headset back on, reopen the client if needed, and rerun USB forwarding if it was lost. |
| Jitter / decoder errors | Restore the last working setting and lower bitrate or resolution separately. |

## Known limitations and test evidence

- GitHub Actions built Beta 0.1 from project commit `183a5960adefe4a598a201fe7e7b89d25849e66c`, with upstream ALVR commit `ca2decae968f2fd37b43b777cca4ba597808ba52`.
- Automated compilation, patch application, APK signature verification, path-remapping scan, and checksum checks passed. The downloaded artifact's checksum was verified locally.
- The CI-built client, re-signed locally without rebuilding its code, connected over USB and displayed SteamVR correctly in both eyes after a headset reboot. This is a basic visual check, not a sustained game benchmark.
- Off-head operation is **not reliable**. Stay-awake while powered and covering the sensor did not prevent sleep in the active-stream test. It slept after roughly 80 seconds with reason `xr_doff`; eye detection has not been confirmed as the cause.
- Controller/input completeness, other PC hardware, and an APK install with the original CI signing key have not been validated here.

## Building and reporting issues

See [ACTIONS.txt](ACTIONS.txt) for GitHub build/artifact instructions, [SETUP.txt](SETUP.txt) for source build steps, and [BUILD-PRIVACY.txt](BUILD-PRIVACY.txt) for binary privacy/signing checks. Artifacts require GitHub sign-in and expire after 14 days; release downloads are separate.

[Report a problem](https://github.com/Terminal-ennui/Galaxy_XR_ALVR_USB/issues) with client/server versions, GPU and driver, codec, Hz, per-eye resolution, target Mbps, reproduction steps, and whether the headset was worn. Review logs before posting: remove usernames, device names, serials, IP addresses, local paths, and credentials.

## License and upstream credit

The source patch is [MIT licensed](LICENSE), with upstream copyright notices preserved. This project builds on [ALVR](https://github.com/alvr-org/ALVR). The APK also contains third-party components, including the generic Khronos OpenXR loader; their licenses remain applicable. This is an independent proof of concept, not an official Samsung or Valve product.
