class V4SMainPage
  include PageObject

  a(:volunteers_help_link, text: 'Volunteers Help')
  a(:shift_calendar_link, text: 'Shift Calendar')
  a(:find_volunteers_link, text: 'Find Volunteers')
  a(:volunteers_wizard_link, text: 'Volunteers Wizard')
  a(:volunteer_jobs_link, text: 'Volunteer Jobs')
end
