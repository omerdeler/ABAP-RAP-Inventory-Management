CLASS zcl_inv_data_gen_od DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_inv_data_gen_od IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    DATA: lt_products  TYPE TABLE OF zinv_product_od,
          lt_stocks    TYPE TABLE OF zinv_stock_od,
          lv_timestamp TYPE timestampl,
          lv_uuid1     TYPE sysuuid_x16,
          lv_uuid2     TYPE sysuuid_x16,
          lv_uuid3     TYPE sysuuid_x16.

    " Eski verileri tamamen temizle
    DELETE FROM zinv_product_od.
    DELETE FROM zinv_stock_od.

    GET TIME STAMP FIELD lv_timestamp.

    " Ana Ürün Verileri
    lt_products = VALUE #(
      ( client = sy-mandt product_id = 'IPHONE15'  product_name = 'iPhone 15 Pro'          category = 'Elektronik' base_unit = 'ST' min_stock_level = '10' )
      ( client = sy-mandt product_id = 'MACBOOK_M3' product_name = 'MacBook Air M3'         category = 'Elektronik' base_unit = 'ST' min_stock_level = '5' )
      ( client = sy-mandt product_id = 'MACBOOK_M4' product_name = 'MacBook Air M4'         category = 'Elektronik' base_unit = 'ST' min_stock_level = '10' )
      ( client = sy-mandt product_id = 'LOGI_MX'    product_name = 'Logitech MX Master Mouse' category = 'Aksesuar'   base_unit = 'ST' min_stock_level = '20' )
    ).
    INSERT zinv_product_od FROM TABLE @lt_products.

    TRY.
        " UUID'leri güvenli bir şekilde değişkenlere üretiyoruz (Sıfır kalmasını önlemek için)
        lv_uuid1 = cl_system_uuid=>create_uuid_x16_static( ).
        lv_uuid2 = cl_system_uuid=>create_uuid_x16_static( ).
        lv_uuid3 = cl_system_uuid=>create_uuid_x16_static( ).

        lt_stocks = VALUE #(
          ( client           = sy-mandt
            stock_id         = lv_uuid1
            product_id       = 'IPHONE15'
            total_quantity   = '50'
            unit             = 'ST'
            last_updated_at  = lv_timestamp )

          ( client           = sy-mandt
            stock_id         = lv_uuid2
            product_id       = 'MACBOOK_M3'
            total_quantity   = '3'
            unit             = 'ST'
            last_updated_at  = lv_timestamp )

          ( client           = sy-mandt
            stock_id         = lv_uuid3
            product_id       = 'LOGI_MX'
            total_quantity   = '100'
            unit             = 'ST'
            last_updated_at  = lv_timestamp )
        ).

        INSERT zinv_stock_od FROM TABLE @lt_stocks.
        out->write( 'Urunler ve Stoklar GERÇEK UUID ve zaman damgasiyla basariyla yuklendi!' ).

      CATCH cx_uuid_error.
        out->write( 'UUID uretim hatasi.' ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
