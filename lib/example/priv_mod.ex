defmodule Example.PrivMod do
  @module_private Example

  def a_method() do
    :ok
  end
end
