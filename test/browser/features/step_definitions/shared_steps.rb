Given(/^I empty the Recycle Bin$/) do
  # THIS STEP CAN BE CALLED FROM ANY PAGE FOR WHICH THE "Recycle Bin" LINK EXISTS
  # IT WILL THEN RETURN THE BROWSER TO WHATEVER PAGE IT WAS INVOKED FROM
  on(V4SWhateverPage) do |page|
    delete_campaigns
    sleep 1 #MAKE SURE DELETE PROPAGATES
    page.recycle_bin
    page.empty_org
    @browser.alert.ok
    @browser.back

    if ENV['SELENIUM_BROWSER'] == 'chrome'
      @browser.back
    end

  end
end
