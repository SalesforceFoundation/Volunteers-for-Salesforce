@smoketest
Feature: V4S Find Volunteers

  Scenario: Shift Calendar
    When I click the Shift Calendar tab
    Then I should see the Shift Calendar page
      And I should see the default value for Campaign
      And I should see the default value for Volunteer Job
      And I should see the calendar itself
