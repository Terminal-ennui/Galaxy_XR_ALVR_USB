# Galaxy XR ALVR USB — Beta 0.1, stable baseline

Stream Windows SteamVR content to Samsung Galaxy XR over a USB 3 data cable using a small client compatibility patch and the **official, unmodified ALVR stable 20.14.1 server**.

This is compressed VR streaming, not DisplayPort input. SteamVR is still required. No firmware modification, bootloader unlock, or calibration extraction is needed.

## Start here

### 1. Download the matching files

- [Stable-baseline APK builds](https://github.com/Terminal-ennui/Galaxy_XR_ALVR_USB/actions/workflows/build-apk.yml): select a successful run for this stable-baseline PR/branch and download its artifact. Extract `Galaxy-XR-ALVR.apk`. Check `BUILD-INFO.txt` says ALVR **20.14.1**. Older artifacts and the original Beta 0.1 release use a different version; do not mix them.
- [Official ALVR stable 20.14.1 Windows server ZIP](https://github.com/alvr-org/ALVR/releases/download/v20.14.1/alvr_streamer_windows.zip). Extract it into its own folder.
- [Official stable release page](https://github.com/alvr-org/ALVR/releases/tag/v20.14.1): choose `alvr_streamer_windows.zip`, not Linux or a debug ZIP. Use **our patched headset APK**, not the upstream Android APK.
- [Google Android platform-tools](https://developer.android.com/tools/releases/platform-tools): download the Windows version and extract `platform-tools` beside the APK and `Connect-USB.ps1`.

The PC needs Steam, SteamVR, and a VR-capable GPU. Use a **USB 3 data cable connected directly to a USB 3 PC port**, and the headset's data port. You can charge the external battery separately.

### 2. Install the headset client

Enable Developer options and USB debugging on Galaxy XR. Connect the cable, wear the headset, and accept the debugging prompt for your own PC.

Open PowerShell in the downloaded files folder:

```powershell
.\platform-tools\adb.exe devices -l
.\platform-tools\adb.exe install -r .\Galaxy-XR-ALVR.apk
```

The headset must show `device`, not `unauthorized` or `offline`.

The launcher name is **ALVR Stable Test**, package `alvr.client.stabletest`. It is separate from the old nightly client and the official stable client. Open the correct one with:

```powershell
.\platform-tools\adb.exe shell monkey -p alvr.client.stabletest -c android.intent.category.LAUNCHER 1
```

**Signing warning:** CI uses a temporary debug key. A new build usually cannot update a copy signed with a different key. Do not uninstall a working client without saving its settings; uninstalling deletes app data. Retained release signing is not configured. The newly generated CI package still needs its own headset acceptance test.

### 3. Set up USB forwarding

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Connect-USB.ps1
```

This script creates the two required ADB forwards. It does not install the APK, change quality, or prevent sleep. Administrator privileges are not required. The execution-policy bypass applies only to that process.

**Run it again after unplugging USB or restarting the PC, headset, or ADB.**

### 4. Connect to the PC

1. Open `ALVR Dashboard.exe` from the **20.14.1** server folder, and open **ALVR Stable Test** on the headset.
2. In the PC dashboard, add/trust the physical headset. Set its manual IP/address to **`127.0.0.1`**. If discovery doesn't show it, use **Add device manually**, give it a name, and enter that address.
3. Select **TCP** in ALVR's connection settings.
4. Start SteamVR from ALVR. Keep the headset on and complete normal permission/boundary prompts.
5. Confirm ALVR says **Streaming** and SteamVR is visible in both eyes.

The IP shown inside the headset may be a Wi-Fi address. **Do not use that address for this USB setup.** On the PC, `127.0.0.1` reaches the headset through ADB forwarding.

Use the Windows local desktop/console, not an active Windows Remote Desktop session.

### 5. Start conservatively

Set quality in the **PC ALVR dashboard**. Start with HEVC, **72 Hz**, 1440 × 1440 per eye, 60 Mbps target, **8-bit SDR**, HDR off, and both foveated encoding and client-side foveation disabled. Increase one setting at a time.

### Important: re-enable ALVR after a SteamVR crash

**If SteamVR crashes on the first run or while testing quality settings, it may disable the ALVR add-on.** On the next launch, a pop-up may report a blocked/disabled add-on and ask you to re-enable it. This does not necessarily mean you need to reinstall ALVR.

In SteamVR, open **Settings > Startup/Shutdown > Manage Add-ons** and enable **ALVR** again, then restart SteamVR. Menu wording can vary by SteamVR version.

Alternatively, **close SteamVR completely** and run the included helper from the downloaded files folder:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\ALVR-Unblock.ps1
```

Then open the PC ALVR dashboard and start SteamVR again. The helper backs up SteamVR settings and clears only ALVR's safe-mode block; it does not change quality settings or fix the original crash. If a new quality setting caused the crash, restore your last working setting before retrying. SteamVR may block the add-on again if it crashes again.

## Recommended upper setting for the tested RTX 3090 rig

| Setting | Value |
| --- | --- |
| Server | Official ALVR stable 20.14.1 |
| Connection | USB 3, ADB forwarding, TCP |
| Codec | HEVC / H.265 |
| Refresh target | 72 Hz |
| Resolution | 2560 × 2560 **per eye** |
| Bitrate mode / target | Constant, **375 Mbps** |
| Color | 8-bit SDR; HDR off |
| Foveated encoding / client-side foveation | Both off |

The combined stereo frame is 5120 × 2560; **do not enter that as the per-eye resolution**.

This is a personal, visually smooth upper setting for an **i7-11700K / RTX 3090**, NVIDIA driver **595.71**, not a universal default. For more margin, start at 200 Mbps and work upward. Other GPUs and demanding games may need lower settings.

### 60-second benchmark

A full 60-second SteamVR-scene capture on that rig completed without an event-stream interruption:

| Measurement | Result |
| --- | --- |
| Actual video bitrate | 315 Mbps average; sampled intervals 286–348 Mbps |
| Reported packet-loss counter increase | **0** |
| Server / reported client FPS | 71.6 / 63.6 average |
| ALVR pipeline latency | 113 ms average; 127 ms p95 |
| GPU / hardware encoder utilization | 18% / 81% average |
| GPU temperature / power | 58°C / 184 W average |

GPU telemetry includes 60 samples spanning approximately 62 seconds and covering the stream capture. The owner reported the picture as smooth before the run. Client FPS telemetry nevertheless dipped as low as 24. **This is not a locked-72-FPS guarantee, a sustained-375-Mbps measurement, or a demanding-game endurance benchmark.** ALVR latency is estimated, not externally measured motion-to-photon latency. Zero reported packet loss does not mean zero dropped or repeated display frames.

### Wi-Fi comparison: 6 GHz (Wi-Fi 7 reported)

A separate 60-second Wi-Fi capture used the same 375 Mbps target, HEVC 8-bit, 72 Hz, per-eye resolution, foveation settings, and TCP protocol. The owner reported it as very smooth. USB stream forwarding was removed; the cable remained connected only for ADB telemetry.

The headset reported **5975 MHz (6 GHz)** and Wi-Fi standard **8 / 802.11be (Wi-Fi 7)** with MLO immediately after the tests. This is the 6 GHz band also used by Wi-Fi 6E, but **this run is not a verified Wi-Fi 6E / 802.11ax benchmark**. Android's standard identifiers are documented in [ScanResult](https://developer.android.com/reference/android/net/wifi/ScanResult#WIFI_STANDARD_11BE).

| Measurement | Earlier USB capture | Wi-Fi capture |
| --- | --- | --- |
| Actual video bitrate, average | 315 Mbps | 317 Mbps |
| Reported packet-loss counter increase | **0** | **0** |
| Server / reported client FPS, average | 71.6 / 63.6 | 71.4 / 63.9 |
| ALVR pipeline latency, average / p95 | 113 / 127 ms | 124 / 128 ms |
| Encoding / decoding latency, average | 13.3 / 55.5 ms | 13.4 / 55.4 ms |
| GPU / hardware encoder utilization, average | 18% / 81% | 19% / 81% |

The Wi-Fi capture completed without an event-stream interruption, with 120 statistics summaries and 60 GPU samples. Its reported client FPS ranged from 23 to 72. A subsequent **450 Mbps target produced visible jitter**, so the target was returned to **375 Mbps**.

At these settings, Wi-Fi delivered similar actual bitrate and reported frame rates; **these results do not demonstrate a USB advantage**. These were separate short scene captures, not a controlled replay or endurance comparison. The USB run used the earlier local stable client; Wi-Fi used the CI-built stable APK. The latency difference cannot be attributed solely to transport. Both used TCP: zero ALVR-reported loss does not establish zero wireless loss or TCP retransmissions.

## Troubleshooting

| Symptom | What to try |
| --- | --- |
| Waiting for PC / Trust / connection timeout | Check the matching 20.14.1 server, open the correct headset app, rerun USB forwarding, and verify trusted manual address `127.0.0.1` with TCP. |
| No headset found | Wake it, accept debugging, and use a known USB 3 data cable/direct port. |
| Black screen / Starting headset | Wear it normally, check prompts, and reopen the client. Reboot normally if needed, then recreate USB forwarding. |
| Green picture | Leave the active Windows Remote Desktop session and use the local console. |
| Jitter after changing codec/quality or resuming | Restore the last good setting. Exit the headset client, SteamVR, and the PC ALVR dashboard; reopen all three and recreate USB forwarding. Restarting only one component may not clear it. If it persists, reduce bitrate. |
| Pop-up reports ALVR blocked/disabled after a crash | [Re-enable ALVR or run `ALVR-Unblock.ps1`](#important-re-enable-alvr-after-a-steamvr-crash). Restore the last working quality setting if needed. |

## Builds and limitations

CI pins upstream stable commit `a9f6542fa507a841f40ab4f3fcb531427cd02550`, applies the minimal Galaxy XR patch, builds the APK, checks its signature, scans for embedded builder paths, and supplies a checksum and build provenance.

The stable patch adds Android XR runtime/Full Space declarations, a separate launcher package, a 72 Hz capability fallback, and a smaller lobby swapchain. It retains stable upstream decoding and does **not** modify the Windows server.

Local stable-client tests passed several headset removal/resume cycles. The CI-built stable APK was subsequently installed and reported visually smooth over USB and Wi-Fi. Sleep/resume and connection timeouts can still occur; off-head keep-awake is not guaranteed. Compilation alone is not hardware acceptance. No AV1, 10-bit, HDR, or 90 Hz support is claimed by this build.

See [ACTIONS.txt](ACTIONS.txt), [SETUP.txt](SETUP.txt), and [BUILD-PRIVACY.txt](BUILD-PRIVACY.txt). CI artifact downloads require GitHub sign-in and expire after 14 days. Release publication is separate.

[Report a problem](https://github.com/Terminal-ennui/Galaxy_XR_ALVR_USB/issues) with versions, GPU/driver, codec, Hz, per-eye size, target Mbps, and reproduction steps. Review logs before posting; remove personal names, serials, network addresses, paths, and credentials.

## License and credit

The source patch is [MIT licensed](LICENSE), with upstream notices preserved. This project builds on [ALVR](https://github.com/alvr-org/ALVR) and packages the generic Khronos OpenXR loader. Third-party licenses remain applicable. This is independent of Samsung and Valve.
