
defmodule ExPrivModules.Tracer do
    @spec trace(tuple, Macro.Env.t()) :: :ok
    def trace({:remote_function, _meta, module, _, _}, env) do
      ExPrivModules.Validator.add_function_call(env.module, module)
      :ok
    end
  
    @spec trace(tuple, Macro.Env.t()) :: :ok
    def trace({:on_module, _, _}, env) do
      module_space = Module.get_attribute(env.module, :module_private)
  
      if module_space do
        ExPrivModules.Validator.add_private_module(env.module, module_space)
      end
  
      :ok
    end
  
    def trace(_, _) do
      :ok
    end
  end