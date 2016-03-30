defmodule Helpers do
	@doc """
	Convert a map into a given struct

	Usage: struct_from_map(%{key: "value"}, as: %MyStruct{})
	"""
	@spec struct_from_map(map, as: struct) :: struct
	def struct_from_map(a_map, as: a_struct) do
		# Find the keys within the map
		keys = Map.keys(a_struct) |> Enum.filter(fn x -> x != :__struct__  end)

		# Process map, checking for both string / atom keys
		processed_map =
			for key <- keys, into: %{} do
				value = Map.get(a_map, key) || Map.get(a_map, to_string(key))
				{key, value}
			end

		a_struct = Map.merge(a_struct, processed_map)
		a_struct
	end
end