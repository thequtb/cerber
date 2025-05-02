defmodule Cerber.Workflow do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workflows" do
    field :workflow_type, :string, default: "gitflow"
    field :current_branch, :string
    field :locked_branches, {:array, :string}, default: []
    field :approved_branches, {:array, :string}, default: []
    field :current_stage, :string
    field :assignee, :string
    field :last_commit, :string
    field :status, :string, default: "active"

    belongs_to :project, Cerber.Project

    timestamps()
  end

  def changeset(workflow, attrs) do
    workflow
    |> cast(attrs, [:project_id, :workflow_type, :current_branch, :locked_branches, 
                   :approved_branches, :current_stage, :assignee, :last_commit, :status])
    |> validate_required([:project_id, :workflow_type])
    |> foreign_key_constraint(:project_id)
  end
end 