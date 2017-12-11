When(/^I click the Volunteers Help tab$/) do
  on(V4SMainPage).volunteers_help_link_element.when_present.click
end

Then(/^I should see the Trailhead Link$/) do
  expect(on(V4SVolunteersHelpPage).trailhead_link_element.when_present(15).visible?).to be(true)
end

Then(/^I should see the V4S Help link$/) do
  expect(on(V4SVolunteersHelpPage).v4s_help_link_element.when_present.visible?).to be(true)
end

Then(/^I should see the Power of Us Hub link$/) do
  expect(on(V4SVolunteersHelpPage).power_of_us_hub_link_element.when_present.visible?).to be(true)
end
