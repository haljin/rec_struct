defmodule RecStructTest do
  use ExUnit.Case

  defmodule TestStructs do
    require RecStruct
    import RecStruct

    defheader TestHeader,  "test/test.hrl" do
      defmsg TestRec, :test_record
      defmsg OtherTestRec, :other_test_record, convert_undefined: false
    end
  end

  test "Converting structures to records" do
    alias TestStructs.TestHeader.Structures, as: St
    alias TestStructs.TestHeader.Records, as: Rec
    require Rec

    assert Rec.test_record() == St.to_record(%St.TestRec{})
    assert Rec.test_record(St.to_record(%St.TestRec{}), :other_field) == :undefined
    assert %St.TestRec{}.a_field == 15
    assert %St.TestRec{}.other_field == nil
  end

  test "Converting records to structures" do
    alias TestStructs.TestHeader.Structures, as: St
    alias TestStructs.TestHeader.Records, as: Rec
    require Rec

    assert St.to_struct(Rec.test_record()) == %St.TestRec{}
    assert St.to_struct(Rec.test_record()).other_field == nil
    assert Rec.test_record(Rec.test_record(), :a_field) == 15
    assert Rec.test_record(Rec.test_record(), :other_field) == :undefined
  end

  test "Modifying values is transferred" do
    alias TestStructs.TestHeader.Structures, as: St
    alias TestStructs.TestHeader.Records, as: Rec
    require Rec
    
    assert St.to_struct(Rec.test_record(other_field: :some_atom)) == %St.TestRec{other_field: :some_atom}
    assert Rec.test_record(other_field: :some_atom) == St.to_record(%St.TestRec{other_field: :some_atom})
  end

  test "convert_undefined: false makes structures preserve undefined" do
    alias TestStructs.TestHeader.Structures, as: St
    alias TestStructs.TestHeader.Records, as: Rec
    require Rec

    assert St.to_struct(Rec.other_test_record()) == %St.OtherTestRec{}
    assert St.to_struct(Rec.other_test_record()).b == :undefined
    assert Rec.other_test_record(St.to_record(St.to_struct(Rec.other_test_record())), :b) ==  :undefined
  end

end
