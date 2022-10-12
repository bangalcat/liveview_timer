defmodule LiveviewTimerWeb.PageController do
  use LiveviewTimerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
