defmodule Cerber.Repo.Migrations.UpdateProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :version, :string, default: "0.1.0"
      add :last_built, :utc_datetime
      add :last_run, :utc_datetime
      add :config_path, :string
    end
  end
end 