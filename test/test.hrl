-record(test_record, {a_field = 15,
                      other_field}).  

-record(other_test_record, {something = "test",
                            b,
                            c}).

-record(record_with_subrecord, {my_field = 13487,
                                field_with_record = #test_record{}}).

