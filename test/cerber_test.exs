defmodule CerberTest do
  use ExUnit.Case
  doctest Cerber

  test "greets the world" do
    assert Cerber.hello() == :world
  end
end
