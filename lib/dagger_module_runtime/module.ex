defmodule Dagger.ModuleRuntime.Helper do
  def camelize(name) do
    name |> to_string() |> Macro.camelize()
  end
end

defmodule Dagger.ModuleRuntime.Function do
  alias Dagger.ModuleRuntime.Helper

  def define_functions(type_def, dag, module)
      when is_struct(type_def, Dagger.TypeDef) and is_struct(dag, Dagger.Client) and
             is_atom(module) do
    funs =
      Module.get_attribute(module, :functions)
      |> Enum.map(&define_function(dag, &1))

    Enum.reduce(
      funs,
      type_def,
      &Dagger.TypeDef.with_function(&2, &1)
    )
  end

  defp define_function(dag, fun_def) do
    name = Keyword.fetch!(fun_def, :name)
    # args = fun_def[:args] || []
    return = Keyword.fetch!(fun_def, :return)

    # TODO: function doc by retrieving from `@doc`.
    # TODO: optional parameter
    dag
    |> Dagger.Client.function(Helper.camelize(name), fun_return(dag, return))
  end

  defp fun_return(dag, type) do
    return_type_def =
      dag
      |> Dagger.Client.type_def()

    case type do
      :string ->
        return_type_def
        |> Dagger.TypeDef.with_kind(Dagger.TypeDefKind.string_kind())

      module ->
        case Module.split(module) do
          # A module that generated by codegen.
          ["Dagger", name] ->
            return_type_def
            |> Dagger.TypeDef.with_object(name)

          [name] ->
            return_type_def
            |> Dagger.TypeDef.with_object(name)
        end
    end
  end
end

defmodule Dagger.ModuleRuntime.Module do
  alias Dagger.ModuleRuntime.Function
  alias Dagger.ModuleRuntime.Helper

  def define_module(dag, module) when is_struct(dag, Dagger.Client) and is_atom(module) do
    dag
    |> Dagger.Client.module()
    |> Dagger.Module.with_object(define_object(dag, module))
  end

  defp define_object(dag, module) do
    dag
    |> Dagger.Client.type_def()
    |> Dagger.TypeDef.with_object(Helper.camelize(module))
    |> Function.define_functions(dag, module)
  end
end
