use Mix.Config

config :alpheidae,
  welcome_text: "Hello!",
  max_bandwith: 32768,
  socket_options: [port: 5000, certfile: '_keys/cert.pem', keyfile: '_keys/key.pem']
