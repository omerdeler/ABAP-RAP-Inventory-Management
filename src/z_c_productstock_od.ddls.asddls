@EndUserText.label: 'Urun ve Stok Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define root view entity Z_C_ProductStock_OD
  provider contract transactional_query
  as projection on Z_I_ProductStock_OD
{
    key stock_id,
    
        product_id,
        product_name,
        category,
        base_unit,
        min_stock_level,
        @Semantics.quantity.unitOfMeasure: 'unit'
        total_quantity,
        unit,           
        last_updated_at, 
        StockStatus
}
