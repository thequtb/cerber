defmodule Cerber.CommandHandler do
  @moduledoc """
  Handles commands for Cerber projects.
  """
  
  alias Cerber.{UI, DB}
  alias YamlElixir
  
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
  
  defp build_project(project_name, args) do
    # Check if project exists
    case DB.get_project_by_name(project_name) do
      nil -> 
        UI.error("Project #{project_name} not found")
      project -> 
        # Run buildah commands to build the container
        UI.header("Building project #{project_name}")
        
        # Determine the path to the buildah.yaml file
        buildah_file = Path.join(["/apps", project_name, "conf", "buildah.yaml"])
        
        # Check if buildah.yaml exists
        if not File.exists?(buildah_file) do
          # Try alternative locations
          alternative_file = Path.join(["/apps", project_name, "buildah.yaml"])
          buildah_file = if File.exists?(alternative_file), do: alternative_file, else: buildah_file
        end
        
        if File.exists?(buildah_file) do
          # Read and parse the buildah.yaml file
          case YamlElixir.read_from_file(buildah_file) do
            {:ok, yaml_content} ->
              # Extract build steps
              build_steps = get_in(yaml_content, ["build"])
              
              if is_list(build_steps) and not Enum.empty?(build_steps) do
                # Create a map of variables for substitution
                vars = %{
                  "project_name" => project_name,
                  "template" => project.template,
                  "version" => project.version
                }
                
                # Execute each build step
                build_result = execute_build_steps(build_steps, vars, project_name)
                
                case build_result do
                  :ok ->
                    # Update database with build time on success
                    # Temporarily commenting out for testing
                    # DB.update_project(project, %{
                    #   last_built: DateTime.utc_now(),
                    #   status: "built"
                    # })
                    
                    UI.success("Project #{project_name} built successfully")
                    
                  {:error, step, exit_code, _output} ->
                    UI.error("Build failed at step: #{step}")
                    UI.error("Build process terminated with exit code #{exit_code}")
                end
              else
                UI.error("No build steps found in buildah.yaml")
                UI.info("Please make sure your buildah.yaml file contains a 'build:' section with a list of commands")
              end
              
            {:error, reason} ->
              UI.error("Failed to parse buildah.yaml: #{inspect(reason)}")
              UI.info("Please check that your buildah.yaml file contains valid YAML syntax")
          end
        else
          UI.error("Buildah configuration file not found")
          UI.info("Expected location: #{buildah_file}")
          UI.info("Please create a buildah.yaml file with build instructions")
        end
    end
  end
  
  # Execute build steps sequentially, stopping on the first error
  defp execute_build_steps(steps, vars, project_name) do
    # Create working directory if it doesn't exist
    work_dir = Path.join(["/apps", project_name])
    
    Enum.reduce_while(steps, :ok, fn step, _acc ->
      # Process variables in the step
      processed_step = process_variables(step, vars)
      
      UI.info("Executing: #{processed_step}")
      
      # Execute the build step
      case System.cmd("sh", ["-c", processed_step], cd: work_dir, stderr_to_stdout: true) do
        {output, 0} ->
          # Command succeeded
          unless output == "" do
            formatted_output = format_output(output)
            UI.info("Output: \n#{formatted_output}")
          end
          {:cont, :ok}
          
        {output, exit_code} ->
          # Command failed
          formatted_output = format_output(output)
          UI.error("Command failed with exit code #{exit_code}")
          UI.error("Output: \n#{formatted_output}")
          {:halt, {:error, processed_step, exit_code, output}}
      end
    end)
  end
  
  # Replace variables in a string with their values from a map
  defp process_variables(string, vars) when is_binary(string) do
    Regex.replace(~r/\#\{([^}]+)\}/, string, fn _, var_name ->
      value = Map.get(vars, var_name)
      cond do
        is_nil(value) -> ""
        is_binary(value) -> value
        true -> to_string(value)
      end
    end)
  end
  
  defp process_variables(non_string, _vars) do
    UI.error("Cannot process variables in non-string: #{inspect(non_string)}")
    ""
  end
  
  # Format command output for display
  defp format_output(output) when is_binary(output) do
    output
    |> String.trim()
    |> String.split("\n")
    |> Enum.map_join("\n", fn line -> "  #{line}" end)
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