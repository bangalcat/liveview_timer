defmodule LiveviewTimerWeb.TimerLive.Index do
  use LiveviewTimerWeb, :live_view
  alias Phoenix.LiveView.JS
  alias LiveviewTimer.Timer

  @impl true
  def mount(_params, _session, socket) do
    {:ok, pid} = start_timer()
    if connected?(socket), do: Timer.subscribe()
    {status, time} = Timer.get_timer_state(pid)
    {:ok, assign(socket, :timer, %{remain_time: time, status: status, timer_id: pid})}
  end

  def circle_angle(remain_time) do
    "background: conic-gradient(#5B74A9A0 #{percent(remain_time)}%, #5B74A933 0);"
  end

  def hand_angle(remain_time) do
    "--tw-rotate: #{angle(remain_time)}deg;"
  end

  defp angle(i), do: 180 + i * 6 / 60
  defp percent(i), do: i / 60 / 60 * 100

  def digital_time(remain_time) do
    min = floor(remain_time / 60)
    sec = rem(remain_time, 60)
    String.pad_leading("#{min}", 2, "0") <> ":" <> String.pad_leading("#{sec}", 2, "0")
  end

  @impl true
  def handle_event("play_or_pause", %{"val" => btn}, %{assigns: %{timer: timer}} = socket) do
    case btn do
      "play" -> Timer.play(timer.timer_id)
      "pause" -> Timer.pause(timer.timer_id)
    end

    {status, remain_time} = Timer.get_timer_state(timer.timer_id)

    {:noreply,
     socket |> assign(:timer, Map.merge(timer, %{status: status, remain_time: remain_time}))}
  end

  def handle_event("update-timer", %{"time" => minute}, %{assigns: %{timer: timer}} = socket) do
    {status, remain_time} = Timer.set_time(timer.timer_id, ceil(minute * 60))

    {:noreply,
     socket |> assign(:timer, Map.merge(timer, %{status: status, remain_time: remain_time}))}
  end

  @impl true
  def handle_info(:timer_updated, socket) do
    {status, remain_time} = Timer.get_timer_state()

    {:noreply,
     socket
     |> assign(
       :timer,
       socket.assigns.timer |> Map.merge(%{status: status, remain_time: remain_time})
     )}
  end

  defp pause_or_play(:running), do: "pause"
  defp pause_or_play(_), do: "play"

  defp start_timer() do
    case Timer.start_link(args: 60 * 60) do
      {:error, {:already_started, pid}} ->
        {:ok, pid}

      {:ok, pid} ->
        {:ok, pid}
    end
  end
end
