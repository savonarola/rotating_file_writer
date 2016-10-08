defmodule RotatingFileWriter do

  use GenServer

  require Logger

  @default_mode [:write, :append, :delayed_write]
  @default_gen_server_opts []
  @default_check_interval 1000

  def start_link(file_name_spec, opts \\ [])

  def start_link({file_name_pattern, time_zone}, opts) do
    file_name_fun = make_strftime_fun(file_name_pattern, time_zone)
    start_link(file_name_fun, opts)
  end

  def start_link(file_name_fun, opts) when is_function(file_name_fun) do
    mode = Keyword.get(opts, :mode, @default_mode)
    gen_server_opts = Keyword.get(opts, :gen_server_opts, @default_gen_server_opts)
    check_interval = Keyword.get(opts, :check_interval, @default_check_interval)
    initial_time = Keyword.get(opts, :initial_time, now)
    GenServer.start_link(__MODULE__, [file_name_fun, mode, check_interval, initial_time], gen_server_opts)
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def write(pid, data) do
    GenServer.call(pid, {:write, data})
  end

  def reopen(pid) do
    GenServer.call(pid, :reopen)
  end

  def file_name(pid) do
    GenServer.call(pid, :file_name)
  end

  def init([file_name_fun, mode, check_interval, initial_time]) do
    Process.flag(:trap_exit, true)
    file_name = file_name_fun.(initial_time)
    timer_ref = :erlang.start_timer(check_interval, self, :check_file_name_actuality)
    st = %{
      file_name_fun: file_name_fun,
      file_name: file_name,
      file: nil,
      mode: mode,
      timer_ref: timer_ref,
      check_interval: check_interval
    }
    {:ok, reopen_file(st)}
  end

  def check_file_name_actuality(pid, time \\ now) do
    GenServer.cast(pid, {:check_file_name_actuality, time})
  end

  def handle_call({:write, data}, _from, st) do
    result = IO.write(st.file, data)
    {:reply, result, st}
  end

  def handle_call(:file_name, _from, st) do
    {:reply, st.file_name, st}
  end

  def handle_call(:stop, _from, st) do
    {:stop, :normal, :ok, st}
  end

  def handle_call(:reopen, _from, st) do
    {:reply, :ok, reopen_file(st)}
  end

  def handle_cast({:check_file_name_actuality, time}, st) do
    new_st = maybe_reopen_file(time, st)
    {:noreply, new_st}
  end

  def handle_info({:timeout, _timer_ref, :check_file_name_actuality}, st) do
    new_timer_ref = :erlang.start_timer(st.check_interval, self, :check_file_name_actuality)
    :erlang.cancel_timer(st.timer_ref)
    check_file_name_actuality(self)
    {:noreply, %{st | timer_ref: new_timer_ref}}
  end

  def terminate(_reason, st) do
    close_file(st)
  end

  defp reopen_file(st) do
    close_file(st)
    Logger.info("Opening #{st.file_name}")
    file = File.open!(st.file_name, st.mode)
    %{st | file: file}
  end

  defp close_file(st) do
    if st.file do
      Logger.info("Closing #{st.file_name}")
      :ok = File.close(st.file)
    end
  end

  defp make_strftime_fun(file_name_pattern, time_zone) do
    fn(time) ->
      local_time = Timex.Timezone.convert(time, time_zone)
      Timex.format!(local_time, file_name_pattern, :strftime)
    end
  end

  defp now do
    Timex.now
  end

  defp maybe_reopen_file(new_time, st) do
    new_file_name = st.file_name_fun.(new_time)
    if new_file_name != st.file_name do
      reopen_file(%{st | file_name: new_file_name})
    else
      st
    end
  end

end
