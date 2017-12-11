Feature: Volunteers Wizard Page

  Background:
    Given I am on the Volunteers Wizard Page
      And I empty the Recycle Bin

  Scenario: Use Volunteers Wizard Page
    When I create a new campaign with jobs and shifts
      And I clone the campaign I just created
    Then the clone campaign should refresh
      And I empty the Recycle Bin
