# rec_struct
[![Build Status](https://travis-ci.org/haljin/rec_struct.svg?branch=master)](https://travis-ci.org/haljin/rec_struct) [![Hex.pm Version](http://img.shields.io/hexpm/v/rec_struct.svg?style=flat)](https://hex.pm/packages/rec_struct)


Erlang record to Elixir structure converter. Allows for simple defining of Elixir structures that automatically map to Erlang records imported from a header file.

## Installation

The package is [available in Hex](https://hex.pm/packages/rec_struct) and can be installed
by adding `rec_struct` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rec_struct, "~> 0.2.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc). 
The documentation can also be found at [https://hexdocs.pm/rec_struct](https://hexdocs.pm/rec_struct).

## Usage

To use record structures first the header file, from which the Erlang records will be imported, must be defined. That is done using the `defheader` macro:

```elixir
defheader MyModule, "include/path_to_header/header.hrl", do
(...)
end
```

This will import the header and use `Record.defrecord` to define the macros that can be used to build and manipulate records directly in the `MyModule.Records` module 
that will be generated.

With the header imported now each individual record can be imported and mapped to an Elixir structure by using:

```elixir
defheader TestHeader, "test/test.hrl" do
  defrecstruct TestRec, :test_record
  defrecstruct OtherTestRec, :other_test_record
end
```

This will define two structures in `TestHeader.Structures.TestRec` and `TestHeader.Structures.OtherTestRec` modules. Additionally two functions will be defined in
`TestHeader.Structures`:

* `to_struct/1` which transforms an Erlang record (tuple) to the appropriate Elixir structure
* `to_record/1` which transforms and Elixir structure into a record.

Please see the [documentation](https://hexdocs.pm/rec_struct) for more information and examples.

## Note

Currently the `defheader` and `defrectstruct` macros only work correctly if `RecStruct` module is imported!

