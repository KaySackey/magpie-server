use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :magpie, Magpie.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :magpie, Magpie.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "magpie_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :guardian, Guardian,
  allowed_algos: ["HS512"], # optional
  verify_module: Guardian.JWT,  # optional
  issuer: "Magpie",
  ttl: { 1, :days },
  verify_issuer: false, # Anyone who knows my secret can talk to me!
  secret_key: "secret",
  serializer: Magpie.GuardianSerializer