# Cerber

Cerber is a powerful containerization and project management CLI tool built with Elixir. It simplifies the process of creating, building, running, and managing containerized applications using Buildah and Podman.

## Features

- **Project Templates**: Create new projects from pre-defined templates
- **Database Integration**: Track projects and workflows in PostgreSQL
- **Containerization**: Build container images using Buildah
- **Container Management**: Run, stop, and monitor containers with Podman
- **Project Management**: List, inspect, and remove projects
- **Workflow Orchestration**: Enforce gitflow or other workflow patterns

## Installation

### Prerequisites

- Elixir 1.14 or later
- Buildah (for container building)
- Podman (for container running)
- PostgreSQL (for database storage)

### Building from Source

```bash
# Clone the repository
git clone <repository-url>
cd cerber

# Get dependencies
mix deps.get

# Compile the project
mix compile

# Build the executable
mix escript.build
```

This creates an executable named `crbr` that you can run directly or add to your PATH.

## Configuration

This project follows 12-factor app principles for configuration:

1. Copy `env.sample` to `.env` and update values for your environment
2. For environment-specific overrides, create `.dev.overrides.env`, `.test.overrides.env`, or `.prod.overrides.env` files

The application uses Dotenvy to load environment variables at runtime following this priority:
- Base configuration from `.env`
- Environment-specific overrides from `.{env}.overrides.env`
- System environment variables

## Usage

### Project Creation

```bash
# Create a new project (interactive mode)
./crbr new

# Create a new project with specific parameters
./crbr new template=bot project_name=my_awesome_bot

# Create a basic project
./crbr my_project
```

### Project Management

```bash
# List all projects
./crbr list

# Build a project container
./crbr my_project build

# Run a project container
./crbr my_project run

# Stop a running container
./crbr my_project stop

# View container logs
./crbr my_project logs
./crbr my_project logs --follow

# Remove a project
./crbr my_project remove
./crbr my_project remove --force
```

### Workflow Management

```bash
# Create new feature
./crbr my_project feature add

./crbr my_project feature test

./crbr my_project feature commit 

./crbr my_project feature merge


## Available Templates

- **base**: Basic project structure
- **bot**: Chatbot applications
- **api_langchain**: LangChain API applications
- **api_rest**: REST API applications
- **admin**: Admin panel applications

## Database Schema

Cerber uses PostgreSQL to store project and workflow information:

### Projects Table

- `id`: Primary key
- `name`: Project name
- `template`: Template used
- `status`: Current status

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/cerber>.

