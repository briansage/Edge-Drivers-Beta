# SmartThings Edge Drivers
Forked from [work by Mariano Colmenarejo](https://github.com/Mariano-Github/Edge-Drivers-Beta) and modified by Brian Sage.

### NOTICE
**The drivers in this repository and on my channel may not be up to date with the latest updates from Mariano Colmenarejo or SmartThings. Feel free to file an Issue or author a pull request to help update.**

## Installation

Tested with a SmartThings Hub v3 running firmware 62.x. Your mileage may vary.

The drivers install from this repository onto your own hub through a driver channel you
own, using the SmartThings CLI.

### 1. Install the tools

From the repo root:

```
brew bundle
```

The `Brewfile` installs the SmartThings CLI, `luacheck` (for the checks `make deploy`
runs before packaging), `stylua` and `mise`. The checks also use the system `python3`.
Without Homebrew, install the same tools another way.

### 2. Sign in

```
smartthings devices
```

The first command that needs your account opens a browser to sign in.

### 3. Create a channel and enroll your hub

Create the channel once. `channel.json` needs `name`, `description`, `termsOfServiceUrl`
and `"type": "DRIVER"`:

```
smartthings edge:channels:create --input channel.json
smartthings devices --type HUB
smartthings edge:channels:enroll <hub id> --channel <channel id>
```

### 4. Set up `.env`

```
cp .env.example .env
```

Set `CHANNEL` to the channel ID and `HUB` to the hub ID. `.env` stays out of git.

### 5. Install a driver

```
make deploy DRIVER=zigbee-light-multifunction-sage
```

This checks the driver, packages it, assigns it to your channel and installs it on your
hub. It deploys only drivers listed in `DRIVERS` in the `Makefile`.

### 6. Move your devices onto it

Devices stay on their current driver until you switch them. In the SmartThings app, open
the device, tap ⋮, then **Driver**. Or from the CLI:

```
smartthings edge:drivers:switch <device id>
```

## Getting Started

These steps are for changing the drivers. Install first, as above.

```
mise install   # Lua 5.3.6, pinned in mise.toml; also loads .env into your shell
make check     # lint and fingerprint gates for the drivers in DRIVERS
make test      # plain-Lua unit tests
```

To watch a driver's logs, run this in a terminal and accept the hub's certificate the
first time:

```
smartthings edge:drivers:logcat <driver id> --hub-address <hub ip>
```

`AGENTS.md` has the full conventions for working on this repo.

Feel free to use, modify, improve, and share.
