defmodule Cerber.UI do
  @moduledoc """
  UI utilities for console output.
  """
  
  # ANSI colors
  @reset "\u001b[0m"
  @bold "\u001b[1m"
  @green "\u001b[32m"
  @yellow "\u001b[33m"
  @red "\u001b[31m"
  @blue "\u001b[34m"
  @magenta "\u001b[35m"
  @cyan "\u001b[36m"
  
  @doc """
  Print a header (blue + bold).
  """
  def header(text) do
    IO.puts("\n#{@blue}#{@bold}#{text}#{@reset}")
  end
  
  @doc """
  Print a success message (green).
  """
  def success(text) do
    IO.puts("#{@green}#{text}#{@reset}")
  end
  
  @doc """
  Print a warning message (yellow).
  """
  def warning(text) do
    IO.puts("#{@yellow}#{text}#{@reset}")
  end
  
  @doc """
  Print an error message (red).
  """
  def error(text) do
    IO.puts("#{@red}#{text}#{@reset}")
  end
  
  @doc """
  Print a command (cyan).
  """
  def command(text) do
    IO.puts("#{@cyan}$ #{text}#{@reset}")
  end
  
  @doc """
  Print info text (normal color).
  """
  def info(text) do
    IO.puts(text)
  end
  
  @doc """
  Print output from a command.
  """
  def output(text) do
    if text && text != "" do
      text
      |> String.split("\n", trim: true)
      |> Enum.each(fn line -> IO.puts("  #{line}") end)
    end
  end
  
  @doc """
  Print a table row, with padding.
  """
  def table_row(columns, widths) do
    row = Enum.zip(columns, widths)
    |> Enum.map(fn {col, width} -> String.pad_trailing(col, width) end)
    |> Enum.join(" | ")
    
    IO.puts("| #{row} |")
  end
  
  @doc """
  Print a table separator row.
  """
  def table_separator(widths) do
    separator = Enum.map(widths, fn width -> String.duplicate("-", width) end)
    |> Enum.join("-+-")
    
    IO.puts("+-#{separator}-+")
  end
  
  @doc """
  Ask for confirmation with yes/no.
  Returns true if the user confirms, false otherwise.
  """
  def confirm(message) do
    response = IO.gets("#{@yellow}#{message} [y/N]: #{@reset}")
    |> String.trim()
    |> String.downcase()
    
    response == "y" || response == "yes"
  end
  
  @doc """
  Ask for user input with a prompt.
  Returns the user's input as a string.
  """
  def prompt(message) do
    IO.gets("#{@magenta}#{message}: #{@reset}")
    |> String.trim()
  end
  
  @doc """
  Ask for user input with a prompt and a default value.
  Returns the user's input or the default if no input is provided.
  """
  def prompt_with_default(message, default) do
    input = IO.gets("#{@magenta}#{message} [#{default}]: #{@reset}")
    |> String.trim()
    
    if input == "", do: default, else: input
  end
  
  @doc """
  Select an item from a list with a prompt.
  """
  def select_from_list(prompt, options) do
    if options == [] do
      IO.puts("\n#{@magenta}#{prompt}#{@reset}")
      IO.puts("\n#{@yellow}No options available#{@reset}")
      nil
    else
      select(prompt, options)
    end
  end
  
  @doc """
  Display a selection menu and return the selected option.
  """
  def select(prompt, options) do
    IO.puts("\n#{@magenta}#{prompt}#{@reset}")
    
    options
    |> Enum.with_index(1)
    |> Enum.each(fn {option, index} ->
      IO.puts("  #{index}. #{option}")
    end)
    
    input = IO.gets("\n#{@magenta}Select [1-#{length(options)}]: #{@reset}")
    |> String.trim()
    
    case Integer.parse(input) do
      {num, _} when num >= 1 and num <= length(options) ->
        Enum.at(options, num - 1)
      _ ->
        warning("Invalid selection. Please try again.")
        select(prompt, options)
    end
  end
end 