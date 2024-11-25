## Idea

I want all my common code in its own package, so if any changes are required, I can just modify it in one place. Therefore every useful bits of 'code' should be in a corresponding package.

### Packages

#### Common

Contains all ESPHome specific stuff, commonly used for all (or at least most) of my devices. Each part is in its own separate package, so they can be combined as required.

#### Shelly

Contains device specific code for Shelly devices

#### Sonoff

Contains device specific code for Sonoff devices
