@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Ürün Arama Yardımı CDS'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS // Bu kod F4'ün doğrudan açılır kutu (Dropdown) olmasını sağlar

define view entity Z_I_PRODUCT_HELP
  as select from zinv_product_od
{
      @EndUserText.label: 'Ürün Kodu'
  key product_id,
      @EndUserText.label: 'Ürün Adı'
      product_name,
      @EndUserText.label: 'Kategori'
      category
}
