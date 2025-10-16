# Hardware setup

I have a Beelink S12 as my Proxmox host, on which there are several VMs / LXC containers: HA OS, Mosquito MQTT, PostgreSQL (HA DB) and others. I also have a router for the IoT network on 2.4 GHz WiFi, and an other one for my regular and Guest network. I made sure that the two 2.4 GHz networks are using non-overlapping channels in order to avoid interference.

TODO: proxmox guide

# Network setup

TODO

# Project Structure

There are guides in the `guides` folder, and everything else is in the `src` folder. Under `src` there is a subfolder for each subdomain, like ESPHome, Home Assistant, etc. Each domain must have a `scripts` folder, and that contains the life cycle of that domain. The `backup.sh` is responsible for creating the backups before updating, while `deploy.sh` should deal with first installation and later updates. I would like everything to be configuration driven from a git repo, so it is easy to move my system from one place to another. In case of a hardware failure, I should be able to quickly recover at least my configuration.
