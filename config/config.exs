# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# third-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
config :gossip,
  seeds: [
    %{
      public_key:
        <<4, 192, 132, 7, 125, 156, 52, 165, 226, 49, 165, 233, 129, 177, 25, 187, 222, 148, 85,
          93, 233, 95, 88, 139, 164, 180, 19, 18, 127, 88, 166, 145, 217, 7, 91, 73, 143, 58, 213,
          139, 210, 220, 120, 115, 118, 153, 250, 58, 145, 196, 214, 91, 103, 3, 160, 77, 162,
          193, 35, 83, 4, 166, 23, 162, 91>>,
      ip: '127.0.0.1',
      port: 4000
    }
  ],
  cycle_milliseconds: 3000,
  public_key:
    <<4, 194, 90, 13, 115, 30, 9, 129, 130, 59, 51, 253, 18, 10, 203, 74, 216, 117, 181, 168, 95,
      126, 117, 234, 148, 164, 69, 178, 255, 126, 20, 119, 41, 4, 16, 226, 51, 140, 238, 117, 68,
      109, 171, 200, 13, 10, 159, 147, 80, 149, 146, 67, 61, 139, 94, 251, 208, 67, 119, 142, 213,
      234, 13, 210, 182>>,
  port: 3000

#
# and access this configuration in your application as:
#
#     Application.get_env(:gossip, :key)
#
# You can also configure a third-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env()}.exs"
