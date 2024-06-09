[_] = Code.compile_file("./lib/ex_priv_modules.exs")
IO.inspect(ExPrivModules.__info__(:functions))

defmodule PrivateModTracer do
  @spec trace(tuple, Macro.Env.t()) :: :ok
  def trace({:remote_function, _meta, module, _, _}, env) do
    IO.inspect(ExPrivModules.__info__(:functions))
    ExPrivModules.add_function_call(env.module, module)
    :ok
  end

  @spec trace(tuple, Macro.Env.t()) :: :ok
  def trace({:on_module, _, _}, env) do
    module_space = Module.get_attribute(env.module, :module_private)

    if module_space do
      ExPrivModules.add_private_module(env.module, module_space)
    end

    :ok
  end

  def trace(_, _) do
    :ok
  end
end

require Logger

Mix.Task.clear()
{:ok, _} = ExPrivModules.start_link()
Mix.Task.run("compile", ["--force", "--tracer", PrivateModTracer])

case ExPrivModules.evaluate() do
  :ok ->
    Logger.info("All private module calls are valid")
    System.halt(0)

  {:error, errors} ->
    Logger.error("Failed to compile: following errors: #{inspect(errors)}")
end
