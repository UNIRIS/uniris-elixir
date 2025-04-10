use Mix.Config

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
          <<4, 192, 132, 7, 125, 156, 52, 165, 226, 49, 165, 233, 129, 177, 25, 187, 222, 148, 85,
          93, 233, 95, 88, 139, 164, 180, 19, 18, 127, 88, 166, 145, 217, 7, 91, 73, 143, 58, 213,
          139, 210, 220, 120, 115, 118, 153, 250, 58, 145, 196, 214, 91, 103, 3, 160, 77, 162,
          193, 35, 83, 4, 166, 23, 162, 91>>,

  port: 4000