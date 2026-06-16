CLASS lhc_ProductStock DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR ProductStock RESULT result.

    METHODS determineProductDetails FOR DETERMINE ON MODIFY
      IMPORTING keys FOR ProductStock~determineProductDetails.

    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE ProductStock.

    METHODS validateQuantity FOR VALIDATE ON SAVE
      IMPORTING keys FOR ProductStock~validateQuantity.

    METHODS sendInventoryReport FOR MODIFY
      IMPORTING keys FOR ACTION ProductStock~sendInventoryReport.
ENDCLASS.


CLASS lhc_ProductStock IMPLEMENTATION.

  METHOD get_global_authorizations.
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = if_abap_behv=>auth-allowed.
    ENDIF.
  ENDMETHOD.


  METHOD determineProductDetails.
    " 1. Fiori ekranından girilen güncel verileri (miktarı ve ürün id'sini) okuyoruz
    READ ENTITIES OF Z_I_ProductStock_OD IN LOCAL MODE
      ENTITY ProductStock
        FIELDS ( product_id total_quantity )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_inserted_stocks).

    LOOP AT lt_inserted_stocks ASSIGNING FIELD-SYMBOL(<fs_stock>).
      IF <fs_stock>-product_id IS NOT INITIAL.

        " 2. Ürünün asgari stok seviyesini, adını ve kategorisini çekiyoruz
        SELECT SINGLE FROM zinv_product_od
          FIELDS product_name, category, min_stock_level
          WHERE product_id = @<fs_stock>-product_id
          INTO @DATA(ls_product_info).

        IF sy-subrc = 0.
          " 3. Statüyü ve Renk Kodunu hesaplama mantığı
          DATA(lv_status) = VALUE string( ).
          DATA(lv_criticality) = VALUE i( ).

          IF <fs_stock>-total_quantity IS INITIAL OR <fs_stock>-total_quantity = 0.
            lv_status = 'STOK YOK'.
            lv_criticality = 1. " Kırmızı
          ELSEIF <fs_stock>-total_quantity <= ls_product_info-min_stock_level.
            lv_status = 'KRITIK'.
            lv_criticality = 2. " Sarı
          ELSE.
            lv_status = 'NORMAL'.
            lv_criticality = 3. " Yeşil
          ENDIF.

          " 4. Ekrandaki alanları canlı olarak güncelliyoruz
          MODIFY ENTITIES OF Z_I_ProductStock_OD IN LOCAL MODE
            ENTITY ProductStock
              UPDATE FIELDS ( product_name category StockStatus StockCriticality )
              WITH VALUE #( ( %tky             = <fs_stock>-%tky
                              product_name     = ls_product_info-product_name
                              category         = ls_product_info-category
                              StockStatus      = lv_status
                              StockCriticality = lv_criticality ) )
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

          APPEND VALUE #(
              %cid                = entities[ sy-tabix ]-%cid
              %key                = <fs_entity>-%key
              %element-product_id = if_abap_behv=>mk-on
            ) TO reported-productstock.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD validateQuantity.
    " 1. Ekrangaki güncel stok verilerini okuyoruz
    READ ENTITIES OF Z_I_ProductStock_OD IN LOCAL MODE
      ENTITY ProductStock
        FIELDS ( total_quantity product_id )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_stocks).

    LOOP AT lt_stocks ASSIGNING FIELD-SYMBOL(<fs_stock>).
      " 2. Eğer girilen stok miktarı 0'dan küçükse (Negatifse)
      IF <fs_stock>-total_quantity < 0.

        " Failed tablosuna ekleyerek Fiori'nin kaydetmesini blokluyoruz
        APPEND VALUE #( %tky = <fs_stock>-%tky ) TO failed-productstock.

        APPEND VALUE #(
            %tky                    = <fs_stock>-%tky
            %element-total_quantity = if_abap_behv=>mk-on " Hata alanını kırmızıya boyar
            %msg                    = new_message_with_text(
                                        severity = if_abap_behv_message=>severity-error
                                        text     = 'Stok miktarı negatif bir değer olamaz!' )
          ) TO reported-productstock.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.



    METHOD sendInventoryReport.
        " 1. Girdiyi güvenle okuyoruz (Patronun Mail Adresi)
        DATA(lv_boss_email) = keys[ 1 ]-%param-email_address.

        " 2. SIMÜLASYON VE LOGLAMA
        " Gerçek hayatta bulut kısıtlaması olmadığında HTTP API'ye gidecek olan JSON içeriğini
        " debug ekranında veya sistem loglarında görebilmek için hazırlıyoruz.
        DATA(lv_simulated_json) = |\{ "to": "{ lv_boss_email }", "subject": "Depo Stok Giriş Raporu", "body": "Sayın Yöneticim, depoya yeni mal girişi başarıyla yapılmıştır." \}|.

        " 3. KULLANICIYA GERİ BİLDİRİM
        " Fiori ön yüzündeki kullanıcımıza sürecin başarıyla tetiklendiğini bildiren
        " standart RAP mesaj mekanizmasını çalıştırıyoruz.
        APPEND VALUE #( %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-success
                                 text     = |[SIMÜLASYON] Envanter raporu başarıyla hazırlandı ve '{ lv_boss_email }' adresine gönderilmek üzere sıraya alındı!| )
                      ) TO reported-productstock.

  ENDMETHOD.


