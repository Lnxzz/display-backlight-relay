display-backlight-relay
===

A Venus OS 'plugin' to control the backlight of a HDMI display using one of the relays of a Victron GX device.

![Video](https://github.com/Lnxzz/display-backlight-relay/raw/refs/heads/main/doc/screen_on_off.mov)


*Disclaimer*

This plugin comes without any guarantees or warranties. Use it at your own risk. I only tested it on my hardware setup using a Cerbo GX.

## Background

Venus OS puts official screens to sleep by turning their backlight off: the UI is still running and printed on the screen but simply can't be seen without backlight.

To do so, the Gui writes "1" or "0" to a file which is configured in */etc/venus/blank_display_device* and */etc/venus/blank_display_device.in*.  
By default those points to */sys/class/backlight/gxdisp-2-0051/bl_power* which is a sysfs file that interacts with [Victron screen specific driver](https://github.com/victronenergy/linux/blob/venus-5.10.109/drivers/video/backlight/victron-gxdisp-bl.c#L115).

For reference, in Gui V2 [this is triggered](https://github.com/victronenergy/gui-v2/blob/main/src/screenblanker.cpp#L160) by [clicking the sleep button](https://github.com/victronenergy/gui-v2/blob/main/components/StatusBar.qml#L283) or when [the timer reaches its time out](https://github.com/victronenergy/gui-v2/blob/main/src/screenblanker.cpp#L25).

My specific HDMI display (WaveShare 7" 1024x600) has no software backlight control, it does however have a hardware switch the control the backlight. 
By connecting the first or second relay of a Cerbi GX device to the backlight switch of your HDMI display we get the possibility to control the backlight of the screen.

## Installation

Download into `/data/display-backlight-relay` on your Cerbo GX and run `install.sh`.
Use `uninstall.sh` to remove the service.

## Configuration

Edit the configuration parameters as part of the display-backlight-relay.sh script

## More information
The venos OS configuration GitHub repository from ldenisey [ldenisey/venus-os-configuration](https://github.com/ldenisey/venus-os-configuration) has been used as source.
See [https://github.com/ldenisey/venus-os-configuration/blob/main/docs/Touchscreen-Sleep.md](https://github.com/ldenisey/venus-os-configuration/blob/main/docs/Touchscreen-Sleep.md) for more information to use third party touchscreens with Victron systems.

