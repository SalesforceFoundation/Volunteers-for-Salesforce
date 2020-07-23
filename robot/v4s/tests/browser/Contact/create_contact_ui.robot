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
    ${first_name} =         Generate Random String
    Set suite variable      ${first_name}
    ${last_name} =          Generate Random String
    Set suite variable      ${last_name}

*** Test Cases ***

Create and Verify a Contact via UI
    Go To Page                             Listing                              Contact
    Click Object Button                    New
    Wait For Modal                         New         Contact
    Populate Modal Form                    First Name=${first_name}
    ...                                    Last Name=${last_name}
    ...                                    Email=test@example.com
    ...                                    Volunteer Status=New Sign Up
    Click Modal Button                     Save
    Wait Until Modal Is Closed
    Click Tab                              Details
    Verify Details                         Name                                 contains            ${first_name} ${last_name}
    Verify Details                         Email                                contains            test@example.com  
    Verify Details                         Volunteer Status                     contains            New Sign Up      