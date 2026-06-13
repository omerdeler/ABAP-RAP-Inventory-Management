
CLASS lhc_ProductStock DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR ProductStock RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR ProductStock RESULT result.

    METHODS determineProductDetails FOR DETERMINE ON MODIFY
      IMPORTING keys FOR ProductStock~determineProductDetails.

    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE ProductStock.

ENDCLASS.


CLASS lhc_ProductStock IMPLEMENTATION.

  METHOD get_global_authorizations.
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = if_abap_behv=>auth-allowed.
    ENDIF.
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD determineProductDetails.
    " Fiori ekranından girilen veriyi okuyoruz
    READ ENTITIES OF Z_I_ProductStock_OD IN LOCAL MODE
      ENTITY ProductStock
        FIELDS ( product_id )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_inserted_stocks).

    LOOP AT lt_inserted_stocks ASSIGNING FIELD-SYMBOL(<fs_stock>).
      IF <fs_stock>-product_id IS NOT INITIAL.

        " Ürünün ana verisini çekiyoruz (Adı ve Kategorisi)
        SELECT SINGLE FROM zinv_product_od
          FIELDS product_name, category
          WHERE product_id = @<fs_stock>-product_id
          INTO @DATA(ls_existing_product).

        IF sy-subrc = 0.
          " Sadece isim ve kategori bilgilerini dolduruyoruz
          MODIFY ENTITIES OF Z_I_ProductStock_OD IN LOCAL MODE
            ENTITY ProductStock
              UPDATE FIELDS ( product_name category )
              WITH VALUE #( ( %tky         = <fs_stock>-%tky
                              product_name = ls_existing_product-product_name
                              category     = ls_existing_product-category ) )
              REPORTED DATA(lt_reported).
        ENDIF.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD precheck_create.
    " 1. Ön yüzden girilen verileri okuyoruz
    READ ENTITIES OF Z_I_ProductStock_OD IN LOCAL MODE
      ENTITY ProductStock
        FIELDS ( product_id )
        WITH CORRESPONDING #( entities )
      RESULT DATA(lt_checked_entities).

    LOOP AT lt_checked_entities ASSIGNING FIELD-SYMBOL(<fs_entity>).
      IF <fs_entity>-product_id IS NOT INITIAL.

        " 2. Veritabanında bu ürüne ait mükerrer kayıt var mı kontrolü
        SELECT SINGLE FROM zinv_stock_od
          FIELDS stock_id
          WHERE product_id = @<fs_entity>-product_id
          INTO @DATA(ls_existing_stock).

        IF sy-subrc = 0.
          " Ürün varsa failed tablosuna ekleyerek kaydı engelliyoruz
          APPEND VALUE #( %cid = entities[ sy-tabix ]-%cid
                          %key = <fs_entity>-%key ) TO failed-productstock.

          "" Sistem uyuşmazlıklarını bypass etmek için mesaj nesnesini doğrudan el ile dolduruyoruz:
          APPEND VALUE #(
              %cid                = entities[ sy-tabix ]-%cid
              %key                = <fs_entity>-%key
              %element-product_id = if_abap_behv=>mk-on
            ) TO reported-productstock.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
