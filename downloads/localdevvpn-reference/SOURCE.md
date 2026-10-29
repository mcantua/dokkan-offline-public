# LocalDevVPN transport research

Purpose: verify VPN name, App Store link and loopback address, without guessing. Source inspected read-only; no code copied. Upstream licenses apply if implementation code is later copied.

- https://github.com/jkcoxson/LocalDevVPN/blob/af3fd697803ada4ac2b8d518358f5ab0a534844c/README.md
- https://github.com/jkcoxson/LocalDevVPN/blob/af3fd697803ada4ac2b8d518358f5ab0a534844c/LocalDevVPN/Constants.swift
- https://github.com/jkcoxson/minimuxer/blob/6ae94902a90c67bfea1a1ebacd4cda8bb576e943/src/device.rs

Observed: LocalDevVPN App Store link id6755608044; default interfaceconfigured-address/32, peerconfigured-address/32; minimuxer lockdown endpointconfigured-address:62078. Actual App Store availability, VPN session and phone transport have not been tested.
