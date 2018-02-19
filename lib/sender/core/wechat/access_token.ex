defmodule Sender.Core.Wechat.AccessToken do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    {:ok, %{token: get_token()}}
  end

  @spec access_token() :: String.t()
  def access_token do
    GenServer.call(__MODULE__, :access_token)
  end

  @spec refresh_token() :: :ok
  def refresh_token do
    GenServer.cast(__MODULE__, :refresh_token)
  end

  @doc """
  Берет токен, проверяет на свежесть. Если просрочен, то запрашивает новый и
  отдает. Если токен свежий, но время его жизни через 10 минут подойдет к концу,
  то отдаем токен тому кто запросил, и обновляемся.
  """
  def handle_call(:access_token, _from, %{token: {token, exp_date}} = state) do
    if exp_date > :os.system_time(:seconds) do
      if exp_date - 600 < :os.system_time(:seconds) do
        refresh_token()
      end

      {:reply, token, state}
    else
      case get_token() do
        {token, exp} ->
          {:reply, token, %{token: {token, exp}}}

        _ ->
          {:reply, nil, state}
      end
    end
  end

  def handle_call(:access_token, _from, %{token: nil} = state) do
    case get_token() do
      {token, exp} ->
        {:reply, token, %{token: {token, exp}}}

      _ ->
        {:reply, nil, state}
    end
  end

  def handle_cast(:refresh_token, _state) do
    {:noreply, %{token: get_token()}}
  end

  @spec get_token() :: {token :: String.t(), exp :: integer}
  defp get_token do
    wechat_cfg()
    |> token_url()
    |> request_token()
    |> receive_token()
    |> take_token()
  end

  defp wechat_cfg() do
    Application.get_env(:sender, :wechat) |> Enum.into(%{})
  end

  defp token_url(%{api_url: api_url, app_id: id, app_secret: secret}) do
    {:ok, "#{api_url}/token?grant_type=client_credential&appid=#{id}&secret=#{secret}"}
  end

  defp token_url(_) do
    {:error, "not detected some env config parameter"}
  end

  defp request_token({:ok, url}) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, body}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp request_token({:error, reason}), do: {:error, reason}

  defp receive_token({:ok, body}) do
    case body |> Poison.decode!() do
      %{"access_token" => token, "expires_in" => exp} ->
        {:ok, {token, exp}}

      %{"errmsg" => msg} ->
        {:error, msg}
    end
  end

  defp receive_token({:error, reason}), do: {:error, reason}

  defp take_token({:ok, {token, exp}}), do: {token, :os.system_time(:seconds) + exp}

  defp take_token({:error, reason}) do
    Logger.error("#{reason}")
    nil
  end
end
