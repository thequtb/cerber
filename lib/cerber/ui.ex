defmodule Cerber.UI do
  @moduledoc """
  UI utilities for Cerber CLI.
  """
  
  @doc """
  Prints a header with a title.
  """
  def header(title) do
    IO.puts("\n\e[1m\e[36m=== #{title} ===\e[0m")
  end
  
  @doc """
  Prints an info message.
  """
  def info(message) do
    IO.puts(message)
  end
  
  @doc """
  Prints a success message.
  """
  def success(message) do
    IO.puts("\e[32m#{message}\e[0m")
  end
  
  @doc """
  Prints a warning message.
  """
  def warning(message) do
    IO.puts("\e[33m#{message}\e[0m")
  end
  
  @doc """
  Prints an error message.
  """
  def error(message) do
    IO.puts("\e[31m#{message}\e[0m")
  end
  
  @doc """
  Prints a table row with specified column widths.
  """
  def table_row(columns, widths) do
    columns
    |> Enum.zip(widths)
    |> Enum.map(fn {col, width} ->
      col_str = if is_nil(col), do: "", else: to_string(col)
      String.pad_trailing(col_str, width)
    end)
    |> Enum.join(" | ")
    |> then(&IO.puts("| #{&1} |"))
  end
  
  @doc """
  Prints a table separator line.
  """
  def table_separator(widths) do
    widths
    |> Enum.map(fn width -> String.duplicate("-", width) end)
    |> Enum.join("-+-")
    |> then(&IO.puts("+-#{&1}-+"))
  end
  
  @doc """
  Prompts the user for input with a default value.
  """
  def prompt(message, default \\ "") do
    default_display = if default != "", do: " [#{default}]", else: ""
    IO.gets("#{message}#{default_display}: ")
    |> String.trim()
    |> then(fn input ->
      if input == "", do: default, else: input
    end)
  end
  
  @doc """
  Prompts the user to select an option from a list.
  """
  def select(message, options) do
    IO.puts("\n#{message}:")
    
    options
    |> Enum.with_index(1)
    |> Enum.each(fn {option, index} ->
      IO.puts("  #{index}. #{option}")
    end)
    
    selected = 
      IO.gets("\nEnter your choice (1-#{length(options)}): ")
      |> String.trim()
      |> Integer.parse()
      |> case do
        {num, _} when num > 0 and num <= length(options) ->
          Enum.at(options, num - 1)
        _ ->
          warning("Invalid selection. Please try again.")
          select(message, options)
      end
    
    selected
  end
  
  @doc """
  Prompts for confirmation.
  """
  def confirm(message, default \\ true) do
    default_str = if default, do: "Y/n", else: "y/N"
    response = IO.gets("#{message} [#{default_str}]: ")
    |> String.trim()
    |> String.downcase()
    
    case response do
      "" -> default
      "y" -> true
      "yes" -> true
      "n" -> false
      "no" -> false
      _ -> 
        warning("Please answer 'y' or 'n'.")
        confirm(message, default)
    end
  end
end 