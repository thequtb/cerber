defmodule Cerber.Repo.Migrations.CreateWorkflows do
  use Ecto.Migration

  def change do
    create table(:workflows) do
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :workflow_type, :string, null: false, default: "gitflow"
      add :current_branch, :string
      add :locked_branches, {:array, :string}, default: []
      add :approved_branches, {:array, :string}, default: []
      add :current_stage, :string
      add :assignee, :string
      add :last_commit, :string
      add :status, :string, null: false, default: "active"

      timestamps()
    end

    create index(:workflows, [:project_id])
  end
end 