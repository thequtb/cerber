defmodule Cerber do
  use Application

  @moduledoc """
  Documentation for `Cerber`.
  """

  def start(_type, _args) do
    children = [
      Cerber.Repo
    ]
    opts = [strategy: :one_for_one, name: Cerber.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Main entry point for the CLI.
  """
  def main(args) do
    Cerber.CLI.main(args)
  end

  @doc """
  Hello world.

  ## Examples

      iex> Cerber.hello()
      :world

  """
  def hello do
    :world
  end
end
