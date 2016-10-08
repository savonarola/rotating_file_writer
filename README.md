[![Build Status](https://travis-ci.org/savonarola/rotating_file_writer.svg?branch=master)](https://travis-ci.org/savonarola/rotating_file_writer)

# RotatingFileWriter

`RotatingFileWriter` is a simple write dispatcher. It opens file
on the basis of `strftime` pattern and current time and automatically
reopens it when pattern starts to interpolate into new name.

## Example

Basic usage:

```elixir
{:ok, writer} = RotatingFileWriter.start_link({"log/%F-%H.log", "Europe/Moscow"})

RotatingFileWriter.write(writer, "some log record")
# ...
RotatingFileWriter.write(writer, "some log record")

RotatingFileWriter.stop(writer)

```

Advanced usage:

```elixir
{:ok, writer} = RotatingFileWriter.start_link(
  fn(time) ->
     Timex.format!(time, "log/{ISOweek-day}.log")
  end, # Custom file name generating function
  [
    mode: [:write, :append, :sync], # Custom file open mode
    gen_server_opts: [name: RotatingLog], # GenServer options
    check_interval: 10000 # Custom interval of checking file name change, ms
  ]
)

RotatingFileWriter.write(writer, "some log record")

current_file_name = RotatingFileWriter.file_name(writer)

RotatingFileWriter.reopen(writer)

RotatingFileWriter.stop(writer)

```


## Installation

The package can be installed as:

  1. Add `rotating_file_writer` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:rotating_file_writer, "~> 0.1.0"}]
    end
    ```

  2. Ensure `rotating_file_writer` is started before your application:

    ```elixir
    def application do
      [applications: [:rotating_file_writer]]
    end
    ```

## License

This software is licensed under [MIT License](LICENSE).
