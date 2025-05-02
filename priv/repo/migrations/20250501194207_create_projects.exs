defmodule Cerber.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :name, :string, null: false
      add :template, :string, null: false
      add :status, :string, null: false, default: "new"

      timestamps()
    end

    create unique_index(:projects, [:name])

    execute "ALTER TABLE projects ADD CONSTRAINT template_enum CHECK (template IN ('base', 'bot', 'api_langchain', 'api_rest', 'admin'))"
    execute "ALTER TABLE projects ADD CONSTRAINT status_enum CHECK (status IN ('new', 'built', 'running', 'stopped', 'set_up'))"
  end
end
