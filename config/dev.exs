use Mix.Config

config :alpheidae,
  welcome_text: "Hello!",
  max_bandwith: 32768,
  channels: [
    %{name: "Channel One", description: "Hello!"}
  ],
  super_user_token: "abcdefg",
  socket_options: [port: 5000, certfile: '_keys/cert.pem', keyfile: '_keys/key.pem']
