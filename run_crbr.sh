#!/bin/bash

# Get the directory where this script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if the escript is built, build it if not
if [ ! -f "$DIR/crbr" ]; then
  echo "Building Cerber CLI..."
  cd "$DIR" && mix escript.build
fi

# Run migrations if needed
echo "Running migrations..."
cd "$DIR" && mix ecto.create --quiet || true
cd "$DIR" && mix ecto.migrate --quiet || true

# Run the CLI with all arguments passed to this script
$DIR/crbr "$@" 