defmodule RecStruct do
  @moduledoc """
  This module contains all of the macros that allow defining Erlang header files containing records as well as records strutures themselves.
  """

  @type recstructOptions :: {:convert_undefined, boolean}

  @doc """
  Defines an Erlang header file that is meant to be imported. The header defines the name of the module that will be generated containing all
  record and structure definitions and the path to the Erlang header file to be read.

      defheader MyModule, "include/path_to_header/header.hrl", do

      end

  This will create three modules. `MyModule` as the umbrella module, `MyModule.Records` containing the record generation macros (such as made by `Record.defrecord`)
  and `MyModule.Structures` which will house all the Elixir structures and conversion functions.
  """
  @spec defheader(module, Path.t, [term]) :: none
  defmacro defheader(modName, filePath, do: expr) do
    extractedRecords = Record.extract_all(from: filePath)
    
    allRecords = for {recName, fields} <- extractedRecords do
      quote do Record.defrecord(unquote(recName), unquote(Macro.escape(fields))) end end

    transformedExpr = Macro.prewalk(expr, 
    fn ({:defrecstruct, meta, [par1, recordName]}) -> 
        {:defrecstruct, meta, [par1, recordName, [fields: extractedRecords[recordName]]]}
      ({:defrecstruct, meta, [par1, recordName, otherParams]}) -> 
        {:defrecstruct, meta, [par1, recordName, otherParams ++ [fields: extractedRecords[recordName]]]}
      (otherwise) -> otherwise
    end)

    quote do      
      defmodule unquote(modName) do
        @moduledoc false
        defmodule Records do
          @moduledoc false
          require Record
          unquote(allRecords)
        end
        
        defmodule Structures do
          @moduledoc false
          require Records
          import Records
          
          unquote(transformedExpr)
        end
      end     
    end    
  end

  @doc """
  Defines a record structure together with its conversion functions. 
  
  A record structures requires an Elixir module name which the structure will be defined in and an atom denoting the 
  Erlang record name that will be mapped to the structure. Optional parameters can be passed into the definition. `defrecstruct` 
  can only be defined inside a `defheader` block. 

  Doing:

      defmodule TestStructs do
        require RecStruct
        import RecStruct

        defheader TestHeader, "test/test.hrl" do
          defrecstruct TestRec, :test_record
          defrecstruct OtherTestRec, :other_test_record, convert_undefined: false
        end
      end

  will generate two structures inside the `TestStructs` module: `TestHeader.Structures.TestRec` which maps to the `:my_record` Erlang record 
  and `TestHeader.Structures.OtherTestRec` that maps to the `:my_other_record` record. It will also defined two functions `TestHeader.Structures.to_struct/1` 
  and `TestHeader.Structures.to_record/1` that can convert between the two data types and should be used on the interaction point between Erlang and Elixir code.

  It can be used in the following way:

      iex> alias RecStructTest.TestStructs.TestHeader
      iex> st = %TestHeader.Structures.TestRec{}
      iex> TestHeader.Structures.to_record(st)
      {:test_record, 15, :undefined}

      iex> alias RecStructTest.TestStructs.TestHeader
      iex> require TestHeader.Records
      iex> rec = TestHeader.Records.test_record()
      iex> TestHeader.Structures.to_struct(rec)
      %RecStructTest.TestStructs.TestHeader.Structures.TestRec{}

  ### Options
  The `:convert_undefined` option selects whether the value of `:undefined` in the record should be converted to `nil` in the structure and vice versa. E.g.

      iex> alias RecStructTest.TestStructs.TestHeader
      iex> require TestHeader.Records
      iex> rec = TestHeader.Records.test_record()
      iex> TestHeader.Records.test_record(rec, :other_field)
      :undefined
      iex> st = TestHeader.Structures.to_struct(rec)
      iex> st.other_field
      nil

      iex> alias RecStructTest.TestStructs.TestHeader
      iex> require TestHeader.Records     
      iex> st = %TestHeader.Structures.TestRec{}
      iex> st.other_field
      nil
      iex> rec = TestHeader.Structures.to_record(st)
      iex> TestHeader.Records.test_record(rec, :other_field)
      :undefined

  If `false` is provided, this will not be done and `:undefined` will be seen in the structures.

  Defaults to `true`
  """
  @spec defrecstruct(module, atom, [recstructOptions]) :: none
  defmacro defrecstruct(msgName, recordName, opts \\ []) do
    if opts[:fields] == nil, do: raise ArgumentError, "Undefined or invalid record name. Got #{inspect recordName}"
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
        @moduledoc false
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

