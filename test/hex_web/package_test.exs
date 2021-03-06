defmodule HexWeb.PackageTest do
  use HexWebTest.Case

  alias HexWeb.User
  alias HexWeb.Package

  setup do
    {:ok, _} = User.create(%{username: "eric", email: "eric@mail.com", password: "eric"}, true)
    :ok
  end

  test "create package and get" do
    user = User.get(username: "eric")
    user_id = user.id
    assert {:ok, %Package{}} = Package.create(user, pkg_meta(%{name: "ecto"}))
    assert [%User{id: ^user_id}] = Package.get("ecto") |> Package.owners
    assert is_nil(Package.get("postgrex"))
  end

  test "update package" do
    user = User.get(username: "eric")
    assert {:ok, package} = Package.create(user, pkg_meta(%{name: "ecto"}))

    Package.update(package, %{"meta" => %{"contributors" => ["eric", "josé"]}})
    package = Package.get("ecto")
    assert length(package.meta["contributors"]) == 2
  end

  test "validate valid meta" do
    meta = %{
      "contributors" => ["eric", "josé"],
      "licenses"     => ["apache", "BSD"],
      "links"        => %{"github" => "www", "docs" => "www"},
      "description"  => "so good"}

    user = User.get(username: "eric")
    assert {:ok, %Package{meta: ^meta}} = Package.create(user, pkg_meta(%{name: "ecto", meta: meta}))
    assert %Package{meta: ^meta} = Package.get("ecto")
  end

  test "ignore unknown meta fields" do
    meta = %{
      "contributors" => ["eric"],
      "foo"          => "bar"}

    user = User.get(username: "eric")
    assert {:ok, %Package{}} = Package.create(user, pkg_meta(%{name: "ecto", meta: meta}))
    assert %Package{meta: meta2} = Package.get("ecto")

    assert Map.size(meta2) == 1
    assert meta["contributors"] == meta2["contributors"]
  end

  test "validate invalid meta" do
    meta = %{
      "contributors" => "eric",
      "licenses"     => 123,
      "links"        => ["url"],
      "description"  => ["so bad"]}

    user = User.get(username: "eric")
    assert {:error, errors} = Package.create(user, pkg_meta(%{name: "ecto", meta: meta}))
    assert length(errors) == 1
    assert length(errors[:meta]) == 4
  end

  test "packages are unique" do
    user = User.get(username: "eric")
    assert {:ok, %Package{}} = Package.create(user, pkg_meta(%{name: "ecto"}))
    assert {:error, _} = Package.create(user, pkg_meta(%{name: "ecto"}))
  end

  test "reserved names" do
    user = User.get(username: "eric")
    assert {:error, [name: "is reserved"]} = Package.create(user, pkg_meta(%{name: "elixir"}))
  end
end
