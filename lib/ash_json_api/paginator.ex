defmodule AshJsonApi.Paginator do
  defstruct [:limit, :results, :total, offset: 0]
end
