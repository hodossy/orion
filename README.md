# Orion

Orion is our home automation center, based on Home Assistant and ESPHome, running on Proxmox and connected with OpenWRT. I try to use only open source solution, where it is available. This place is intended to store all my configurations, and I try to document everything here, so my future self or the poor soul after me who needs to tinker with my setup can have an aid in doing so. Goal is my wife/children could do everything they need based on these [guides](./guides), please check them.

## Use Cases

### Heating

I have underfloor heating mats, for which a simple smart switch could do the trick, but I have chosen the Shelly Plus 2 PM since it has GPIO0 pin conveniently accessible for a DS18B20 temperature sensor (along with VCC and GND to power the OneWire protocol).

### Cover automation

I have jalousies (can roll up/down and tilt slats, and are outside the windows), for which a 433 MHz motor was more expensive than a normal wired motor and a smart switch, plus the later enables me to automate them as well. I use Shelly Plus 2 PMs for this as well.
