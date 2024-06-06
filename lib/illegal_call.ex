defmodule IllegalCall do
  alias Example.PrivMod

  def do_stuff(), do: PrivMod.a_method()
end
