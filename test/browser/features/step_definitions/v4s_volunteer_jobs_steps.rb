Given(/^I create a Campaign named "([^"]*)"$/) do |camp_name|
  create_campaign(camp_name)
end

Given(/^I fill in Volunteer Job Name$/) do
  on(V4SJobsPage) do |page|
    page.new_button
    page.job_name = "data analyst#{@random_string}"
    end
  end
Given(/^I find my Campaign using "([^"]*)"$/) do |camp_name1|
  on(V4SJobsPage).opp_name_element.send_keys "#{camp_name1} #{@random_string}"
end

Given(/^I navigate to Volunteer Jobs$/) do
  on(V4SMainPage).volunteer_jobs_link_element.when_present.click
end

When(/^I add a description$/) do
  on(V4SJobsPage).description_element.send_keys "description information #{@random_string}"
end

When(/^I check the skills$/) do
  on(V4SJobsPage) do |page|
    page.skills_select = 'Computer usage'
    page.add_select_element.click
  end
end

When(/^I click checkboxes$/) do
  on(V4SJobsPage) do |page|
    page.check_ongoing_box
    page.check_inactive_box
    page.check_display_box
  end
end

When(/^I click Save$/) do
  on(V4SJobsPage).save_button
end

When(/^I set the timezone$/) do
  on(V4SJobsPage) do |page|
    timezone_array = page.timezone_select_options
    @description_timezone = timezone_array[2]
    page.timezone_select = @description_timezone
  end
end

When(/^I fill in location fields$/) do
  on(V4SJobsPage) do |page|
    page.street_field = "minecraft #{@random_string}"
    page.city_field = "village #{@random_string}"
    page.state_field = "texas #{@random_string}"
    page.zip_code_field = "12345#{@random_string}"
  end
end

When(/^I fill in location information$/) do
  on(V4SJobsPage).location_description_element.send_keys "location information #{@random_string}"
end

Then(/^I should see complete description saved$/) do
  on(V4SJobsPage) do |page|
    expect(page.first_check_element.visible?).to be true
    expect(page.second_check_element.visible?).to be true
    expect(page.third_check_element.visible?).to be true
    expect(page.description_zone_element.text).to match /#{@description_timezone}.+Computer usage.+description information #{@random_string}/m
  end
end

Then(/^I should see location information saved$/) do
  expect(on(V4SJobsPage).location_table).to match /minecraft #{@random_string}.+village #{@random_string}.+texas #{@random_string}.+12345#{@random_string}.+location information #{@random_string}/m
end


Then(/^I should see my Volunteer Job$/) do
  on(V4SJobsPage) do |page|
    expect(page.title).to eq "data analyst#{@random_string}"
    expect(page.header).to eq "Volunteer Job Detail"
    expect(page.job_name).to eq "data analyst#{@random_string}"
    expect(page.campaign_link_element.text).to eq "Test Campaign #{@random_string}"
  end
end
