defmodule RecStruct.Mixfile do
  use Mix.Project

  def project do
    [
      app: :rec_struct,
      version: "0.2.0",
      elixir: "~> 1.4",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      package: package(),
      description: description()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.14", only: :dev, runtime: false}
    ]
  end
  
  defp description do
    "Library for defining record structures, that is Elixir structs that automatically map to Erlang records."
  end
  
  defp package do
    [
      name: "rec_struct",
      files: ["lib/*", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Pawel Antemijczuk"],
      licenses: ["MIT License"],
      links: %{"GitHub" => "https://github.com/haljin/rec_struct"}
    ]
  end
end
