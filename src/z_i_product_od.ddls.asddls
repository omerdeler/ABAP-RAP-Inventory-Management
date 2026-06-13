@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Product Interface View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true


define root view entity Z_I_PRODUCT_OD 
    as select from zinv_product_od
    

{
    
  key product_id      as ProductId,
      product_name    as ProductName,
      category        as Category,
      base_unit       as BaseUnit,
      
      @Semantics.quantity.unitOfMeasure: 'BaseUnit'
      min_stock_level as MinStockLevel,
      last_updated_at
       
}
