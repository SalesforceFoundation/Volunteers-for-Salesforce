
Given(/^I login the first time with oauth$/) do
  on(LoginPage) do |page|
    page.app_switcher_element.when_present.click
    begin
      #WE ONLY NEED TO CLICK Volunteers AFTER A FRESH INSTALL
      #DON'T FAIL THE TEST IF Volunteers IS ALREADY SELECTED
      page.v4s_app_picker_element.when_present.click
    rescue
    end
    page.app_switcher_element.when_present.click
  end
end
