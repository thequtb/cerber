defmodule Cerber.CommandHandler do
  @moduledoc """
  Handles commands for Cerber projects.
  """
  
  alias Cerber.{UI, DB}
  
  @doc """
  Runs a command for a specified project.
  """
  def run_command(project_name, command_name, args) do
    case command_name do
      "build" -> build_project(project_name, args)
      "run" -> run_project(project_name, args)
      "stop" -> stop_project(project_name, args)
      "logs" -> show_logs(project_name, args)
      "remove" -> remove_project(project_name, args)
      
      # Gitflow commands
      "lock" -> lock_branch(project_name, args)
      "unlock" -> unlock_branch(project_name, args)
      "approve" -> approve_branch(project_name, args)
      "branch" -> set_branch(project_name, args)
      "stage" -> set_stage(project_name, args)
      "assign" -> set_assignee(project_name, args)
      "workflow" -> show_workflow(project_name, args)
      
      # Custom commands
      _ -> run_custom_command(project_name, command_name, args)
    end
  end
  
  # Project commands
  
  defp build_project(project_name, _args) do
    # Check if project exists
    case DB.get_project_by_name(project_name) do
      nil -> 
        UI.error("Project #{project_name} not found")
      project -> 
        # Run buildah commands to build the container
        UI.header("Building project #{project_name}")
        
        # For now, just mock the build process
        UI.info("Building container image...")
        Process.sleep(1000)
        UI.success("Container image built successfully")
        
        # Update database with build time
        DB.update_project(project, %{
          last_built: DateTime.utc_now(),
          status: "built"
        })
        
        UI.success("Project #{project_name} built and database updated")
    end
  end
  
  defp run_project(project_name, _args) do
    # Check if project exists
    case DB.get_project_by_name(project_name) do
      nil -> 
        UI.error("Project #{project_name} not found")
      project -> 
        # Run podman commands to run the container
        UI.header("Running project #{project_name}")
        
        # For now, just mock the run process
        UI.info("Starting container...")
        Process.sleep(1000)
        UI.success("Container started successfully")
        
        # Update database with run time
        DB.update_project(project, %{
          last_run: DateTime.utc_now(),
          status: "running"
        })
        
        UI.success("Project #{project_name} is now running")
    end
  end
  
  defp stop_project(project_name, _args) do
    # Check if project exists
    case DB.get_project_by_name(project_name) do
      nil -> 
        UI.error("Project #{project_name} not found")
      project -> 
        # Run podman commands to stop the container
        UI.header("Stopping project #{project_name}")
        
        # For now, just mock the stop process
        UI.info("Stopping container...")
        Process.sleep(1000)
        UI.success("Container stopped successfully")
        
        # Update database status
        DB.update_project(project, %{status: "stopped"})
        UI.success("Project #{project_name} stopped")
    end
  end
  
  defp show_logs(project_name, args) do
    # Check if project exists
    case DB.get_project_by_name(project_name) do
      nil -> 
        UI.error("Project #{project_name} not found")
      _project -> 
        # Run podman commands to show logs
        follow = Enum.member?(args, "--follow") || Enum.member?(args, "-f")
        
        UI.header("Logs for project #{project_name}")
        
        # For now, just mock the logs
        UI.info("Container logs:")
        UI.info("[2024-05-01 12:00:00] Starting application")
        UI.info("[2024-05-01 12:00:01] Application initialized")
        UI.info("[2024-05-01 12:00:02] Ready to receive connections")
        
        if follow do
          UI.info("Press Ctrl+C to stop following logs...")
          # In a real implementation, we would use System.cmd with streaming
        end
    end
  end
  
  defp remove_project(project_name, args) do
    force = Enum.member?(args, "--force") || Enum.member?(args, "-f")
    
    # Check if project exists
    case DB.get_project_by_name(project_name) do
      nil -> 
        UI.error("Project #{project_name} not found")
      project -> 
        if force || UI.confirm("Are you sure you want to remove project #{project_name}?") do
          # Remove container and project files
          UI.header("Removing project #{project_name}")
          
          # For now, just mock the removal process
          UI.info("Removing container...")
          Process.sleep(500)
          UI.info("Removing project files...")
          Process.sleep(500)
          UI.success("Project files removed")
          
          # Remove from database
          case DB.delete_project(project) do
            {:ok, _} -> 
              UI.success("Project #{project_name} removed from database")
            {:error, reason} -> 
              UI.error("Failed to remove project from database: #{inspect(reason)}")
          end
        else
          UI.info("Removal cancelled")
        end
    end
  end
  
  # Gitflow commands
  
  defp lock_branch(project_name, [branch_name | _]) do
    case DB.get_project_by_name(project_name) do
      nil -> 
        UI.error("Project #{project_name} not found")
      project -> 
        case DB.get_workflow(project.id) do
          nil -> 
            {:ok, workflow} = DB.create_workflow(%{
              project_id: project.id,
              workflow_type: "gitflow",
              status: "active"
            })
            lock_branch_for_workflow(workflow.id, branch_name)
          workflow -> 
            lock_branch_for_workflow(workflow.id, branch_name)
        end
    end
  end
  
  defp lock_branch(project_name, []) do
    UI.error("Branch name is required")
  end
  
  defp lock_branch_for_workflow(workflow_id, branch_name) do
    case DB.lock_branch(workflow_id, branch_name) do
      {:ok, _} -> 
        UI.success("Branch #{branch_name} is now locked")
      {:error, reason} -> 
        UI.error("Failed to lock branch: #{inspect(reason)}")
    end
  end
  
  defp unlock_branch(project_name, [branch_name | _]) do
    case DB.get_project_by_name(project_name) do
      nil -> 
        UI.error("Project #{project_name} not found")
      project -> 
        case DB.get_workflow(project.id) do
          nil -> 
            UI.error("No workflow found for project #{project_name}")
          workflow -> 
            case DB.unlock_branch(workflow.id, branch_name) do
              {:ok, _} -> 
                UI.success("Branch #{branch_name} is now unlocked")
              {:error, reason} -> 
                UI.error("Failed to unlock branch: #{inspect(reason)}")
            end
        end
    end
  end
  
  defp unlock_branch(project_name, []) do
    UI.error("Branch name is required")
  end
  
  defp approve_branch(project_name, [branch_name | _]) do
    case DB.get_project_by_name(project_name) do
      nil -> 
        UI.error("Project #{project_name} not found")
      project -> 
        case DB.get_workflow(project.id) do
          nil -> 
            {:ok, workflow} = DB.create_workflow(%{
              project_id: project.id,
              workflow_type: "gitflow",
              status: "active"
            })
            approve_branch_for_workflow(workflow.id, branch_name)
          workflow -> 
            approve_branch_for_workflow(workflow.id, branch_name)
        end
    end
  end
  
  defp approve_branch(project_name, []) do
    UI.error("Branch name is required")
  end
  
  defp approve_branch_for_workflow(workflow_id, branch_name) do
    case DB.approve_branch(workflow_id, branch_name) do
      {:ok, _} -> 
        UI.success("Branch #{branch_name} is now approved")
      {:error, reason} -> 
        UI.error("Failed to approve branch: #{inspect(reason)}")
    end
  end
  
  defp set_branch(project_name, [branch_name | _]) do
    case DB.get_project_by_name(project_name) do
      nil -> 
        UI.error("Project #{project_name} not found")
      project -> 
        case DB.get_workflow(project.id) do
          nil -> 
            {:ok, workflow} = DB.create_workflow(%{
              project_id: project.id,
              workflow_type: "gitflow",
              status: "active"
            })
            set_branch_for_workflow(workflow.id, branch_name)
          workflow -> 
            set_branch_for_workflow(workflow.id, branch_name)
        end
    end
  end
  
  defp set_branch(project_name, []) do
    UI.error("Branch name is required")
  end
  
  defp set_branch_for_workflow(workflow_id, branch_name) do
    case DB.set_current_branch(workflow_id, branch_name) do
      {:ok, _} -> 
        UI.success("Current branch set to #{branch_name}")
      {:error, reason} -> 
        UI.error("Failed to set branch: #{inspect(reason)}")
    end
  end
  
  defp set_stage(project_name, [stage | _]) do
    case DB.get_project_by_name(project_name) do
      nil -> 
        UI.error("Project #{project_name} not found")
      project -> 
        case DB.get_workflow(project.id) do
          nil -> 
            {:ok, workflow} = DB.create_workflow(%{
              project_id: project.id,
              workflow_type: "gitflow",
              status: "active"
            })
            set_stage_for_workflow(workflow.id, stage)
          workflow -> 
            set_stage_for_workflow(workflow.id, stage)
        end
    end
  end
  
  defp set_stage(project_name, []) do
    UI.error("Stage name is required")
  end
  
  defp set_stage_for_workflow(workflow_id, stage) do
    case DB.set_current_stage(workflow_id, stage) do
      {:ok, _} -> 
        UI.success("Current stage set to #{stage}")
      {:error, reason} -> 
        UI.error("Failed to set stage: #{inspect(reason)}")
    end
  end
  
  defp set_assignee(project_name, [assignee | _]) do
    case DB.get_project_by_name(project_name) do
      nil -> 
        UI.error("Project #{project_name} not found")
      project -> 
        case DB.get_workflow(project.id) do
          nil -> 
            {:ok, workflow} = DB.create_workflow(%{
              project_id: project.id,
              workflow_type: "gitflow",
              status: "active"
            })
            set_assignee_for_workflow(workflow.id, assignee)
          workflow -> 
            set_assignee_for_workflow(workflow.id, assignee)
        end
    end
  end
  
  defp set_assignee(project_name, []) do
    UI.error("Assignee name is required")
  end
  
  defp set_assignee_for_workflow(workflow_id, assignee) do
    case DB.set_assignee(workflow_id, assignee) do
      {:ok, _} -> 
        UI.success("Project assigned to #{assignee}")
      {:error, reason} -> 
        UI.error("Failed to set assignee: #{inspect(reason)}")
    end
  end
  
  defp show_workflow(project_name, _args) do
    case DB.get_project_by_name(project_name) do
      nil -> 
        UI.error("Project #{project_name} not found")
      project -> 
        case DB.get_workflow(project.id) do
          nil -> 
            UI.warning("No workflow found for project #{project_name}")
          workflow -> 
            UI.header("Workflow for #{project_name}")
            UI.info("Type: #{workflow.workflow_type}")
            UI.info("Current branch: #{workflow.current_branch || "Not set"}")
            UI.info("Current stage: #{workflow.current_stage || "Not set"}")
            UI.info("Assignee: #{workflow.assignee || "Not set"}")
            
            UI.header("Locked branches")
            if Enum.empty?(workflow.locked_branches) do
              UI.info("No locked branches")
            else
              workflow.locked_branches
              |> Enum.each(fn branch -> UI.warning("  #{branch}") end)
            end
            
            UI.header("Approved branches")
            if Enum.empty?(workflow.approved_branches) do
              UI.info("No approved branches")
            else
              workflow.approved_branches
              |> Enum.each(fn branch -> UI.success("  #{branch}") end)
            end
        end
    end
  end
  
  defp run_custom_command(project_name, command_name, args) do
    UI.error("Command not found: #{command_name}")
    UI.info("Available commands: build, run, stop, logs, remove, lock, unlock, approve, branch, stage, assign, workflow")
  end
end 