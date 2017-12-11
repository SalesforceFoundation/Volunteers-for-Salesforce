class V4SShiftCalendarPage
  include PageObject

  h1(:shift_calendar_header, class: 'slds-text-heading--medium')
  select_list(:campaign_select, id: /ddlCampaignId/)
  select_list(:volunteer_job_select, id: /ddlJobId/)
  table(:calendar_table, class: 'fc-border-separate')
end

