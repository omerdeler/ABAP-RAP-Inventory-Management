@EndUserText.label: 'Mail Gönderimi İçin Abstract Parametre Yapısı'

define abstract entity Z_A_MailParameter_OD
{
  @EndUserText.label: 'Alıcı E-Posta Adresi'
  email_address : abap.char( 255 );
}
