# Zigbee Light Multifunction (Sage)

A fork of Mariano Colmenarejo's
[Zigbee Light Multifunction Mc](https://github.com/Mariano-Github/Edge-Drivers-Beta/tree/main/zigbee-light-multifunction-v6),
version 6. Supported devices are listed in [fingerprints.yml](fingerprints.yml).

## Sage changes

### 2026-11-23

- **Circadian follows the seasons.** Color now runs from dawn to dusk (the end of
  twilight, sun 6° below the horizon) for the day of the year, coolest at midday and warmest
  outside that window. The new **Circadian Location** setting picks a latitude band; it
  defaults to Northern (New York, Tokyo, Rome). The Circadian Period Start and End settings
  are gone.
- Midday is taken as 12:00 standard time, so during daylight saving the coolest point is at
  1 PM on the clock. Dawn and dusk can be up to about 16 minutes off from the real sky, more
  if you live far from your time zone's center.

### 2026-11-17

- **Circadian changes color only.** It no longer touches brightness. It starts when the
  light turns on, including from a switch bound to the bulb's Zigbee group, and follows the
  time of day every 5 minutes. It ends when the light turns off or when you set a color,
  until the next turn-on. Outside the circadian hours the light holds the warmest color.
- **Circadian brightness settings removed.** Circadian MIN/MAX Level and the night setting
  no longer did anything.
- **New defaults.** Color temperature 2700–5500K (or the bulb's ceiling), used as limits on
  color commands. Circadian period 6:00–20:00 (replaced by dawn to dusk on 2026-11-23). Transition times 1 second; 0 means the
  bulb's own speed.
- **Local time.** "Local Time Offset" is replaced by **UTC Offset (hours)**, −23 to +23,
  and **Auto-adjust for US daylight saving**. The hub clock runs on UTC, so set the offset
  to your standard time (−8 for US Pacific) and turn daylight saving on where clocks
  change. Arizona and Hawaii leave it off.
- **Settings screen.** Settings are grouped under headings, and the first line shows the
  build date and commit.

### Switching a bulb from Mariano's driver

- Settings you saved under his driver keep their values, so new defaults don't apply to
  them. Check the fade times and color limits after switching.
- The old time offset doesn't carry over. Set UTC Offset again.

The release notes below are Mariano's, from the original driver.

## Added new to control all paired devices directly from the driver with custom groups. 

- You can see how works all new mirror groups funtions in this smartthings community post:

 https://community.smartthings.com/t/edge-driver-mc-zigbee-light-multifunction-mc/234387/763?u=mariano_colmenarejo

## (NEW RELEASE) Version 6.0 of the Edge Driver Zigbee Light Multifunction Mc

## Changes and Improvements:

1.	At the request of Milan I have added more modes of continuous color change, using 2 contiguous colors or with a unique color, blue or green.
NOTE: All color change modes are executed in the driver and are not programmed in the device, therefore continuous use or in more than one device at the same time can condition the operation of the hub and the network, since with the frequency of the chosen timer commands are executed, sent and received continuously.

2.	Added capability for information of the signal metric as in the last jump. In default history you don't see the events. In preferences you can enable visibility if you want to perform a troublesooting of the device signal.

3.	Added preference for ATTEMPT Restore State if Power Lost, using the cluster 0x0006 and the attributes 0x4003 (zigbee standard) and 0x8002 (Tuya). I don't know of any bulb that works with this, but in the switch-level profile there are dimmers that could work. If I manage to discover or know by someone the clusters and attributes used by some manufacturer I will add it

4.	Added a non-visible capability, DriverVersion, which will warn in the event history once a day or when running an InfoChanged lifecycle that a new version of the driver is available that needs to be updated manually. It will be activated only when the driver is renamed (-OLD).


## (NEW RELEASE) Version 5.0 of the Edge Driver Zigbee Light Multifunction Mc

 ## Changes and Improvements:

1- I have merged in this Driver the three existing similar Drivers:

- Zigbee Light Multifunction Mc

- Zigbee Light Multifunction and Tr-Time

- Zigbee Light Multifunction Group Mc

2- Transition Time functions for Off-On-Off, Level, Color temperature and Color changes are adjustable from preferences with times from 0 sec to 10 sec.

-Not all zigbee light bulbs work with the Transition Time Argument. If it does not work properly or you want to use the default values of the hardware and platform, you just have to put the values = 0 sec all settings or the ones you need.

3- The configuration functions to add and delete Groups, cluster 0x0004, it works like this:

- When we add one or more devices to a group, we can send commands directly to all the devices in the same group with a remote control, which supports this function , without having to go through the Hub.

- I’ve added a custom capability, shown at the end, which shows the group numbers that are added to this device. You can also delete all the groups added from this capability.
 
- To add new groups:

- Open settings, preferences and in the Add Group options type the group number to add

- Inserting Value = 0 reads all Added Groups and displays them in the custom capability and event history.

- To Delete groups individually:

- Open settings, preferences and in the Options Remove Group number type the group number to remove.

- inserting value = 0 remove all groups


# (NEW RELEASE) Version 3.0 of the Edge Driver Zigbee Light Multifunction Mc

## Improvements and bug fixes:

My Thanks to @milandjurovic71 for test the driver with his bulbs.

As a request, @eric182 , the Continuous Color Change function has been added:

-Has a Custom Capability to turn the function Active and Inactive.

-Has a Custom Capability to modify the Timer between 1 and 20 sec for Color Changes

-Has a Custom Capability to select Color Change Mode

-Continuous Mode : The initial color is adjusted randomly and changes continuously with the rhythm of the timer chosen between 1 and 20 Sec.

-Random Mode : Color is adjusted randomly continuously with each timer interval

-All Modes : Both modes run randomly for a time between 50 sec to 300 sec each random cycle. Color change with random timer between 1 and 3 seconds.


## (NEW RELEASE) Version 2.0 of the Edge Driver Zigbee Light Multifunction Mc

## Improvements and bug fixes:

At the request of @milandjurovic71, preferences have been added for Minimum and Maximum Level settings of the Circadian Lighting function. In this way they are independent of the Llevel settings for progressive ON

The code has been corrected to prevent the “ Active " selections of the Progressive ON-OFF and Circadian Lighting functions from being reset to " Inactive " when a Reboot Hub or Driver update happens.


## (New RELEASE) New Edge Drive Zigbee Light Multifunction Mc:

- This Driver has all the functions of the Zigbee Level ColorTemp Bulb Mc driver, which it replaces and will not be updated any more.

## Added Color Control Capability with profiles for RGB and RGBW with 2700k-6500k Color temperature.

Thanks to the suggestion and collaboration to do the tests for @milandjurovic71


-All three capabilities are accessible for use with routines and scenes
Color change timer and color change mode can be modified dynamically.


## Works with lights, led strips with profiles:

Switch & Level
Switch, Level & ColorTemperature
Switch, Level, RGB, RGBW, RGBCCT, CCT
Could work with zigbee single dimmers, but not tested

## Included Devices :

See fingerprints.yml file