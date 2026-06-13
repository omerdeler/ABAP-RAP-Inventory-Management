
CLASS lhc_Product DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Product RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Product RESULT result.
ENDCLASS.




CLASS lhc_Product IMPLEMENTATION.
  METHOD get_instance_authorizations.
    " İçinin boş kalması test ortamında güncelleme/silme için tam yetki verir.
  ENDMETHOD.

  METHOD get_global_authorizations.
    " KİLİT NOKTA: Create butonunun ekrana gelmesi için sisteme "HERKESE YARATMA YETKİSİ VER" diyoruz.
    result = VALUE #( %create = if_abap_behv=>auth-allowed ).
  ENDMETHOD.
ENDCLASS.
