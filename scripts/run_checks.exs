defmodule RunChecks do
  def run() do
    Agent.start_link(fn -> %{} end, name: :dependents_acc)
    Agent.start_link(fn -> [] end, name: :priv_modules)
    Mix.Task.clear()
    Mix.Task.run("compile", ["--force", "--tracer", __MODULE__])
  end

  @spec trace(tuple, Macro.Env.t()) :: :ok
  def trace({:remote_function, _meta, module, _, _}, env) do
    Agent.update(:dependents_acc, fn dependencies_acc ->
      Map.update(dependencies_acc, module, [env.module], fn list ->
        [env.module | list] |> Enum.uniq()
      end)
    end)

    :ok
  end

  @spec trace(tuple, Macro.Env.t()) :: :ok
  def trace({:on_module, _, _}, env) do
    module_space = Module.get_attribute(env.module, :module_private)

    if module_space do
      Agent.update(:priv_modules, fn acc -> [{env.module, module_space} | acc] end)
    end

    :ok
  end

  def trace(_, _) do
    :ok
  end

  def validate_call(calling_module, called_module, modulespace, modulespace_len) do
    calling_module_segments = Module.split(calling_module)
    valid? = Enum.take(calling_module_segments, modulespace_len) == modulespace

    if valid? do
      []
    else
      [{calling_module, called_module}]
    end
  end

  def validate_calls(dependants_map, priv_modules) do
    priv_modules
    |> Enum.flat_map(fn {module, modulespace} ->
      modulespace = Module.split(modulespace)
      modulespace_len = Enum.count(modulespace)

      dependants_map
      |> Map.get(module, [])
      |> Enum.flat_map(&validate_call(&1, module, modulespace, modulespace_len))
    end)
  end
end

require Logger
RunChecks.run()
dependents = Agent.get(:dependents_acc, & &1)
priv_modules = Agent.get(:priv_modules, & &1)
result = dependents |> RunChecks.validate_calls(priv_modules)

case result do
  [] ->
    System.halt(0)

  errors ->
    Enum.each(errors, fn {caller, called} ->
      Logger.error("Illegal call to private module #{called} in #{caller}.")
    end)

    Process.sleep(100)

    System.halt(1)
end
