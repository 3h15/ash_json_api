defmodule AshJsonApi.Controllers.GetManyToMany do
  alias AshJsonApi.Paginator

  def init(options) do
    # initialize options
    options
  end

  def call(%{path_params: %{"id" => id}} = conn, options) do
    resource = options[:resource]
    relationship = options[:relationship]
    related_resource = relationship.destination

    with {:ok, request} <- AshJsonApi.Request.from(conn, related_resource, :get_many_to_many),
         {:record, {:ok, record}} when not is_nil(record) <-
           {:record, Ash.get_by_id(resource, id)},
         {:ok, query} <- Ash.relationship_query(related_resource, relationship),
         {:ok, %Paginator{query: query} = paginator} <-
           AshJsonApi.Paginator.paginate(request, query),
         {:run_query, {:ok, related}} <- {:run_query, Ash.get_many(query, related_resource)},
         {:ok, found, includes} <- AshJsonApi.Includes.Includer.get_includes(related, request) do
      serialized = AshJsonApi.Serializer.serialize_many(request, paginator, found, includes)

      conn
      |> Plug.Conn.put_resp_content_type("application/vnd.api+json")
      |> Plug.Conn.send_resp(200, serialized)
    else
      {:error, error} ->
        raise "whups: #{inspect(error)}"

      {:run_query, {:error, error}} ->
        raise "whups: #{inspect(error)}"

      {:record, nil} ->
        conn
        # |> put_resp_content_type("text/plain")
        |> Plug.Conn.send_resp(404, "uh oh")
    end
    |> Plug.Conn.halt()
  end
end
