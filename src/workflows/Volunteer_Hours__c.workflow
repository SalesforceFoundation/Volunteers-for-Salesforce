<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_End_Date</fullName>
        <description>Set End Date to Start Date</description>
        <field>End_Date__c</field>
        <formula>Start_Date__c</formula>
        <name>Set End Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Volunteer Hours - Set End Date</fullName>
        <actions>
            <name>Set_End_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Volunteer_Hours__c.End_Date__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <description>If End Date is empty, set it to Start Date.</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
