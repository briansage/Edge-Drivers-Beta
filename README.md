# SmartThings Edge Drivers
Forked from [work by Mariano Colmenarejo](https://github.com/Mariano-Github/Edge-Drivers-Beta) and modified by Brian Sage.

### NOTICE
**The drivers in this repository and on my channel may not be up to date with the latest updates from Mariano Colmenarejo or SmartThings. Feel free to file an Issue or author a pull request to help update.**

## Installation

Tested with SmartThings hub v3 by Aeotec running firmware 56.x. Your mileage may vary.

Add to your hub from this link:
https://api.SmartThings.com/invitation-web/accept?id=6b68563b-1905-4654-8d2b-e677a2997424

## Getting Started

These steps are for building and deploying the drivers to your own hub. To only install
them, use the invitation link above.

### Tools

```
brew install luacheck stylua smartthingscommunity/smartthings/smartthings mise
mise install    # Lua 5.3.6, pinned in mise.toml
```

The first `smartthings` command that needs your account opens a browser to sign in.

### A channel and a hub

Drivers reach a hub through a channel you own. Create one once, then enroll each hub in
it:

```
smartthings edge:channels:create --input channel.json
smartthings devices --type HUB
smartthings edge:channels:enroll <hub id> --channel <channel id>
```

`channel.json` needs `name`, `description`, `termsOfServiceUrl` and `"type": "DRIVER"`.

### Configure

```
cp .env.example .env
```

Fill in `CHANNEL` and `HUB`. `.env` stays out of git, and mise loads it into your shell
inside the repo.

### Work on a driver

```
make check     # lint and fingerprint gates for the drivers in DRIVERS
make test      # plain-Lua unit tests
make deploy DRIVER=zigbee-light-multifunction-sage
```

`make deploy` runs `make check` first, then packages the driver, assigns it to your
channel and installs it on your hub.

To watch a driver's logs, run this in a terminal and accept the hub's certificate the
first time:

```
smartthings edge:drivers:logcat <driver id> --hub-address <hub ip>
```

`AGENTS.md` has the full conventions for working on this repo.

Feel free to use, modify, improve, and share.
