# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule Taskweft.Plans do
  @moduledoc """
  Bundled RECTGTN HTN planning domains and problems, embedded into this
  module at compile time.

  `taskweft_plans` ships `priv/plans/{domains,problems}/*.jsonld` (plus a
  handful of `*.notes.json` siblings). Prior to this module, callers (e.g.
  `taskweft_mcp`'s resource handlers) read those files off disk at runtime
  via `:code.priv_dir(:taskweft_plans)` — fragile under some release/
  container packaging setups, where a *dependency's* `priv/` can end up
  missing from the assembled release even though it's listed in `package:
  files:` (the same failure class `taskweft/taskweft`'s
  `Taskweft.JSONLD.Loader` documents for its own bundled JSON schema: a
  path that resolves correctly under `mix run` but points at a directory
  that never exists in the runtime image).

  Baking file content into the `.beam` at compile time sidesteps the
  packaging question entirely — the data travels with the module no matter
  how the release is assembled, and callers no longer need `:code.priv_dir/1`
  at all. `@external_resource` on every bundled file makes `mix compile`
  recompile this module whenever a plan file changes, so the dev workflow
  (edit `.jsonld`, `mix test`) still works exactly as before.

  Every getter returns the exact raw file bytes (not a decoded/re-encoded
  term) — this module has no JSON dependency, and byte-for-byte content is
  what MCP resource reads have always served.
  """

  @plans_dir Path.join([__DIR__, "..", "..", "priv", "plans"]) |> Path.expand()

  @domain_files Path.wildcard(Path.join([@plans_dir, "domains", "*.jsonld"]))
  @problem_files Path.wildcard(Path.join([@plans_dir, "problems", "*.jsonld"]))
  @problem_note_files Path.wildcard(Path.join([@plans_dir, "problems", "*.notes.json"]))

  for file <- @domain_files ++ @problem_files ++ @problem_note_files do
    @external_resource file
  end

  # Not a `defp` helper: a module attribute assignment is evaluated during
  # compilation, before local functions defined later in the same module
  # body are callable from attribute context — inline the read instead.
  @domains Map.new(@domain_files, fn path -> {Path.basename(path), File.read!(path)} end)
  @problems Map.new(@problem_files, fn path -> {Path.basename(path), File.read!(path)} end)
  @problem_notes Map.new(@problem_note_files, fn path ->
                   {Path.basename(path), File.read!(path)}
                 end)

  @doc """
  Raw JSON-LD text for a bundled domain file, e.g. `"blocks_world.jsonld"`.
  """
  @spec domain(String.t()) :: {:ok, String.t()} | :error
  def domain(file), do: Map.fetch(@domains, file)

  @doc "Same as `domain/1`, raising if `file` is not bundled."
  @spec domain!(String.t()) :: String.t()
  def domain!(file), do: Map.fetch!(@domains, file)

  @doc """
  Raw JSON-LD text for a bundled problem file, e.g. `"blocks_world_1a.jsonld"`.
  """
  @spec problem(String.t()) :: {:ok, String.t()} | :error
  def problem(file), do: Map.fetch(@problems, file)

  @doc "Same as `problem/1`, raising if `file` is not bundled."
  @spec problem!(String.t()) :: String.t()
  def problem!(file), do: Map.fetch!(@problems, file)

  @doc """
  Raw JSON text for a bundled problem's sibling `.notes.json` file (human/
  LLM-facing status metadata, not part of the planning document itself),
  e.g. `"work_queue.notes.json"`.
  """
  @spec problem_notes(String.t()) :: {:ok, String.t()} | :error
  def problem_notes(file), do: Map.fetch(@problem_notes, file)

  @doc "File names of every bundled domain, e.g. `[\"blocks_world.jsonld\", ...]`."
  @spec list_domains() :: [String.t()]
  def list_domains, do: @domains |> Map.keys() |> Enum.sort()

  @doc "File names of every bundled problem, e.g. `[\"blocks_world_1a.jsonld\", ...]`."
  @spec list_problems() :: [String.t()]
  def list_problems, do: @problems |> Map.keys() |> Enum.sort()

  @doc "File names of every bundled problem's `.notes.json` sibling."
  @spec list_problem_notes() :: [String.t()]
  def list_problem_notes, do: @problem_notes |> Map.keys() |> Enum.sort()
end
