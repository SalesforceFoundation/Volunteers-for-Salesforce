class V4SJobsPage
  include PageObject

  button(:new_button, title: 'New')
  text_field(:job_name, id: 'Name')
  text_field(:opp_name, index: 3)
  button(:save_button, title: 'Save')
  h2(:title, class:'pageDescription' )
  h2(:header, class:'mainTitle')
  div(:job_name, id:'Name_ileinner')
  a(:campaign_link, id: /lookup/)

  text_field(:street_field, index: 4)
  text_field(:city_field, index: 5)
  text_field(:state_field, index: 6)
  text_field(:zip_code_field, index: 7)
  table(:location_table, class: 'detailList', index: 1)

  checkbox(:ongoing_box, index: 1)
  checkbox(:inactive_box, index: 2)
  checkbox(:display_box, index: 3)
  select_list(:timezone_select, index: 1)
  select_list(:skills_select, title: /Skills Needed/)
  a(:add_select, title: 'Add')
  img(:first_check, title:'Checked', index: 0)
  img(:second_check, title:'Checked', index: 1)
  img(:third_check, title:'Checked', index: 2)

  div(:description_zone, class: 'pbSubsection')

  in_iframe(title: /Rich Text Editor/, index: 0) do |frame|
    body(:description, id: /body/, frame: frame)
  end

  in_iframe(title: /Rich Text Editor/, index: 1) do |frame|
    body(:location_description, id: /body/, frame: frame)
  end

end
