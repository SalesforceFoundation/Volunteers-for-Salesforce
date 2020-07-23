*** Settings ***

Resource       cumulusci/robotframework/Salesforce.robot
Library        v4s.py
Library        DateTime

*** Keywords ***

API Create Contact
    ${ns} =                 Get V4S Namespace Prefix
    [Arguments]             &{fields}
    ${first_name} =         Generate Random String
    ${last_name} =          Generate Random String
    ${contact_id} =         Salesforce Insert  Contact
    ...                         FirstName=${first_name}
    ...                         LastName=${last_name}
    ...                         Email=v4stest@example.com
    ...                         ${ns}Volunteer_Status__c=New Sign Up
    ...                         &{fields}
    &{contact} =            Salesforce Get  Contact  ${contact_id}
    Store Session Record    Contact  ${contact_id}
    [Return]                &{contact}

API Create Campaign
    [Arguments]             &{fields}
    ${campaign_name} =      Generate Random String
    ${campaign_id} =        Salesforce Insert  Campaign
    ...                         Name=${campaign_name}
    ...                         &{fields}
    &{campaign} =           Salesforce Get  Campaign  ${campaign_id}
    Store Session Record    Campaign  ${campaign_id}
    [Return]                &{campaign}    

Capture Screenshot and Delete Records and Close Browser
    [Documentation]         This keyword will capture a screenshot before closing the browser and deleting records when test fails
    Run Keyword If Any Tests Failed      Capture Page Screenshot
    Close Browser
    Delete Session Records