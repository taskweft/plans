# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule Taskweft.PlansTest do
  @moduledoc """
  Pins `Taskweft.Plans`' compile-time-embedded content against the on-disk
  `priv/plans/` files it's baked from — a drift between the two would mean
  `mix compile` didn't pick up an edit (missing `@external_resource`) or the
  wildcard glob missed a file.
  """

  use ExUnit.Case, async: true

  alias Taskweft.Plans

  @plans_dir Path.join(["priv", "plans"])

  test "every on-disk domain file is embedded byte-for-byte" do
    for path <- Path.wildcard(Path.join([@plans_dir, "domains", "*.jsonld"])) do
      file = Path.basename(path)
      assert {:ok, content} = Plans.domain(file)
      assert content == File.read!(path)
    end
  end

  test "every on-disk problem file is embedded byte-for-byte" do
    for path <- Path.wildcard(Path.join([@plans_dir, "problems", "*.jsonld"])) do
      file = Path.basename(path)
      assert {:ok, content} = Plans.problem(file)
      assert content == File.read!(path)
    end
  end

  test "every on-disk problem notes file is embedded byte-for-byte" do
    for path <- Path.wildcard(Path.join([@plans_dir, "problems", "*.notes.json"])) do
      file = Path.basename(path)
      assert {:ok, content} = Plans.problem_notes(file)
      assert content == File.read!(path)
    end
  end

  test "list_domains/list_problems/list_problem_notes match what's on disk" do
    on_disk = fn glob ->
      @plans_dir
      |> Path.join(glob)
      |> Path.wildcard()
      |> Enum.map(&Path.basename/1)
      |> Enum.sort()
    end

    assert Plans.list_domains() == on_disk.(Path.join("domains", "*.jsonld"))
    assert Plans.list_problems() == on_disk.(Path.join("problems", "*.jsonld"))
    assert Plans.list_problem_notes() == on_disk.(Path.join("problems", "*.notes.json"))
  end

  test "domain/1 and problem/1 return :error for an unbundled file" do
    assert :error = Plans.domain("does_not_exist.jsonld")
    assert :error = Plans.problem("does_not_exist.jsonld")
    assert :error = Plans.problem_notes("does_not_exist.notes.json")
  end

  test "domain!/1 and problem!/1 raise for an unbundled file" do
    assert_raise KeyError, fn -> Plans.domain!("does_not_exist.jsonld") end
    assert_raise KeyError, fn -> Plans.problem!("does_not_exist.jsonld") end
  end

  test "bundled domain content parses as JSON" do
    for file <- Plans.list_domains() do
      assert {:ok, content} = Plans.domain(file)
      assert {:ok, _decoded} = Jason.decode(content)
    end
  end

  test "bundled problem content parses as JSON" do
    for file <- Plans.list_problems() do
      assert {:ok, content} = Plans.problem(file)
      assert {:ok, _decoded} = Jason.decode(content)
    end
  end
end
