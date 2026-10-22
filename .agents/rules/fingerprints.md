# Fingerprints and profiles

A profile's identity is the `name:` field inside the profile YAML. Filenames differ
from declared names throughout this repo:

| File | Declared `name:` |
|---|---|
| `multipurpose-switch-1.yml` | `multipurpse-switch-1` |
| `window-treatment-profile.calib.yml` | `window-treatment-profile-calib` |
| `battery-temp-humidity.yml` | `battery-temp-humid` |

Resolve every `deviceProfileName` by reading the `name:` field of the profiles in the
same driver directory. Matching is case-insensitive.

All 1,900 fingerprint entries currently resolve. `make fingerprints` proves it.

## Adding a fingerprint

1. Identify the device's `manufacturer` and `model` from `logcat` or the SmartThings app.
2. Choose a profile whose declared `name:` provides the capabilities the device reports.
3. Add the entry to the driver's `fingerprints.yml` under the matching section.
4. Give the entry an `id` that is unique within that file.
5. Run `make fingerprints`.
