defmodule RotatingFileWriter.Mixfile do
  use Mix.Project

  def project do
    [
      app: :rotating_file_writer,
      version: "0.1.0",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        "coveralls": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      deps: deps()
    ]
  end

  def application do
    [applications: [:logger, :timex]]
  end

  defp deps do
    [
      {:excoveralls, "~> 0.5", only: :test},
      {:timex, "~> 3.0"}
    ]
  end
end
