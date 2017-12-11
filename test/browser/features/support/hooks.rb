Before do |scenario|
  @array_of_contacts = []
  @array_of_contact_names = []
  @array_of_opp_ids = []
  set_url_and_object_namespace_to_v4s
end

After('@reset_recurring_donations') do
  reset_recurring_donations_settings(@recurring_donations_settings)
end

After do |scenario|
  #CLOBBER OBJECTS TO PREVENT FAILURES FROM POLLUTING DOWNSTREAM TESTS
  #IF THE OBJECT IS ALREADY DELETED THIS IS A NOOP
  delete_campaigns
  delete_all_contacts
  delete_jobs
end
