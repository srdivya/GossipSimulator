defmodule PROJECT2Test do
  use ExUnit.Case
  doctest PROJECT2

  test "greets the world" do
    assert PROJECT2.hello() == :world
  end
end
