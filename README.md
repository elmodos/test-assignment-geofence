Test Assignment 
----------------

The goal of this assignment is to create an iOS application that will detect if the device is located inside of a geofence area.

Geofence area is defined as a combination of some geographic point, radius, and specific Wifi network name. A device is considered to be inside of the geofence area if the device is connected to the specified WiFi network or remains geographically inside the defined circle.

Note that if device coordinates are reported outside of the zone, but the device still connected to the specific Wifi network, then the device is treated as being inside the geofence area.

Application activity should provide controls to configure the geofence area and display current status: inside OR outside.

Requirements 
---

To be able to build and run applicaton on your device, your provisioning profile should
- have explicit bundle id of target `geofence`
- have `Access WiFi Information` capability on
- have `Background Modes` capability on

You also will need [CocoaPods](https://guides.cocoapods.org/using/getting-started.html#installation)

```terminal
$ sudo gem install cocoapods
$ cd geofence
$ pod install
```

Then open `geofence.xcworkspace` 
