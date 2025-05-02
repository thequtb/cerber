import Config
import Dotenvy

env_dir_prefix = "."

source!([
  Path.absname(".env", env_dir_prefix),
  Path.absname(".#{config_env()}.overrides.env", env_dir_prefix),
  System.get_env()
])

config :cerber, Cerber.Repo,
  database: env!("DB_NAME", :string),
  username: env!("DB_USER", :string),
  password: env!("DB_PASSWORD", :string),
  hostname: env!("DB_HOST", :string),
  pool_size: env!("DB_POOL_SIZE", :integer, 10)

# Add any environment-specific settings
if config_env() == :test do
  config :cerber, Cerber.Repo, pool: Ecto.Adapters.SQL.Sandbox
end 