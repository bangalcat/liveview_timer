defmodule LiveviewTimer.Timer do
  use GenServer
  alias Phoenix.PubSub
  require Logger

  @default_start_time 25 * 60

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts[:args], name: opts[:name] || __MODULE__)
  end

  def get_timer_state(server \\ __MODULE__) do
    GenServer.call(server, :get_state)
  end

  def set_time(server \\ __MODULE__, time) do
    GenServer.call(server, {:set_time, time})
  end

  def play(server \\ __MODULE__) do
    GenServer.call(server, :play)
  end

  def pause(server \\ __MODULE__) do
    GenServer.call(server, :pause)
  end

  @impl true
  def init(args) do
    time = args || 25 * 60
    {:ok, {:stopped, time}}
  end

  @impl true
  def handle_call(:get_state, _, {status, time}) do
    {:reply, {status, time}, {status, time}}
  end

  def handle_call({:set_time, new_time}, _, {status, _time}) do
    {:reply, {status, new_time}, {status, new_time}, :hibernate}
  end

  def handle_call(:pause, _, {_status, time}) do
    notify()
    {:reply, time, {:stopped, time}}
  end

  def handle_call(:play, _, {status, time}) do
    case status do
      :stopped ->
        Process.send_after(self(), :tick, 1000)
        {:reply, status, {:running, time}}

      :done ->
        Process.send_after(self(), :tick, 1000)
        new_time = if time == 0, do: @default_start_time, else: time
        {:reply, status, {:running, new_time}}

      _ ->
        {:reply, status, {status, time}}
    end
  end

  @impl true
  def handle_info(:tick, {:running, 0}) do
    notify()
    {:noreply, {:done, 0}}
  end

  def handle_info(:tick, {:running, time}) do
    Logger.debug("#{time}")
    Process.send_after(self(), :tick, 1000)
    notify()
    {:noreply, {:running, time - 1}}
  end

  def handle_info(:tick, {status, time}) do
    {:noreply, {status, time}}
  end

  def subscribe do
    PubSub.subscribe(LiveviewTimer.PubSub, "liveview_timer")
  end

  def notify do
    PubSub.broadcast(LiveviewTimer.PubSub, "liveview_timer", :timer_updated)
  end
end
