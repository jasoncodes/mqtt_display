# `mqtt_display`

A little Swift app for macOS which lets you sleep and wake your Mac's display over MQTT.

## Installation

```shell
make install MQTT_URL=mqtt://…
```

This will compile the binary, install it into `~/.local/bin`, and create a launch agent to run at login.

URLs such as `mqtts://foo:bar@example.com` for TLS MQTT and `wss://foo:bar@example.com/mqtt` for WebSockets over HTTPS are supported.

## Example Home Assistant switch configuration

```yaml
mqtt:
  switch:
    - name: MacBook display
      icon: mdi:laptop
      command_topic: mymacbook/display/set
      payload_on: "on"
      payload_off: "off"
      state_topic: mymacbook/display
      state_on: "on"
      state_off: "off"
      availability_topic: mymacbook/display/available
      payload_available: "online"
      payload_not_available: "offline"
```
