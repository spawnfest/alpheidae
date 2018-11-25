# Alpheidae
[![CircleCI](https://circleci.com/gh/spawnfest/alpheidae/tree/master.svg?style=svg&circle-token=c655df12f3c97bd47e974e62c2bbb036a4e44778)](https://circleci.com/gh/spawnfest/alpheidae/tree/master)

A minimal mumble server written in Elixir.

## Running in development

Make sure you have the following installed:
 * Elixir 1.7.4 (compiled with Erlang/OTP 21)
 * openssl
 * [Mumble 1.2.19](https://wiki.mumble.info/wiki/Main_Page) or greater

Run the following to gereate a set of self signed keys and start the server.

    $ mix generate_keys
    $ mix run --no-halt

Connect on port 5000.

## Configuring the Server

Edit `config/dev.exs`. The valid keys are:

| Key | Description |
|-----|------------|
| `welcome_text` | Text sent to each user when they connect to the server |
| `max_bandwith` | Max bandwith; used in audio calculation |
| `channels` | List of each channel on the server |
| `socket_options` | [Ranch](https://github.com/ninenines/ranch)/[SSL](http://erlang.org/doc/man/ssl.html) options |

## Useful Reading

* [Mumble 1.2.5-alpha Protocol spec](https://media.readthedocs.org/pdf/mumble-protocol/latest/mumble-protocol.pdf)
* [Mumble/Murmur source](https://github.com/mumble-voip/mumble)