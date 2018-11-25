# Alpheidae
[![CircleCI](https://circleci.com/gh/spawnfest/alpheidae/tree/master.svg?style=svg&circle-token=c655df12f3c97bd47e974e62c2bbb036a4e44778)](https://circleci.com/gh/spawnfest/alpheidae/tree/master)

A minimal mumble (voice chat) server written in Elixir.

## Running in development

Make sure you have the following installed:
 * Elixir 1.7.4 (compiled with Erlang/OTP 21)
 * openssl
 * [Mumble 1.2.19](https://wiki.mumble.info/wiki/Main_Page) or greater

Run the following to gereate a set of self signed keys and start the server.

    $ mix deps.get
    $ mix generate_keys
    $ mix run --no-halt

Connect on port 5000.

## Demonstration/Testing

0. Get Mumble clients as above (for Ubuntu 16.04 or higher, get the 1.3 [snaphots](https://launchpad.net/~mumble/+archive/ubuntu/snapshot)).
1. Get the dependencies: `$ mix deps.get`
2. Generate the server keys: `$ mix generate_keys`
3. Start the server: `$ mix run --no-halt`
4. In new terminals, start 2 new mumble instances: `$ mumble -m `
5. Connect each instance to your server (default is localhost, port is 5000)
6. Mute yourself in both instances (click the little microphone icon to make it red/disabled)
7. Unmute yourself in one instance and talk
8. You should hear yourself talking!
9. Send a message in the chat room, watch it show up in the other instance.
10. Right-click on one of the instances and send a private message, watch it show up in the other instance.
11. In the instance, double-click on a channel name and your user will change channels. Observe this in other instance.

## Configuring the Server

Edit `config/dev.exs`. The valid keys are:

| Key | Description |
|-----|------------|
| `welcome_text` | Text sent to each user when they connect to the server |
| `max_bandwith` | Max bandwith; used in audio calculation |
| `channels` | List of each channel on the server |
| `socket_options` | [Ranch](https://github.com/ninenines/ranch)/[SSL](http://erlang.org/doc/man/ssl.html) options |

## Todos / Future work

* UDP support
* Channel links
* ACLs/ permission system
* Client certificate authentication
* Better channel configuration
* Web interface/in-browser audio
* Better deafening/muting support
* Server viewer support

## Useful Reading

* [Mumble 1.2.5-alpha Protocol spec](https://media.readthedocs.org/pdf/mumble-protocol/latest/mumble-protocol.pdf)
* [Mumble/Murmur source](https://github.com/mumble-voip/mumble)