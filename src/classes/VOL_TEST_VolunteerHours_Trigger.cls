/*
    Copyright (c) 2016, Salesforce.org
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

@isTest
private class VOL_TEST_VolunteerHours_Trigger {
    private static VOL_Access_TEST.Stub accessMock = new VOL_Access_TEST.Stub();

    @IsTest
    private static void shouldUpdateShiftRecordsOnConfirmedHours() {
        VOL_SharedCode.access = (VOL_Access) Test.createStub(VOL_Access.class, accessMock);
        UTIL_UnitTest.generateDataWithShift();
        Id shiftId = UTIL_UnitTest.getId(Volunteer_Shift__c.SObjectType);

        Volunteer_Hours__c hours = UTIL_UnitTest.createHours(
            UTIL_UnitTest.getId(Contact.SObjectType),
            UTIL_UnitTest.getId(Volunteer_Job__c.SObjectType),
            shiftId
        );
        hours.Status__c = 'Confirmed';
        insert hours;

        accessMock.assertMethodCalled('updateRecords', Volunteer_Shift__c.SObjectType);
    }

    @IsTest
    private static void shouldNotUpdateShiftRecordsOnPendingHours() {
        VOL_SharedCode.access = (VOL_Access) Test.createStub(VOL_Access.class, accessMock);
        UTIL_UnitTest.generateDataWithShift();
        Id shiftId = UTIL_UnitTest.getId(Volunteer_Shift__c.SObjectType);

        Volunteer_Hours__c hours = UTIL_UnitTest.createHours(
            UTIL_UnitTest.getId(Contact.SObjectType),
            UTIL_UnitTest.getId(Volunteer_Job__c.SObjectType),
            shiftId
        );
        hours.Status__c = 'Pending';
        insert hours;

        accessMock.assertMethodCalled('updateRecords', null);
    }

    static testMethod void myUnitTest() {
        Account acc = new Account(name='Individual Test Account');
        insert acc;
        Contact con = new Contact(Lastname='Testy', AccountId=acc.Id, Volunteer_Status__c='inactive');
        insert con;
        Campaign cmp = new Campaign(recordtypeid=VOL_SharedCode.recordtypeIdVolunteersCampaign, name='Test Campaign', IsActive=true);
        insert cmp;
        Volunteer_Job__c job = new Volunteer_Job__c(name='Job1', campaign__c=cmp.Id);
        insert job;
        Volunteer_Shift__c shift = new Volunteer_Shift__c(Volunteer_Job__c=job.Id, Duration__c=1, Start_Date_Time__c=System.now());
        insert shift;
        
        // test inserting new hours
        list<Volunteer_Hours__c> listHours = new list<Volunteer_Hours__c>();        
        for (integer i = 0; i < 10; i++) {
            Volunteer_Hours__c hours = new Volunteer_Hours__c(
                Volunteer_Job__c=job.id, 
                Volunteer_Shift__c=shift.Id,
                Contact__c=con.Id,
                Number_of_Volunteers__c=3,
                Start_Date__c=System.today(), 
                Status__c='Confirmed'
                );
            listHours.add(hours);
        }                       
        insert listHours;
        shift = [select Id, Total_Volunteers__c  from Volunteer_Shift__c where Id = :shift.Id limit 1];
        system.AssertEquals(30, shift.Total_Volunteers__c );
        
        // test updating existing hours
        for (integer i = 0; i < 10; i++) {
            listHours.get(i).Number_of_Volunteers__c = 1;
        }
        update listHours;
        shift = [select Id, Total_Volunteers__c  from Volunteer_Shift__c where Id = :shift.Id limit 1];
        system.AssertEquals(10, shift.Total_Volunteers__c );
            
        // test deleting existing hours
        listHours.remove(1);
        listHours.remove(2);            
        listHours.remove(3);
        delete listHours;
        shift = [select Id, Total_Volunteers__c  from Volunteer_Shift__c where Id = :shift.Id limit 1];
        system.AssertEquals(3, shift.Total_Volunteers__c );
    
        // make sure our contact's volunteer status was made active
        Contact conT = [select Id, Volunteer_Status__c from Contact where Id = :con.Id];
        system.AssertEquals('Active', conT.Volunteer_Status__c);
        
        // test deleting contact to make sure their hours are deleted and Shift rollups are recalced.
        delete conT;
        shift = [select Id, Total_Volunteers__c  from Volunteer_Shift__c where Id = :shift.Id limit 1];
        system.AssertEquals(0, shift.Total_Volunteers__c );
        
        // test undeleting a contact that restores their child objects
        undelete conT;
        shift = [select Id, Total_Volunteers__c  from Volunteer_Shift__c where Id = :shift.Id limit 1];
        system.AssertEquals(3, shift.Total_Volunteers__c );
        
        // test changing of Hours from one Shift to another Shift.
        listHours = new list<Volunteer_Hours__c>();        
        for (integer i = 0; i < 9; i++) {
            Volunteer_Hours__c hours = new Volunteer_Hours__c(
                Volunteer_Job__c=job.id, 
                Volunteer_Shift__c=shift.Id,
                Contact__c=con.Id,
                Number_of_Volunteers__c=3,
                Start_Date__c=System.today(), 
                Status__c='Confirmed'
                );
            listHours.add(hours);
        }                       
        insert listHours;
        shift = [select Id, Total_Volunteers__c  from Volunteer_Shift__c where Id = :shift.Id limit 1];
        system.AssertEquals(30, shift.Total_Volunteers__c );
        Volunteer_Shift__c shift2 = new Volunteer_Shift__c(Volunteer_Job__c=job.Id, Duration__c=1, Start_Date_Time__c=System.now());
        insert shift2;
		listHours[0].Volunteer_Shift__c = shift2.Id;
		listHours[1].Volunteer_Shift__c = shift2.Id;
		listHours[2].Volunteer_Shift__c = shift2.Id;
		update listHours;
        shift = [select Id, Total_Volunteers__c  from Volunteer_Shift__c where Id = :shift.Id limit 1];
        system.AssertEquals(21, shift.Total_Volunteers__c );
        shift2 = [select Id, Total_Volunteers__c  from Volunteer_Shift__c where Id = :shift2.Id limit 1];
        system.AssertEquals(9, shift2.Total_Volunteers__c );
		
        // test reparenting of Hours from one Job to another Job.
        Volunteer_Job__c job2 = new Volunteer_Job__c(name='Job2', campaign__c=cmp.Id);
        insert job2;
        listHours[0].Volunteer_Job__c = job2.Id;
		listHours[0].Volunteer_Shift__c = null;
        listHours[1].Volunteer_Job__c = job2.Id;
		listHours[1].Volunteer_Shift__c = null;
        listHours[2].Volunteer_Job__c = job2.Id;
		listHours[2].Volunteer_Shift__c = null;
		update listHours;
        shift2 = [select Id, Total_Volunteers__c  from Volunteer_Shift__c where Id = :shift2.Id limit 1];
        system.AssertEquals(0, shift2.Total_Volunteers__c );
		job2 = [select Id, Number_of_Volunteers__c from Volunteer_Job__c where Id = : job2.Id limit 1];
		system.AssertEquals(9, job2.Number_of_Volunteers__c);

		// test merging of contacts.
        Contact con2 = new Contact(Lastname='Testy2', AccountId=acc.Id, Volunteer_Status__c='inactive');
        insert con2;
        shift = [select Id, Total_Volunteers__c  from Volunteer_Shift__c where Id = :shift.Id limit 1];
        system.AssertEquals(21, shift.Total_Volunteers__c );		
        Volunteer_Hours__c hours2 = new Volunteer_Hours__c(
            Volunteer_Job__c=job.id, 
            Volunteer_Shift__c=shift.Id,
            Contact__c=con2.Id,
            Number_of_Volunteers__c=4,
            Start_Date__c=System.today(), 
            Status__c='Confirmed'
            );
        insert hours2;
		listHours = [select Id from Volunteer_Hours__c where contact__c = :con.Id];
		system.AssertEquals(12, listHours.size());
		listHours = [select Id from Volunteer_Hours__c where contact__c = :con2.Id];
		system.AssertEquals(1, listHours.size());
        shift = [select Id, Total_Volunteers__c  from Volunteer_Shift__c where Id = :shift.Id limit 1];
        system.AssertEquals(25, shift.Total_Volunteers__c );
		merge con con2;
		listHours = [select Id from Volunteer_Hours__c where contact__c = :con.Id];
		system.AssertEquals(13, listHours.size());
        shift = [select Id, Total_Volunteers__c  from Volunteer_Shift__c where Id = :shift.Id limit 1];
        system.AssertEquals(25, shift.Total_Volunteers__c );

    }

    // ======================================================================================
    // Coverage for W-23750608: merging Contacts in orgs with many Volunteer_Hours__c records
    // fails, because VOL_Contact_MaintainHours.trigger's after-delete (merge) branch re-queries
    // every hour on the affected shifts with no Contact filter, blowing the 50k SOQL
    // query-row governor limit. The tests below cover the merge/rollup scenarios that any
    // fix must continue to get right, plus a repro test that fails on the unfixed trigger.
    // ======================================================================================

    private class MergeTestData {
        Account acc;
        Campaign cmp;
        Volunteer_Job__c job;
        Volunteer_Shift__c shift;
        Contact winningContact;
        Contact duplicateContact;
    }

    private static MergeTestData setupMergeTestData() {
        MergeTestData data = new MergeTestData();
        data.acc = new Account(Name = 'W-23750608 Merge Test Account');
        insert data.acc;
        data.cmp = new Campaign(RecordTypeId = VOL_SharedCode.recordtypeIdVolunteersCampaign, Name = 'W-23750608 Merge Test Campaign', IsActive = true);
        insert data.cmp;
        data.job = new Volunteer_Job__c(Name = 'W-23750608 Merge Test Job', Campaign__c = data.cmp.Id);
        insert data.job;
        data.shift = new Volunteer_Shift__c(Volunteer_Job__c = data.job.Id, Duration__c = 1, Start_Date_Time__c = System.now());
        insert data.shift;
        data.winningContact = new Contact(LastName = 'WinningContact', AccountId = data.acc.Id, Volunteer_Status__c = 'inactive');
        data.duplicateContact = new Contact(LastName = 'DuplicateContact', AccountId = data.acc.Id, Volunteer_Status__c = 'inactive');
        insert new List<Contact>{ data.winningContact, data.duplicateContact };
        return data;
    }

    private static Volunteer_Hours__c newHours(Id jobId, Id shiftId, Id contactId, Decimal numVolunteers, String status) {
        return new Volunteer_Hours__c(
            Volunteer_Job__c = jobId,
            Volunteer_Shift__c = shiftId,
            Contact__c = contactId,
            Number_of_Volunteers__c = numVolunteers,
            Start_Date__c = System.today(),
            Status__c = status
        );
    }

    private static Decimal totalVolunteersOnShift(Id shiftId) {
        return [SELECT Total_Volunteers__c FROM Volunteer_Shift__c WHERE Id = :shiftId LIMIT 1].Total_Volunteers__c;
    }

    // Basic case: the winning contact has no hours on the shift; the duplicate contact's
    // confirmed hours are the shift's only contribution. The rollup must survive the
    // reparent unchanged.
    @IsTest
    static void testMergeRecalculatesWhenOnlyDuplicateContactHadHoursOnShift() {
        MergeTestData data = setupMergeTestData();
        insert newHours(data.job.Id, data.shift.Id, data.duplicateContact.Id, 3, 'Confirmed');
        insert newHours(data.job.Id, data.shift.Id, data.duplicateContact.Id, 2, 'Confirmed');
        System.assertEquals(5, totalVolunteersOnShift(data.shift.Id), 'sanity check before merge');

        Test.startTest();
        merge data.winningContact data.duplicateContact;
        Test.stopTest();

        System.assertEquals(5, totalVolunteersOnShift(data.shift.Id),
            'Total should equal the duplicate contact\'s reparented hours after merge.');
    }

    // Key regression guard: a naive fix that filters the recompute query by Contact__c
    // (as originally suggested on the bug) would drop every OTHER volunteer's hours on
    // the shift. This must keep summing everyone, not just the merged contact.
    @IsTest
    static void testMergePreservesUnrelatedVolunteersOnShift() {
        MergeTestData data = setupMergeTestData();
        Contact unrelatedContact = new Contact(LastName = 'Unrelated', AccountId = data.acc.Id);
        insert unrelatedContact;

        insert newHours(data.job.Id, data.shift.Id, unrelatedContact.Id, 10, 'Confirmed');
        insert newHours(data.job.Id, data.shift.Id, data.duplicateContact.Id, 3, 'Confirmed');
        System.assertEquals(13, totalVolunteersOnShift(data.shift.Id), 'sanity check before merge');

        Test.startTest();
        merge data.winningContact data.duplicateContact;
        Test.stopTest();

        System.assertEquals(13, totalVolunteersOnShift(data.shift.Id),
            'Total must still include the unrelated contact\'s hours after merge.');
    }

    // The duplicate contact's hours span two shifts; both rollups must be recalculated
    // correctly, and merging must not affect a shift the duplicate contact never touched.
    @IsTest
    static void testMergeAcrossMultipleShiftsBothRecalculated() {
        MergeTestData data = setupMergeTestData();
        Volunteer_Shift__c shift2 = new Volunteer_Shift__c(Volunteer_Job__c = data.job.Id, Duration__c = 1, Start_Date_Time__c = System.now());
        insert shift2;

        insert newHours(data.job.Id, data.shift.Id, data.winningContact.Id, 2, 'Confirmed');
        insert newHours(data.job.Id, data.shift.Id, data.duplicateContact.Id, 3, 'Confirmed');
        insert newHours(data.job.Id, shift2.Id, data.duplicateContact.Id, 4, 'Confirmed');
        System.assertEquals(5, totalVolunteersOnShift(data.shift.Id), 'sanity check shift 1 before merge');
        System.assertEquals(4, totalVolunteersOnShift(shift2.Id), 'sanity check shift 2 before merge');

        Test.startTest();
        merge data.winningContact data.duplicateContact;
        Test.stopTest();

        System.assertEquals(5, totalVolunteersOnShift(data.shift.Id), 'Shift 1 total unchanged (2 + 3) after merge.');
        System.assertEquals(4, totalVolunteersOnShift(shift2.Id), 'Shift 2 total recalculated (duplicate-contact-only) after merge.');
    }

    // Two sequential merges into the same winning contact must each recalculate correctly
    // and accumulate, rather than the second merge clobbering the first merge's contribution.
    @IsTest
    static void testSequentialMergesIntoSameWinningContactAccumulateCorrectly() {
        MergeTestData data = setupMergeTestData();
        Contact duplicateContact2 = new Contact(LastName = 'DuplicateContact2', AccountId = data.acc.Id, Volunteer_Status__c = 'inactive');
        insert duplicateContact2;

        insert newHours(data.job.Id, data.shift.Id, data.winningContact.Id, 2, 'Confirmed');
        insert newHours(data.job.Id, data.shift.Id, data.duplicateContact.Id, 3, 'Confirmed');
        insert newHours(data.job.Id, data.shift.Id, duplicateContact2.Id, 4, 'Confirmed');
        System.assertEquals(9, totalVolunteersOnShift(data.shift.Id), 'sanity check before merges');

        Test.startTest();
        merge data.winningContact data.duplicateContact;
        merge data.winningContact duplicateContact2;
        Test.stopTest();

        System.assertEquals(9, totalVolunteersOnShift(data.shift.Id),
            'Total should equal the sum of all three contacts\' hours after both merges.');
    }

    // Hours with no shift, and hours in a non-counting status, must not blow up the merge
    // and must not be counted toward the shift's rollup.
    @IsTest
    static void testMergeIgnoresNullShiftAndNonConfirmedStatuses() {
        MergeTestData data = setupMergeTestData();
        insert newHours(data.job.Id, null, data.duplicateContact.Id, 99, 'Web Sign Up');
        insert newHours(data.job.Id, data.shift.Id, data.duplicateContact.Id, 50, 'Prospect');
        insert newHours(data.job.Id, data.shift.Id, data.duplicateContact.Id, 3, 'Confirmed');
        System.assertEquals(3, totalVolunteersOnShift(data.shift.Id), 'sanity check before merge');

        Test.startTest();
        merge data.winningContact data.duplicateContact;
        Test.stopTest();

        System.assertEquals(3, totalVolunteersOnShift(data.shift.Id),
            'Only the Confirmed hour should count; the null-shift and Prospect hours must not.');
    }

    // Merging two contacts with no Volunteer_Hours__c at all must be a no-op, not an error.
    @IsTest
    static void testMergeWithNoHoursDoesNotThrow() {
        MergeTestData data = setupMergeTestData();

        Test.startTest();
        merge data.winningContact data.duplicateContact;
        Test.stopTest();

        System.assertEquals(null, totalVolunteersOnShift(data.shift.Id), 'Untouched shift is never written and stays null.');
    }

    // Repro for W-23750608: populate the shift with many hours belonging to OTHER
    // contacts (standing in, at unit-test scale, for the >50k Volunteer_Hours__c records
    // in the reported org) plus one hour for the duplicate contact, then merge. The
    // unfixed trigger re-queries every hour on the shift with no Contact filter, so
    // query-row consumption scales with the number of unrelated hours; the fix must
    // keep it a small constant.
    @IsTest
    static void testMergeQueryRowsDoNotScaleWithHoursOnShift() {
        MergeTestData data = setupMergeTestData();

        Integer unrelatedCount = 50;
        List<Contact> unrelatedContacts = new List<Contact>();
        for (Integer i = 0; i < unrelatedCount; i++) {
            unrelatedContacts.add(new Contact(LastName = 'Unrelated' + i, AccountId = data.acc.Id));
        }
        insert unrelatedContacts;

        List<Volunteer_Hours__c> fillerHours = new List<Volunteer_Hours__c>();
        for (Contact unrelatedContact : unrelatedContacts) {
            fillerHours.add(newHours(data.job.Id, data.shift.Id, unrelatedContact.Id, 1, 'Confirmed'));
        }
        insert fillerHours;
        insert newHours(data.job.Id, data.shift.Id, data.duplicateContact.Id, 3, 'Confirmed');

        Test.startTest();
        Integer queryRowsBefore = Limits.getQueryRows();
        merge data.winningContact data.duplicateContact;
        Integer queryRowsUsedByMerge = Limits.getQueryRows() - queryRowsBefore;
        Test.stopTest();

        System.assertEquals(unrelatedCount + 3, totalVolunteersOnShift(data.shift.Id),
            'Total should include the unrelated confirmed hours plus the duplicate contact\'s reparented hours.');

        // The unfixed trigger queries "WHERE Volunteer_Shift__c IN :shiftIds" with no
        // Contact filter, pulling all unrelatedCount + 1 hours on the shift into query rows.
        // The fix uses GROUP BY aggregates, whose result rows (one per shift) count against
        // the limit instead -- so this must stay small regardless of unrelatedCount.
        System.assert(queryRowsUsedByMerge < 15,
            'Merge query-row consumption must not scale with the number of hours on the shift. Used=' + queryRowsUsedByMerge);
    }

}