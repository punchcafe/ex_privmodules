defmodule ExPrivModules do
  use GenServer

  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def add_function_call(calling_module, called_module) do
    GenServer.cast(__MODULE__, {:function_call, calling_module, called_module})
  end

  def add_private_module(private_module, module_space) do
    GenServer.cast(__MODULE__, {:register_module, private_module, module_space})
  end

  def evaluate() do
    GenServer.call(__MODULE__, {:validate})
  end

  ## GenServer Behaviour

  def init(_) do
    function_calls = :ets.new(:function_call, [:set, :protected])
    {:ok, private_modules} = Agent.start_link(fn -> [] end, name: :priv_modules)
    {:ok, {function_calls, private_modules}}
  end

  def handle_call({:validate}, _, state = {function_calls, private_modules}) do
    # Add shutdown flag

    private_modules
    |> Agent.get(& &1)
    |> Enum.map(fn {private_module, private_module_space} ->
      # Should maybe do this on the Agent itself?
      case :ets.lookup(function_calls, private_module) do
        [] ->
          nil

        [{private_module, calling_modules}] ->
          {private_module, private_module_space, calling_modules}
      end
    end)
    |> Enum.filter(& &1)
    |> Enum.flat_map(&validate_callers/1)
    |> case do
      [] -> {:reply, :ok, state}
      errors -> {:reply, {:error, errors}, state}
    end
  end

  defp validate_callers({private_module, private_module_space, calling_modules}) do
    modulespace_segments = Module.split(private_module_space)
    modulespace_len = Enum.count(modulespace_segments)

    calling_modules
    |> Enum.flat_map(&validate_call(&1, private_module, modulespace_segments, modulespace_len))
    |> Enum.map(&{private_module, &1})
  end

  defp validate_call(calling_module, called_module, modulespace_segments, modulespace_len) do
    calling_module_segments = Module.split(calling_module)
    valid? = Enum.take(calling_module_segments, modulespace_len) == modulespace_segments

    if valid? do
      []
    else
      [calling_module]
    end
  end

  def handle_cast({:function_call, calling_module, called_module}, state = {function_calls, _}) do
    case :ets.lookup(function_calls, called_module) do
      [] ->
        :ets.insert(function_calls, {called_module, [calling_module]})

      [{^called_module, calling_modules}] ->
        if calling_module not in calling_modules do
          :ets.insert(function_calls, {called_module, [calling_module | calling_modules]})
        end
    end

    {:noreply, state}
  end

  def handle_cast({:register_module, module, module_space}, state = {_, private_modules}) do
    :ok = Agent.update(private_modules, fn acc -> [{module, module_space} | acc] end)

    {:noreply, state}
  end

  defp validate_call(calling_module, called_module, modulespace, modulespace_len) do
    calling_module_segments = Module.split(calling_module)
    valid? = Enum.take(calling_module_segments, modulespace_len) == modulespace

    if valid? do
      []
    else
      [{calling_module, called_module}]
    end
  end

  defp validate_calls(dependants_map, priv_modules) do
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
