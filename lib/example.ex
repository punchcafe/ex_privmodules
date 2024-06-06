defmodule Example do
  alias __MODULE__.PrivMod

  def do_stuff(), do: PrivMod.a_method()

  defdelegate a_method, to: PrivMod
end
