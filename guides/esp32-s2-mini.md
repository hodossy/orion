# Wenmos ESP32-S2 Mini chip info

## Flashing ESPHome or WLED

#### Requirements

A single USB-C cable is enough

#### Install ESPHome

For some reason the web installer is not working for this one, even if the initial flash succeeds, the device is not available, and is not connecting to the WiFi network. Thus manual flashing is required, that is the only way I was able to make it work.

1. Make sure `esptool` is available [Install guide](https://docs.espressif.com/projects/esptool/en/latest/esp32/installation.html)
2. Create a factory firmware binary in ESPHome Builder in Home Assistant
3. Press the boot button and hold
4. Connect the device to an USB port
5. Wait a bit, then press the reset button for a brief second and release it
6. While still holding the boot button, run `esptool write-flash -e 0x00000 <path-to-factory-bin>`

#### Install WLED

WLED requires a custom bootloader and partition map to be flashed. The bootloader can be found [here](https://github.com/wled/WLED/releases/tag/v0.15.0-b2).

The procedure is generally the same, but each file has to be written at different offsets

```
esptool write-flash -e 0x01000 <path-to-bootloader> 0x08000 <path-to-partition-map> 0x10000 <path-to-wled>
```

### Useful links

[Wemos S2 documentation](https://www.wemos.cc/en/latest/tutorials/s2/get_started_with_arduino_s2.html#upload-code)
[ESP32 and ESPHome upload community thread](https://community.home-assistant.io/t/esp32-s2-and-esphome-upload/382885)
