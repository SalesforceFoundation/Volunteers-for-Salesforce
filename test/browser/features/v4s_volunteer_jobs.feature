@smoketest
Feature: V4S Volunteer Jobs

  Background:
    Given I create a Campaign named "Test Campaign"
    And I navigate to Volunteer Jobs
    And I fill in Volunteer Job Name
    And I find my Campaign using "Test Campaign"

  Scenario: Required Fields
    When I click Save
    Then I should see my Volunteer Job

  Scenario: Location Section
    When I fill in location fields
    And I fill in location information
    And I click Save
    Then I should see location information saved

  Scenario: Description Section
    When I click checkboxes
    And I set the timezone
    And I check the skills
    And I add a description
    And I click Save
    Then I should see complete description saved
