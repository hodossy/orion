## Idea

I want all my common code in its own package, so if any changes are required, I can just modify it in one place. Therefore every useful bits of 'code' should be in a corresponding package.

### Packages

#### Common

Contains all ESPHome specific stuff, commonly used for all (or at least most) of my devices. Each part is in its own separate package, so they can be combined as required.

#### Devices

Contains device specific code in subfolders (Shelly, Sonoff, sensors, etc...), and complete bases for a use case with a specific device, e.g. Shelly Plus 2PM Thermostat.

### Final configurations

Every configuration file, from which a firmware is uploaded to a device, goes to the root of the folder (at least for now).
