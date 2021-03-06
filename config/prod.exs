use Mix.Config

# For production, we configure the host to read the PORT
# from the system environment. Therefore, you will need
# to set PORT=80 before running your server.
#
# You should also configure the url host to something
# meaningful, we use this information when generating URLs.
#
# Finally, we also include the path to a manifest
# containing the digested version of static files. This
# manifest is generated by the mix phoenix.digest task
# which you typically run after static files are built.
#
# To set from enviroment variable: http: [port: {:system, "PORT"}],
# #url: [host: "magpie.chat"],
#
config :magpie, Magpie.Endpoint,
  http: [port: 8000],
  check_origin: false,
  cache_static_manifest: "priv/static/manifest.json"

# Do not print debug messages in production
config :logger, level: :info

# Do not allow fakes
config :magpie, :auth,
	allow_faker: true

config :phoenix, :serve_endpoints, true
config :magpie, Magpie.Endpoint, root: "."

# ## Using releases
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
#     config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :magpie, Magpie.Endpoint, server: true
#
# You will also need to set the application root to `.` in order
# for the new static assets to be served after a hot upgrade:
#
#     config :magpie, Magpie.Endpoint, root: "."

# Finally import the config/prod.secret.exs
# which should be versioned separately.
import_config "prod.secret.exs"
