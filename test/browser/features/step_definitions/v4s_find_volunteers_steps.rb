Given(/^I click my volunteer$/) do
  on(V4SFindVolunteersPage)do |page|
    page.spinner_element.when_not_present
    page.check_found_box
  end
end

Given(/^I create a Contact with V(\d+)S criteria$/) do |arg1|
  create_contact_with_criteria('FindMe' + @random_string, 'Active', 'Weekends', 'Marketing')
end

Given(/^I create a job for the campaign$/) do
  create_job_campaign
end

Given(/^I create a shift for the job$/) do
  create_shift_for_job
end

Given(/^I select my campaign$/) do
  sleep 5
  on(V4SFindVolunteersPage).campaign_select = /JobCampaign/
end

Given(/^I select my job$/) do
  sleep 5
  on(V4SFindVolunteersPage).job_select = /a/
end

Given(/^I select my shift$/) do
  on(V4SFindVolunteersPage).shift_select = /full/
end

Given(/^I select my status$/) do
  on(V4SFindVolunteersPage).job_status_select = 'Confirmed'
end

When(/^I choose Availability "([^"]*)"$/) do |avail|
  on(V4SFindVolunteersPage).avail_select = avail
end

When(/^I choose skills "([^"]*)"$/) do |skills|
  on(V4SFindVolunteersPage).skills_select = skills
end

When(/^I choose Status "([^"]*)"$/) do |status|
  on(V4SFindVolunteersPage) do |page|
    page.status_select_element.when_present(15)
    page.status_select = status
  end
end

When(/^I click Assign$/) do
  on(V4SFindVolunteersPage).assign_button
end

When(/^I click Find$/) do
  on(V4SFindVolunteersPage).find_button
end

When(/^I click the Find Volunteers tab$/) do
  on(V4SMainPage).find_volunteers_link_element.when_present.click
end

Then(/^I should see my Volunteer$/) do
  #OUTPUT FROM .text() IS TRUNCATED FOR SOME REASON
  expect(on(V4SFindVolunteersPage).found_volunteer_link_element.text).to match @random_string[0..8]
end

Then(/^I see that my volunteer is assigned to a job$/) do
  on(V4SFindVolunteersPage).confirmation_notice_element.when_present
end

Then("I should see volunteer job shift") do
  fifteen_character_job_id = @job_id[0..14]
  expect(on(V4SFindVolunteersPage).shift_calendar_entry_element.text).to match /#{fifteen_character_job_id}/
end
