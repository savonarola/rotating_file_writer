defmodule RotatingFileWriterTest do
  use ExUnit.Case

  setup_all do
    File.mkdir!("logtest")

    on_exit fn ->
      File.rm_rf!("logtest")
    end
  end

  test "start_link with pattern" do
    initial_time = Timex.parse!("2000-01-01T00:00:00+03:00", "%FT%T%:z", :strftime)

    {:ok, _} = RotatingFileWriter.start_link(
      {"logtest/%F.log", "Europe/Moscow"},
      initial_time: initial_time
    )
    assert File.exists?("logtest/2000-01-01.log")
  end

  test "start_link with fun" do
    {:ok, _} = RotatingFileWriter.start_link(
      fn(t) ->
        assert %DateTime{} = t
        "logtest/fun_generated.log"
      end
    )
    assert File.exists?("logtest/fun_generated.log")
  end

  test "start_link mode" do
    {:ok, writer} = RotatingFileWriter.start_link(
      fn(_) -> "logtest/mode.log" end
    )
    RotatingFileWriter.write(writer, "one")
    RotatingFileWriter.stop(writer)

    {:ok, writer} = RotatingFileWriter.start_link(
      fn(_) -> "logtest/mode.log" end
    )
    RotatingFileWriter.write(writer, "two")
    RotatingFileWriter.stop(writer)

    assert File.read!("logtest/mode.log") == "onetwo"

    {:ok, writer} = RotatingFileWriter.start_link(
      fn(_) -> "logtest/mode.log" end,
      mode: [:write]
    )
    RotatingFileWriter.write(writer, "three")
    RotatingFileWriter.stop(writer)

    assert File.read!("logtest/mode.log") == "three"
  end

  test "stop" do
    {:ok, writer} = RotatingFileWriter.start_link(
      fn(_) -> "logtest/stop.log" end
    )
    assert :ok == RotatingFileWriter.stop(writer)
  end

  test "write" do
    {:ok, writer} = RotatingFileWriter.start_link(
      fn(_) -> "logtest/write.log" end
    )
    RotatingFileWriter.write(writer, "somestring")
    RotatingFileWriter.stop(writer)

    assert File.read!("logtest/write.log") == "somestring"
  end

  test "reopen" do
    {:ok, writer} = RotatingFileWriter.start_link(
      fn(_) -> "logtest/reopen.log" end,
      mode: [:write, :sync]
    )
    RotatingFileWriter.write(writer, "somestring")
    assert File.read!("logtest/reopen.log") == "somestring"
    RotatingFileWriter.reopen(writer)
    # file is empty after reopen since we didn't pass :append
    assert File.read!("logtest/reopen.log") == ""
  end

  test "file_name" do
    initial_time = Timex.parse!("2001-01-01T00:00:00+03:00", "%FT%T%:z", :strftime)

    {:ok, writer} = RotatingFileWriter.start_link(
      {"logtest/%F.log", "Europe/Moscow"},
      initial_time: initial_time
    )

    assert "logtest/2001-01-01.log" == RotatingFileWriter.file_name(writer)
  end

  test "rotation" do
    initial_time = Timex.parse!("2002-01-01T00:00:00+03:00", "%FT%T%:z", :strftime)

    {:ok, writer} = RotatingFileWriter.start_link(
      {"logtest/%F.log", "Europe/Moscow"},
      initial_time: initial_time
    )

    now_time = Timex.parse!("2003-01-01T00:00:00+03:00", "%FT%T%:z", :strftime)
    RotatingFileWriter.check_file_name_actuality(writer, now_time)
    RotatingFileWriter.stop(writer)

    assert File.exists?("logtest/2003-01-01.log")
  end

  test "rotation (auto)" do
    {:ok, writer} = RotatingFileWriter.start_link(
      {"logtest/rotation-auto-%F.log", "Europe/Moscow"},
      check_interval: 1
    )
    :timer.sleep(10)
    assert :ok = RotatingFileWriter.stop(writer)
  end

end
