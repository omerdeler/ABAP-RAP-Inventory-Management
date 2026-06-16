CLASS z_test_mail_od DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.



CLASS z_test_mail_od IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    DATA(lo_mail) = cl_bcs_mail_message=>create_instance( ).

  ENDMETHOD.

ENDCLASS.
