defmodule Cerber.CLI do
  @moduledoc """
  Command-line interface for Cerber.
  """

  alias Cerber.{Template, UI, CommandHandler}

  @doc """
  Main entry point for the CLI interface.
  """
  def main(args) do
    # Ensure repo is started silently
    _ = ensure_repo_started()

    case args do
      # New command
      ["new"] ->
        Template.create_from_template()
        
      ["new" | params] when params != [] ->
        parsed = Template.parse_params(params)
        # Ensure template and project_name are present, prompt if missing
        template = Map.get(parsed, "template") || Template.__info__(:functions)[:select_template] && Template.select_template() || "base"
        project_name = Map.get(parsed, "project_name") || Template.__info__(:functions)[:prompt_project_name] && Template.prompt_project_name(template) || "my_#{template}_project"
        merged = Map.merge(parsed, %{"template" => template, "project_name" => project_name})
        Template.create_from_template(merged)
        
      # List all projects
      ["list"] ->
        list_projects()
        
      # Create a basic project
      [project_name] when is_binary(project_name) ->
        create_basic(project_name)
        
      # Project command with standard args format
      [project_name, command_name | command_args] ->
        CommandHandler.run_command(project_name, command_name, command_args)
        
      # Show help by default
      [] ->
        show_help()
        
      _ ->
        show_help()
    end
  end

  # Create a basic project
  defp create_basic(project_name) do
    Template.create_from_template(%{"template" => "base", "project_name" => project_name})
  end

  # List all projects
  defp list_projects do
    alias Cerber.DB
    
    UI.header("Available Projects")
    
    # Get projects from database
    db_projects = DB.list_projects()
    
    if Enum.empty?(db_projects) do
      UI.warning("No projects found.")
    else
      widths = [12, 15, 15, 15, 15]
      UI.table_row(["Name", "Template", "Status", "Last Built", "Last Run"], widths)
      UI.table_separator(widths)
      
      db_projects
      |> Enum.each(fn project ->
        last_built = if project.last_built, do: Calendar.strftime(project.last_built, "%Y-%m-%d %H:%M"), else: "Not built"
        last_run = if project.last_run, do: Calendar.strftime(project.last_run, "%Y-%m-%d %H:%M"), else: "Not run"
        
        UI.table_row([project.name, project.template, project.status, last_built, last_run], widths)
      end)
    end
  end

  # Display help information
  defp show_help do
    UI.info("""
    Usage:
      ./crbr new                               - Create a new project from template
      ./crbr new template=NAME project_name=NAME - Create project with parameters
      ./crbr list                              - List all projects
      ./crbr <project_name>                    - Create a basic project
      ./crbr <project_name> build              - Build project container
      ./crbr <project_name> run                - Run project container
      ./crbr <project_name> stop               - Stop project container
      ./crbr <project_name> logs               - Show container logs
      ./crbr <project_name> remove             - Remove project
      
      # Gitflow commands
      ./crbr <project_name> lock <branch>      - Lock a branch
      ./crbr <project_name> unlock <branch>    - Unlock a branch
      ./crbr <project_name> approve <branch>   - Approve a branch
      ./crbr <project_name> branch <branch>    - Set current branch
      ./crbr <project_name> stage <stage>      - Set current stage
      ./crbr <project_name> assign <username>  - Assign project
      ./crbr <project_name> workflow           - Show workflow info
    """)
  end

  # Ensure repo is started
  defp ensure_repo_started do
    case Cerber.Repo.start_link() do
      {:ok, pid} -> 
        # Run migrations if needed
        migrations_path = Path.join([:code.priv_dir(:cerber), "repo", "migrations"])
        Ecto.Migrator.run(Cerber.Repo, migrations_path, :up, all: true)
        {:ok, pid}
      {:error, {:already_started, pid}} ->
        {:ok, pid}
      {:error, _} ->
        # Continue without database
        :error
    end
  end
end 