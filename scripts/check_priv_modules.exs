[{ExPrivModules.Validator, _}] = Code.compile_file(to_string(:code.priv_dir(:ex_privmodules)) <> "/validator.exs")
[{ExPrivModules.Tracer, _}] = Code.compile_file(to_string(:code.priv_dir(:ex_privmodules)) <> "/tracer.exs")

require Logger

Mix.Task.clear()
{:ok, _} = ExPrivModules.Validator.start_link()
Mix.Task.run("compile", ["--force", "--tracer", ExPrivModules.Tracer])

case ExPrivModules.Validator.evaluate() do
  :ok ->
    Logger.info("All private module calls are valid")
    System.halt(0)

  {:error, errors} ->
    Logger.error("Failed to compile: following errors: #{inspect(errors)}")
    Process.sleep(50)
    System.halt(1)
end
