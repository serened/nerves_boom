defmodule Boom do
  require Logger
  use Application
  @interface :wlan0
  @kernel_modules Mix.Project.config[:kernel_modules] || []

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      # worker(Boom.Worker, [arg1, arg2, arg3]),
      worker(Task, [fn -> blinker() end], id: Boom.Blinker),
      worker(Task, [fn -> init_kernel_modules() end], restart: :transient, id: Nerves.Init.KernelModules),
      worker(Task, [fn -> init_wifi_network() end], restart: :transient, id: Nerves.Init.WifiNetwork),
      worker(Task, [fn -> talker() end], id: Boom.Talker),
      worker(NetworkManager, [@interface], restart: :transient, id: Boom.Init.NetworkManager),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Boom.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def blinker() do
    Nerves.Leds.set green: true
    :timer.sleep 200
    Nerves.Leds.set green: false
    :timer.sleep 200
    blinker()
  end

  def init_kernel_modules() do
    Enum.each(@kernel_modules, & System.cmd("modprobe", [&1]))
  end

  def init_wifi_network() do
    Nerves.InterimWiFi.setup @interface, Application.get_env(:boom, @interface)
  end
  
  def talker() do
    Logger.info "wooteroni 🍕"
    :timer.sleep 1000
    talker()
  end
end
