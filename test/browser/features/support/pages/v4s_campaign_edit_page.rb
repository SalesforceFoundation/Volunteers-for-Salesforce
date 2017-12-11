class V4SCampaignEditPage
  include PageObject

  button(:save_button, name: 'save' )
  text_field(:edit_campaign_name, id: 'cpn1')
end
