defmodule Cerber.Repo do
  use Ecto.Repo,
    otp_app: :cerber,
    adapter: Ecto.Adapters.Postgres
end
