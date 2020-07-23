*** Settings ***

Resource        robot/v4s/resources/v4s.robot
Library         cumulusci.robotframework.PageObjects
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

Create and Verify a Campaign via UI
    Go To Page                             Listing                              Campaign
    Click Object Button                    New
    Wait For Modal                         New         Volunteer Campaign
    Populate Modal Form                    Campaign Name=${campaign_name}
    ...                                    Active=checked
    Click Modal Button                     Save
    Wait Until Modal Is Closed
    Select Tab                             Details
    Verify Details                         Campaign Name                        contains            ${campaign_name}
    Verify Details                         Campaign Record Type                 contains            Volunteer Campaign
    Verify Details                         Active                               equals              True