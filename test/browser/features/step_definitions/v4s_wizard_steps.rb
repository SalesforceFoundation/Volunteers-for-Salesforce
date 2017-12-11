Given(/^I am on the Volunteers Wizard Page$/) do
  on(V4SMainPage).volunteers_wizard_link
end

When(/^I create a new campaign with jobs and shifts$/) do
  on(V4SWizardPage) do |page|
    page.campaign_name_element.when_present.send_keys "Test Campaign #{@random_string}"
    page.active_checkbox_element.click
    page.number_sample_jobs= '2'
    page.number_sample_shifts= '3'
    page.save_button
  end
end

When(/^I clone the campaign I just created$/) do
  on(V4SWizardPage).clone_button
end

Then(/^the clone campaign should refresh$/) do
  on(V4SCampaignEditPage) do |page|
    page.edit_campaign_name.clear
    page.edit_campaign_name_element.send_keys "Clone Campaign #{@random_string}"
    page.save_button
  end
  on(V4SCampaignDetailPage) do |page|
    expect(page.campaign_name_element.visible?).to be(true)
    expect(page.campaign_name).to include 'Clone Campaign'
  end
end
