*** Settings ***

Resource        robot/v4s/resources/v4s.robot
Library         cumulusci.robotframework.PageObjects
...             robot/v4s/resources/VolunteersWizardPageObject.py
...             robot/v4s/resources/v4s.py
Suite Setup     Run Keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Delete Records and Close Browser

*** Keywords ***

Setup Test Data
    ${campaign_name} =      Generate Random String
    Set suite variable      ${campaign_name}

*** Test Cases ***

Create a Campaign, Jobs, and Shifts via Volunteers Wizard
    Go To VF Page                          Volunteers Wizard
#    Populate Form                          Campaign Name=${campaign_name}
#    ...                                    Active=checked
#    Click Modal Button                     Save
#    Wait Until Modal Is Closed
#    Select Tab                             Details
#    Verify Details                         Campaign Name                        contains            ${campaign_name}
#    Verify Details                         Campaign Record Type                 contains            Volunteer Campaign
#    Verify Details                         Active                               equals              True