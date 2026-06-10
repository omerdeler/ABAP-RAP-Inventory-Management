@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Envanter Root View'
@Metadata.allowExtensions: true

define root view entity Z_I_ProductStock_OD
  as select from zinv_stock_od as Stock
  
  association [0..1] to zinv_product_od as _Product
    on $projection.product_id = _Product.product_id
{
  key Stock.stock_id,

      // Sisteminin tam uyumla kabul ettiği standart F4 Arama Yardımı tanımı:
      @Consumption.valueHelpDefinition: [{ entity: { name: 'Z_I_PRODUCT_HELP', element: 'product_id' } }]
      Stock.product_id,

      @Semantics.quantity.unitOfMeasure: 'unit'
      Stock.total_quantity,
      Stock.unit,
      Stock.last_updated_at,

      // Alanları doğrudan _Product tablosundan alarak 'Unknown' çakışmalarını önlüyoruz:
      _Product.product_name as product_name,
      _Product.category     as category,
      _Product.base_unit,
      _Product.min_stock_level,

      case
        when Stock.total_quantity <= _Product.min_stock_level then 'KRITIK'
        when Stock.total_quantity is null then 'STOK YOK'
        else 'NORMAL'
      end                   as StockStatus,

      _Product
}
