defmodule ExampleCaller do
    def something() do
        Example.a_method()
    end

    def something_else() do
        Example.PrivMod.a_method()
    end
end