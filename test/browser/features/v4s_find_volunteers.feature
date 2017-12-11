@smoketest
Feature: V4S Find Volunteers
  Background:
    Given I create a Contact with V4S criteria
      And I create a Campaign named "JobCampaign"
      And I create a job for the campaign
      And I create a shift for the job
    When I click the Find Volunteers tab
      And I choose Status "Active"
      And I choose Availability "Weekends"
      And I choose skills "Marketing"
      And I click Find

  Scenario: Find a Volunteer
    Then I should see my Volunteer

  Scenario: Assign volunteer to a job
      And I click my volunteer
      And I select my campaign
      And I select my job
      And I select my shift
      And I select my status
    When I click Assign
      And I see that my volunteer is assigned to a job
      And I click the Shift Calendar tab
    Then I should see volunteer job shift