*  METHOD sendInventoryReport.
*    " 1. Girdiyi güvenle okuyoruz (Patronun Mail Adresi)
*    DATA(lv_boss_email) = keys[ 1 ]-%param-email_address.
*
*    TRY.
*        " 2. BTP Cockpit'te yarattığımız 'SAP_SMTP_SERVER' isimli Destination'ı çağırıyoruz
*        DATA(lo_http_destination) = cl_http_destination_provider=>create_by_cloud_destination(
*                              i_name       = 'SAP_SMTP_SERVER'
*                              i_authn_mode = if_a4c_cp_service=>service_specific
*                            ).
*
*        " 3. HTTP Client nesnesini oluşturuyoruz
*        DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( i_destination = lo_http_destination ).
*        DATA(lo_http_request) = lo_http_client->get_http_request( ).
*
*        " 4. İstek başlıklarını ve gövdesini (Mail içeriğini) hazırlıyoruz
*        lo_http_request->set_header_field( i_name = 'Content-Type' i_value = 'application/json' ).
*
*        DATA(lv_json_body) = |\{ "to": "{ lv_boss_email }", "subject": "Envanter Durumu", "body": "Güncel Envanter durumu ekte sunulmuştur." \}|.
*        lo_http_request->set_text( lv_json_body ).
*
*        " 5. İsteği POST metoduyla uçuruyoruz
*        DATA(lo_http_response) = lo_http_client->execute( i_method = if_web_http_client=>post ).
*
*        " 6. Başarılı ise kullanıcıya Fiori üzerinden yeşil bildirim veriyoruz
*        APPEND VALUE #( %msg = new_message_with_text(
*                                 severity = if_abap_behv_message=>severity-success
*                                 text     = |Envanter raporu '{ lv_boss_email }' adresine başarıyla gönderildi!| )
*                      ) TO reported-productstock.
*
*      CATCH cx_root INTO DATA(lx_mail_error).
*        " Bağlantıda bir hata oluşursa sistemin çökmesini (Dump) engelleyip uyarı basıyoruz
*        APPEND VALUE #( %msg = new_message_with_text(
*                                 severity = if_abap_behv_message=>severity-warning
*                                 text     = |Bağlantı hatası: { lx_mail_error->get_text( ) }| )
*                      ) TO reported-productstock.
*    ENDTRY.
*  ENDMETHOD.

ENDCLASS.

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

