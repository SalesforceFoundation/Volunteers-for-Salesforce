When(/^I click the Shift Calendar tab$/) do
  on(V4SMainPage).shift_calendar_link_element.when_present.click
end

Then(/^I should see the Shift Calendar page$/) do
  expect(on(V4SShiftCalendarPage).shift_calendar_header_element.text).to match 'Volunteers Shift Calendar'
end

Then(/^I should see the default value for Campaign$/) do
  expect(on(V4SShiftCalendarPage).campaign_select).to eq '(all active volunteer campaigns)'
end

Then(/^I should see the default value for Volunteer Job$/) do
  expect(on(V4SShiftCalendarPage).volunteer_job_select).to eq '(all jobs)'
end

Then(/^I should see the calendar itself$/) do
  expect(on(V4SShiftCalendarPage).calendar_table).to match /Sun.+Mon.+Tue.+Wed.+Thu.+Fri.+Sat/
end
