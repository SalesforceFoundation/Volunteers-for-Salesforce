*** Settings ***

Resource        robot/v4s/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/v4s/resources/ContactPageObject.py
...             robot/v4s/resources/AccountPageObject.py
...             robot/v4s/resources/NPSP.py
Suite Setup     Run Keywords
...             Open Test Browser
...             Setup Test Data
Suite Teardown  Delete Records and Close Browser

*** Keywords ***

Setup Test Data
    ${First Name} =         Generate Random String
    Set suite variable      ${First Name}
    ${Last Name} =          Generate Random String
    Set suite variable      ${Last Name}

*** Test Cases ***

Create a Contact via UI
    Go To Page                  Listing     Contact
    Click Object Button         New
    Wait For Modal              New         Contact
    Populate Form               First Name=${First Name}
    ...                         Last Name=${Last Name}
    ...                         Mobile=5556667777
    Populate Field              Email       test@example.com
    Click Modal Button          Save
    Wait Until Modal Is Closed

Verify Contact Detail Page
    Go To Page                  Listing      Contact
    Sleep                       3sec