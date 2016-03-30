ExUnit.start

Mix.Task.run "ecto.create", ~w(-r Magpie.Repo --quiet)
Mix.Task.run "ecto.migrate", ~w(-r Magpie.Repo --quiet)
Ecto.Adapters.SQL.begin_test_transaction(Magpie.Repo)


ExUnit.configure(
timeout: 500,
capture_log: true,
#include: [],
exclude: [])

