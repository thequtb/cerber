defmodule Cerber.Project do
  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field :name, :string
    field :template, :string
    field :version, :string, default: "0.1.0"
    field :last_built, :utc_datetime
    field :last_run, :utc_datetime
    field :config_path, :string
    field :status, :string, default: "new"

    timestamps()
  end

  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :template, :version, :last_built, :last_run, :config_path, :status])
    |> validate_required([:name, :template])
    |> validate_inclusion(:template, ["base", "bot", "api_langchain", "api_rest", "admin"])
    |> validate_inclusion(:status, ["new", "built", "running", "stopped", "set_up"])
    |> unique_constraint(:name)
  end
end 