defmodule AnotherIllegalCall do
  def do_stuff(), do: Example.PrivMod.a_method()
end
