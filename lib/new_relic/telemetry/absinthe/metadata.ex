defmodule NewRelic.Telemetry.Absinthe.Metadata do
  def resolver_name(middleware) do
    Enum.find_value(middleware, fn
      {{Absinthe.Resolution, :call}, resolver_fn} ->
        info = Function.info(resolver_fn)

        case Keyword.get(info, :type) do
          :external -> inspect(resolver_fn)
          :local -> "&#{inspect(info[:module])}.anonymous/#{info[:arity]}"
        end

      {{middleware, :call}, _options} ->
        inspect({middleware, :call})

      _ ->
        nil
    end)
  end

  def operation_span_name(%{type: type, name: name}) when is_binary(name) do
    "#{to_string(type)}:#{name}"
  end

  def operation_span_name(%{type: type}) do
    "#{to_string(type)}"
  end

  def transaction_name(schema, operation) do
    "Absinthe/#{inspect(schema)}/#{operation.type}/" <>
      Enum.join(NewRelic.Telemetry.Absinthe.Metadata.collect_deepest_path(operation), ".")
  end

  def collect_deepest_path(%{type: :mutation, selections: [%{name: name} | _]}) do
    [name]
  end

  def collect_deepest_path(%{type: :subscription, selections: [%{name: name} | _]}) do
    [name]
  end

  def collect_deepest_path(%{type: :query, selections: [selection]}) do
    collect_deepest_path(selection, [])
  end

  def collect_deepest_path(%{type: :query}) do
    []
  end

  def collect_deepest_path(%{selections: selections, name: name}, acc) do
    selections
    |> Enum.reject(fn
      %{name: "__typename"} -> true
      _ -> false
    end)
    |> case do
      [selection] -> collect_deepest_path(selection, acc ++ [name])
      _ -> acc ++ [name]
    end
  end

  def collect_deepest_path(_, acc) do
    acc
  end
end
