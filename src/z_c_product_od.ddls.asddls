@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Product Projection View'
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['ProductId']


define root view entity Z_C_PRODUCT_OD
    provider contract transactional_query
    as projection on Z_I_PRODUCT_OD
    
{
    @Search.defaultSearchElement: true
    @Search.fuzzinessThreshold: 0.8
    key ProductId,
    
    
    @Search.defaultSearchElement: true
    @Search.fuzzinessThreshold: 0.8
    ProductName,
    
    Category,
    BaseUnit,
    
    @Semantics.quantity.unitOfMeasure: 'BaseUnit'
    MinStockLevel
}
