class V4SWizardPage
  include PageObject

  button(:save_button, value: 'Save')
  button(:clone_button, name: 'clone')
  select_list(:number_sample_jobs, id: 'j_id0:j_id3:wizSampleJobs')
  select_list(:number_sample_shifts, id: 'j_id0:j_id3:wizSampleShifts')
  span(:active_checkbox, class: 'slds-checkbox--faux')
  text_field(:campaign_name, id: /inputX/)
  #checkbox(:active_checkbox, id: /inputCB/) THIS IS REAL CHECKBOX; WE CAN ONLY ADDRESS IT VIA SPAN
end
