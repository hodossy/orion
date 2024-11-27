# Orion

Orion is our home automation center, based on Home Assistant and ESPHome. I try to use only open source solution, where it is available. Current use cases I try to solve to the best of my knowledge

### Heating

I have underfloor heating mats, for which a simple smart switch could do the trick, but I have chosen the Shelly Plus 2 PM since it has GPIO0 pin conveniently accessible for a DS18B20 temperature sensor (along with VCC and GND).

### Cover automation

I have jalousies (can roll up/down and tilt slats, and are outside the windows), for which a 433 MHz motor was more expensive than a normal wired motor and a smart switch, plus the later enables me to automate them as well. I use Shelly Plus 2 PMs for this as well.
