defmodule RecStruct do
  @moduledoc """
  Documentation for RecStruct.
  """

  defmacro defheader(modName, filePath, do: expr) do
    extractedRecords = Record.extract_all(from: filePath)
    allRecords = for {recName, fields} <- extractedRecords do quote do Record.defrecord(unquote(recName), unquote(fields)) end end

    transformedExpr = Macro.prewalk(expr, 
    fn ({:defrecstruct, meta, [par1, recordName]}) -> 
        {:defrecstruct, meta, [par1, recordName, [fields: extractedRecords[recordName]]]}
      ({:defrecstruct, meta, [par1, recordName, otherParams]}) -> 
        {:defrecstruct, meta, [par1, recordName, otherParams ++ [fields: extractedRecords[recordName]]]}
      (otherwise) -> otherwise
    end)

    quote do      
      defmodule unquote(modName) do
        defmodule Records do
          require Record
          unquote(allRecords)
        end
        
        defmodule Structures do
          require Records
          import Records
          
          unquote(transformedExpr)
        end
      end     
    end    
  end

  defmacro defrecstruct(msgName, recordName, opts \\ []) do
    recordFields = case Access.get(opts, :convert_undefined, true) do
      true ->
        for {key, val} <- opts[:fields] do 
          {key, case val do 
            :undefined -> nil
            val -> val
          end} 
        end
      false -> 
        opts[:fields]
      _ -> 
        raise ArgumentError, "Wrong value for :convert_undefined. Only true or false allowed"
    end

    keyValForRecords = case Access.get(opts, :convert_undefined, true) do
      true ->
        for {key, _defaultVal} <- recordFields do 
          {key, quote do 
            case Map.get(struct, unquote(key)) do
              nil -> :undefined
              val -> val
            end
          end} 
        end
      false ->
        for {key, _defaultVal} <- recordFields do {key, quote do Map.get(struct, unquote(key)) end} end
    end

    keyValForStructs = case Access.get(opts, :convert_undefined, true) do
      true ->
        for {key, _defaultVal} <- recordFields do 
          {key, quote do 
            case unquote(recordName)(record, unquote(key)) do
              :undefined -> nil
              val -> val
            end      
          end} 
        end
      false ->
      for {key, _defaultVal} <- recordFields do {key, quote do unquote(recordName)(record, unquote(key)) end} end
    end

    quote do
      defmodule unquote(msgName) do
        defstruct unquote(recordFields)
      end

      def to_record(%unquote(msgName){} = struct) do
        unquote(recordName)(unquote(keyValForRecords))          
      end        

      def to_struct(unquote(recordName)() = record) do
        struct(unquote(msgName), unquote(keyValForStructs))
      end
    end
  end
end

