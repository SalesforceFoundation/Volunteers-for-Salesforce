class V4SFindVolunteersPage
  include PageObject

  button(:assign_button, id: 'assignbtn')
  select_list(:avail_select, id: /:1:.+:inputX/m)
  select_list(:campaign_select, css: '#j_id0\3a j_id8\3a j_id146 > div:nth-child(1) > div > select' )
  h2(:confirmation_notice, class: 'slds-text-heading--small', text: /selected volunteer\(s\) have been assigned to this job or shift./)
  button(:find_button, text: 'Find')
  checkbox(:found_box, id: 'cbxAll')
  a(:found_volunteer_link, text: /FindMe/)
  select_list(:job_select, id: /VolunteerJobs/)
  select_list(:job_status_select, css: '#j_id0\3a j_id8\3a j_id166')
  select_list(:shift_select, id: /VolunteerShifts/)
  select_list(:skills_select, id: /:2:.+:inputX/m)
  select_list(:status_select, id: /:0:.+:inputX/m)
  div(:spinner, id: 'divLoading' )
  a(:shift_calendar_entry, text: /full/)
end
