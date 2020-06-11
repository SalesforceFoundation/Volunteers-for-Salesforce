*** Settings ***

Resource        robot/v4s/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
Suite Setup     Open Test Browser
Suite Teardown  Delete Records and Close Browser

*** Keywords ***

Get Random Contact Info
    ${first_name} =  Generate Random String
    ${last_name} =  Generate Random String
    Set Test Variable  ${first_name}  ${first_name}
    Set Test Variable  ${last_name}  ${last_name}

*** Test Cases ***

Create a Contact via API and Go to the Contact Detail and Listing Pages
    &{contact} =  API Create Contact
    Go To Record Home  &{contact}[Id]
    Go To Page              Listing     Contact
    Sleep                   3sec