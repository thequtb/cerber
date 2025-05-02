defmodule Bot.TelegramBot do
  use GenServer
  require Logger

  @bot_token System.get_env("TELEGRAM_BOT_TOKEN")

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    if is_nil(@bot_token) do
      Logger.warning("TELEGRAM_BOT_TOKEN environment variable is not set. Bot will not function properly.")
    else
      # Start long polling for updates
      schedule_get_updates()
    end

    {:ok, %{offset: 0}}
  end

  @impl true
  def handle_info(:get_updates, %{offset: offset} = state) do
    new_offset = 
      case Telegex.get_updates(offset: offset, timeout: 30) do
        {:ok, []} ->
          offset
          
        {:ok, updates} ->
          Logger.info("Received #{length(updates)} updates")
          
          # Process each update
          updates
          |> Enum.each(&process_update/1)
          
          # Return the last update_id + 1 to acknowledge processing
          List.last(updates).update_id + 1
          
        {:error, error} ->
          Logger.error("Error getting updates: #{inspect(error)}")
          offset
      end
      
    schedule_get_updates()
    {:noreply, %{state | offset: new_offset}}
  end

  defp schedule_get_updates do
    # Schedule the next update check in 1 second
    Process.send_after(self(), :get_updates, 1000)
  end

  defp process_update(%{message: nil}), do: :ok

  defp process_update(%{message: message}) do
    case message.text do
      "/start" ->
        send_message(message.chat.id, "Hello! I'm your #{project_name} bot!")
        
      "/help" ->
        send_message(message.chat.id, """
        Available commands:
        /start - Start the bot
        /help - Show this help message
        /echo [text] - Echo back the text
        """)
        
      "/echo " <> text ->
        send_message(message.chat.id, "Echo: #{text}")
        
      text when is_binary(text) ->
        send_message(message.chat.id, "Send /help to see available commands.")
        
      _ ->
        :ok
    end
  end

  defp send_message(chat_id, text) do
    case Telegex.send_message(chat_id, text) do
      {:ok, _} -> :ok
      {:error, error} -> Logger.error("Error sending message: #{inspect(error)}")
    end
  end
end 