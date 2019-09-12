/*
    Copyright (c) 2019, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
@IsTest
public with sharing class DatabaseDml_TEST {
    private static List<SObject> setupSObjects = new List<SObject>();

    /**
    * Creates base data used throughout the different test scenarios
    */
    @TestSetup
    private static void generateData() {
        UTIL_UnitTest.generateData();
    }

    @IsTest
    private static void guestUserCanUpdateUnownedRecords() {
        if (UTIL_UnitTest.guestUser == null) {
            return;
        }

        List<SObject> records = new List<SObject>();
        String name = 'Guest Updated Me ' + System.now();
        setSetupSObjects();

        System.runAs(UTIL_UnitTest.guestUser) {
            for (SObject record : setupSObjects) {
                if (record.getSObjectType() == Contact.SObjectType) {
                    record.put('LastName', name);
                } else {
                    record.put('Name', name);
                }
                records.add(record);
            }

            DatabaseDml.getInstance().updateRecords(records);
        }

        System.assertEquals(name, getCampaigns()[0].Name, 'The campaign name should have been updated.');
        System.assertEquals(name, getJobs()[0].Name, 'The job name should have been updated.');
        System.assertEquals(name, getContacts()[0].LastName, 'The contact name should have been updated.');
    }

    @IsTest
    private static void guestUserCanInsertRecords() {
        if (UTIL_UnitTest.guestUser == null) {
            return;
        }

        List<SObject> records = new List<SObject>();
        String name = 'Guest Created Me ' + System.now();

        System.runAs(UTIL_UnitTest.guestUser) {
            records.add(UTIL_UnitTest.createCampaign(name));
            records.add(UTIL_UnitTest.createContact(name));

            DatabaseDml.getInstance().insertRecords(records);
        }

        for (SObject record : records) {
            System.assertNotEquals(null, record.Id, 'Expected the records to have been inserted.');
        }
    }

    @IsTest
    private static void updateRecordsShouldFailAllRecordsWhenAllOrNone() {
        List<SObject> records = new List<SObject>();
        String name = 'Guest Updated Me ' + System.now();
        Database.DMLOptions allOrNoneOption = new Database.DMLOptions();
        allOrNoneOption.OptAllOrNone = true;
        setSetupSObjects();

        for (SObject record : setupSObjects) {
            if (record.getSObjectType() == Contact.SObjectType) {
                record.put('FirstName', null);
                record.put('LastName', null);
            } else {
                record.put('Name', name);
            }

            records.add(record);
        }

        try {
            DatabaseDml.getInstance().updateRecords(records, allOrNoneOption);
            System.assert(false, 'An exception should have been thrown.');

        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('REQUIRED_FIELD_MISSING'), 'Expected the missing required field to cause an exception.');
        }

        System.assertNotEquals(name, getCampaigns()[0].Name, 'The campaign name should not have been updated.');
        System.assertNotEquals(name, getJobs()[0].Name, 'The job name should not have been updated.');
        System.assertNotEquals(null, getContacts()[0].LastName, 'The contact name should not have been updated.');
    }

    @IsTest
    private static void updateRecordsShouldFailOneRecordWhenNotAllOrNone() {
        List<SObject> records = new List<SObject>();
        String name = 'Guest Updated Me ' + System.now();
        Database.DMLOptions allOrNoneOption = new Database.DMLOptions();
        allOrNoneOption.OptAllOrNone = false;
        setSetupSObjects();

        for (SObject record : setupSObjects) {
            if (record.getSObjectType() == Contact.SObjectType) {
                record.put('FirstName', null);
                record.put('LastName', null);
            } else {
                record.put('Name', name);
            }

            records.add(record);
        }

        try {
            DatabaseDml.getInstance().updateRecords(records, allOrNoneOption);

        } catch (Exception ex) {
            System.assert(false, 'An exception should not have been thrown. ' + ex.getMessage());
        }

        System.assertEquals(name, getCampaigns()[0].Name, 'The campaign name should have been updated.');
        System.assertEquals(name, getJobs()[0].Name, 'The job name should have been updated.');
        System.assertNotEquals(null, getContacts()[0].LastName, 'The contact name should not have been updated.');
    }

    @IsTest
    private static void insertRecordsShouldFailAllRecordsWhenAllOrNone() {
        List<SObject> records = new List<SObject>();
        String name = 'Guest Created Me ' + System.now();
        Database.DMLOptions allOrNoneOption = new Database.DMLOptions();
        allOrNoneOption.OptAllOrNone = true;
        records.add(UTIL_UnitTest.createCampaign(name));
        records.add(UTIL_UnitTest.createContact(name));
        records.add(UTIL_UnitTest.createJob(name, null));

        try {
            DatabaseDml.getInstance().insertRecords(records, allOrNoneOption);
            System.assert(false, 'An exception should have been thrown.');

        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('REQUIRED_FIELD_MISSING'), 'Expected the missing required field to cause an exception.');
        }

        System.assertEquals(null, records[0].get('Id'), 'The campaign should not have been created.');
        System.assertEquals(null, records[1].get('Id'), 'The contact should not have been created.');
        System.assertEquals(null, records[2].get('Id'), 'The job should not have been created.');
    }

    @IsTest
    private static void insertRecordsShouldFailOneRecordWhenNotAllOrNone() {
        List<SObject> records = new List<SObject>();
        String name = 'Guest Created Me ' + System.now();
        Database.DMLOptions allOrNoneOption = new Database.DMLOptions();
        allOrNoneOption.OptAllOrNone = false;
        records.add(UTIL_UnitTest.createCampaign(name));
        records.add(UTIL_UnitTest.createContact(name));
        records.add(UTIL_UnitTest.createJob(name, null));

        try {
            DatabaseDml.getInstance().insertRecords(records, allOrNoneOption);

        } catch (Exception ex) {
            System.assert(false, 'An exception should not have been thrown. ' + ex.getMessage());
        }

        System.assertNotEquals(null, records[0].get('Id'), 'The campaign should have been created.');
        System.assertNotEquals(null, records[1].get('Id'), 'The contact should have been created.');
        System.assertEquals(null, records[2].get('Id'), 'The job should not have been created.');
    }


    /////////////////
    /// Helpers
    /////////////////


    private static void setSetupSObjects() {
        setupSObjects.addAll(getCampaigns());
        setupSObjects.addAll(getJobs());
        setupSObjects.addAll(getContacts());
    }

    private static List<Campaign> getCampaigns() {
        return [SELECT Id, Name FROM Campaign];
    }

    private static List<Volunteer_Job__c> getJobs() {
        return [SELECT Id, Name FROM Volunteer_Job__c];
    }

    private static List<Contact> getContacts() {
        return [SELECT Id, FirstName, LastName FROM Contact];
    }


    /*******************************************************************************************************************
     * @description Stub for DatabaseDml instance
     */
    public class Stub implements System.StubProvider {
        public Map<String, Integer> countByMethodName = new Map<String, Integer>{
            'updateRecords' => 0,
            'insertRecords' => 0
        };

        public Object handleMethodCall(
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs
        ) {
            countByMethodName.put(stubbedMethodName, countByMethodName.get(stubbedMethodName) + 1);
            return null;
        }
    }
}