defmodule Cerber.Template do
  @moduledoc """
  Handles template-based project creation.
  """

  alias Cerber.{DB, Repo, UI}

  @templates ["base", "bot", "api_langchain", "api_rest", "admin"]
  @templates_dir Path.join("/apps", "templates")

  @doc """
  Creates a new project from a template and records it in the database.
  """
  def create_from_template(params \\ %{}) do
    template = Map.get(params, "template")
    project_name = Map.get(params, "project_name")

    t = if template, do: template, else: select_template()
    p = if project_name, do: project_name, else: prompt_project_name(t)

    UI.header("Creating new project '#{p}'")
    UI.info("Using '#{t}' template")

    # Create project in database
    case DB.create_project(%{
      name: p, 
      template: t, 
      version: "0.1.0",
      config_path: Path.join(["/apps", p, "config.yaml"]),
      status: "new"
    }) do
      {:ok, project} -> 
        UI.success("Project '#{p}' successfully created and added to database.")
        
        # Create the actual project files and directories
        case create_project_structure(p, t) do
          {:ok, proj_dir} ->
            UI.success("Project files created at: #{proj_dir}")
            {:ok, project}
          {:error, reason} ->
            UI.error("Error creating project files: #{reason}")
            # Optionally, we could delete the DB record here if file creation fails
            {:error, reason}
        end
        
      {:error, changeset} ->
        UI.error("Error creating project: #{format_errors(changeset)}")
        {:error, changeset}
    end
  end

  @doc """
  Parse command line parameters into a map.
  """
  def parse_params(params) do
    params
    |> Enum.map(fn param ->
      case String.split(param, "=", parts: 2) do
        [key, value] -> {key, value}
        [key] -> {key, true}
      end
    end)
    |> Enum.into(%{})
  end

  # Project creation functions

  @doc """
  Creates the project structure based on a template.
  """
  def create_project_structure(project_name, template) do
    # Define project directory
    proj_dir = Path.join("/apps", project_name)
    
    # Prepare variables for template processing
    vars = %{
      "project_name" => project_name,
      "template" => template,
      "version" => "0.1.0",
      "description" => "Project created with #{template} template",
      "author" => System.get_env("USER") || "Cerber User"
    }
    
    with :ok <- create_project_directory(proj_dir),
         :ok <- copy_template_files(template, proj_dir),
         :ok <- process_template_files(proj_dir, template, vars) do
      {:ok, proj_dir}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Interactive template selection
  def select_template do
    UI.select("Select a template", @templates)
  end

  # Prompt for project name
  def prompt_project_name(template) do
    name = UI.prompt_with_default("Enter project name", "my_#{template}_project")
    
    # Check if the project name already exists
    case DB.get_project_by_name(name) do
      nil -> 
        name
      _ -> 
        UI.warning("A project with that name already exists.")
        prompt_project_name(template)
    end
  end

  @doc """
  Creates the main project directory.
  """
  defp create_project_directory(dir_path) do
    case File.mkdir_p(dir_path) do
      :ok -> :ok
      {:error, reason} -> {:error, "Failed to create project directory: #{reason}"}
    end
  end

  @doc """
  Copies template files to the project directory.
  """
  defp copy_template_files(template, proj_dir) do
    # Path to the template source files
    template_dir = Path.join(@templates_dir, template)

    if File.exists?(template_dir) do
      # For initial implementation, use System.cmd for recursive copy
      case System.cmd("cp", ["-r", "#{template_dir}/.", proj_dir]) do
        {_, 0} -> :ok
        {err, _} -> {:error, "Failed to copy template files: #{err}"}
      end
    else
      UI.warning("Template directory not found at #{template_dir}")
      # Templates not available, create minimal structure
      create_minimal_project(template, proj_dir)
    end
  end
  
  @doc """
  Process template files for variable substitution.
  """
  defp process_template_files(proj_dir, template, vars) do
    # Get template base configuration if available
    base_yaml_path = Path.join(@templates_dir, "base.yaml")
    
    if File.exists?(base_yaml_path) do
      UI.info("Processing template files...")
      
      # Read base.yaml and extract init commands if they exist
      case File.read(base_yaml_path) do
        {:ok, content} ->
          # Simple extraction of init commands without full YAML parser
          init_commands = extract_init_commands(content)
          
          # Process template variables in files
          substitute_variables_in_files(proj_dir, vars)
          
          # Run initialization commands if any were found
          unless Enum.empty?(init_commands) do
            run_initialization_commands(proj_dir, init_commands, vars)
          end
          
        _ -> 
          # File read error, just do simple substitution
          substitute_variables_in_files(proj_dir, vars)
      end
      
      :ok
    else
      # No base.yaml, just do simple substitution with provided vars
      substitute_variables_in_files(proj_dir, vars)
      :ok
    end
  end
  
  @doc """
  Extract initialization commands from base.yaml content using regex.
  """
  defp extract_init_commands(yaml_content) do
    # Find lines under the "init:" section that start with "- "
    case Regex.run(~r/init:\s*\n((?:\s*-\s*.*\n)+)/s, yaml_content) do
      [_, init_section] ->
        init_section
        |> String.split("\n")
        |> Enum.map(&String.trim/1)
        |> Enum.filter(fn line -> String.starts_with?(line, "- ") end)
        |> Enum.map(fn line -> String.trim_leading(line, "- ") end)
        |> Enum.map(&String.trim/1)
        |> Enum.filter(fn line -> line != "" end)
      
      _ -> []
    end
  end
  
  @doc """
  Substitute variables in text files within the project directory.
  """
  defp substitute_variables_in_files(dir, vars) do
    # Find text files and process them
    case System.cmd("find", [dir, "-type", "f", "-name", "*.md", "-o", "-name", "*.txt", "-o", "-name", "*.yaml", "-o", "-name", "*.yml"]) do
      {files, 0} ->
        String.split(files, "\n", trim: true)
        |> Enum.each(fn file ->
          process_file_variables(file, vars)
        end)
      _ -> :ok
    end
  end
  
  @doc """
  Process a single file for variable substitution.
  """
  defp process_file_variables(file_path, vars) do
    case File.read(file_path) do
      {:ok, content} ->
        # Replace #{variable_name} with its value
        updated_content = Regex.replace(~r/\#\{([^}]+)\}/, content, fn _, var_name ->
          Map.get(vars, var_name, "")
        end)
        
        # Write back the updated content
        File.write!(file_path, updated_content)
        
      _ -> :ok
    end
  end
  
  @doc """
  Run initialization commands from base.yaml.
  """
  defp run_initialization_commands(proj_dir, commands, vars) do
    UI.info("Running initialization commands...")
    
    commands
    |> Enum.each(fn cmd ->
      # Process variables in command
      processed_cmd = Regex.replace(~r/\#\{([^}]+)\}/, cmd, fn _, var_name ->
        Map.get(vars, var_name, "")
      end)
      
      UI.info("Running: #{processed_cmd}")
      
      # Execute command
      case System.cmd("sh", ["-c", processed_cmd], cd: proj_dir, stderr_to_stdout: true) do
        {output, 0} ->
          unless output == "", do: UI.info(output)
        {error, _} ->
          UI.error("Command failed: #{error}")
      end
    end)
  end

  @doc """
  Creates a minimal project structure when template files are not available.
  """
  defp create_minimal_project(template, proj_dir) do
    # Create basic structure with README and empty src directory
    src_dir = Path.join(proj_dir, "src")
    File.mkdir_p(src_dir)
    
    # Create basic README file
    readme_content = """
    # #{template} Project
    
    This project was created using the #{template} template.
    
    ## Getting Started
    
    Add implementation details here.
    """
    
    File.write(Path.join(proj_dir, "README.md"), readme_content)
    
    # Create a basic configuration file
    config_content = """
    project:
      name: #{Path.basename(proj_dir)}
      template: #{template}
      version: 0.1.0
    """
    
    File.write(Path.join(proj_dir, "config.yaml"), config_content)
    
    :ok
  end

  @doc """
  Format changeset errors into a readable string.
  """
  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map(fn {k, v} -> "#{k}: #{Enum.join(v, ", ")}" end)
    |> Enum.join("; ")
  end
end 