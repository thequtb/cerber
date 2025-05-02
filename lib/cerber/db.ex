defmodule Cerber.DB do
  import Ecto.Query
  alias Cerber.{Repo, Project, Workflow}

  @doc """
  Lists all projects.
  """
  def list_projects do
    Repo.all(Project)
  end

  @doc """
  Gets a single project by id.
  """
  def get_project(id) do
    Repo.get(Project, id)
  end

  @doc """
  Gets a single project by name.
  """
  def get_project_by_name(name) do
    Repo.get_by(Project, name: name)
  end

  @doc """
  Creates a project.
  """
  def create_project(attrs) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a project.
  """
  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a project.
  """
  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end

  @doc """
  Gets a workflow for a project.
  """
  def get_workflow(project_id) do
    Repo.get_by(Workflow, project_id: project_id)
  end

  @doc """
  Creates a workflow.
  """
  def create_workflow(attrs) do
    %Workflow{}
    |> Workflow.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Locks a branch in a workflow.
  """
  def lock_branch(workflow_id, branch_name) do
    workflow = Repo.get(Workflow, workflow_id)
    
    if workflow do
      locked_branches = (workflow.locked_branches || []) ++ [branch_name]
      |> Enum.uniq()
      
      workflow
      |> Workflow.changeset(%{locked_branches: locked_branches})
      |> Repo.update()
    else
      {:error, :not_found}
    end
  end

  @doc """
  Unlocks a branch in a workflow.
  """
  def unlock_branch(workflow_id, branch_name) do
    workflow = Repo.get(Workflow, workflow_id)
    
    if workflow do
      locked_branches = (workflow.locked_branches || [])
      |> Enum.reject(fn b -> b == branch_name end)
      
      workflow
      |> Workflow.changeset(%{locked_branches: locked_branches})
      |> Repo.update()
    else
      {:error, :not_found}
    end
  end

  @doc """
  Approves a branch in a workflow.
  """
  def approve_branch(workflow_id, branch_name) do
    workflow = Repo.get(Workflow, workflow_id)
    
    if workflow do
      approved_branches = (workflow.approved_branches || []) ++ [branch_name]
      |> Enum.uniq()
      
      workflow
      |> Workflow.changeset(%{approved_branches: approved_branches})
      |> Repo.update()
    else
      {:error, :not_found}
    end
  end

  @doc """
  Sets the current branch in a workflow.
  """
  def set_current_branch(workflow_id, branch_name) do
    workflow = Repo.get(Workflow, workflow_id)
    
    if workflow do
      workflow
      |> Workflow.changeset(%{current_branch: branch_name})
      |> Repo.update()
    else
      {:error, :not_found}
    end
  end

  @doc """
  Sets the current stage in a workflow.
  """
  def set_current_stage(workflow_id, stage) do
    workflow = Repo.get(Workflow, workflow_id)
    
    if workflow do
      workflow
      |> Workflow.changeset(%{current_stage: stage})
      |> Repo.update()
    else
      {:error, :not_found}
    end
  end

  @doc """
  Sets the assignee in a workflow.
  """
  def set_assignee(workflow_id, assignee) do
    workflow = Repo.get(Workflow, workflow_id)
    
    if workflow do
      workflow
      |> Workflow.changeset(%{assignee: assignee})
      |> Repo.update()
    else
      {:error, :not_found}
    end
  end
end 