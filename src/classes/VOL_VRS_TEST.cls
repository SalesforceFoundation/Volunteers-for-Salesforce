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

@IsTest
private with sharing class VOL_VRS_TEST {

    private static Id contactId {
        get {
            if (contactId == null) {
                contactId = [SELECT Id FROM Contact ORDER BY Id LIMIT 1].Id;
            }
            return contactId;
        }
        set;
    }

    private static Id jobId {
        get {
            if (jobId == null) {
                jobId = [SELECT Id FROM Volunteer_Job__c ORDER BY Id LIMIT 1].Id;
            }
            return jobId;
        }
        set;
    }

    private static Date startOfLastMonth {
        get {
            if (startOfLastMonth == null) {
                startOfLastMonth = System.today().addMonths(-1).toStartOfMonth();
            }
            return startOfLastMonth;
        }
        set;
    }

    private static Date endOfNextMonth {
        get {
            if (endOfNextMonth == null) {
                endOfNextMonth = System.today().addMonths(2).toStartOfMonth().addDays(-1);
            }
            return endOfNextMonth;
        }
        set;
    }

    /**
    * Creates base data used throughout the different test scenarios
    */
    @TestSetup
    private static void generateData() {
        UTIL_UnitTest.generateData();
    }

    //******************************************************************************************************
    // Test Volunteer Recurrence Schedules
    @IsTest
    private static void alternateWeekShouldReturnTrueForDaysOfAlternatingWeeks() {
        Volunteer_Recurrence_Schedule__c volunteerSchedule = createVolunteerSchedule();
        volunteerSchedule.Schedule_Start_Date_Time__c = Date.newInstance(2012,2,1);

        System.assertEquals(true, VOL_VRS.alternateWeekVRS(volunteerSchedule, Date.newInstance(2012,2,1)), 'Any day within the same week of the scheduled start date should return true.');
        System.assertEquals(true, VOL_VRS.alternateWeekVRS(volunteerSchedule, Date.newInstance(2012,2,4)), 'Any day within the same week of the scheduled start date should return true.');
        System.assertEquals(false, VOL_VRS.alternateWeekVRS(volunteerSchedule, Date.newInstance(2012,2,6)), 'Any day within the following week of the scheduled start date should return false.');
        System.assertEquals(false, VOL_VRS.alternateWeekVRS(volunteerSchedule, Date.newInstance(2012,2,11)), 'Any day within the following week of the scheduled start date should return false.');
        System.assertEquals(true, VOL_VRS.alternateWeekVRS(volunteerSchedule, Date.newInstance(2012,2,13)), 'Any day within the week two weeks after the scheduled start date should return true.');
    }

    @IsTest
    private static void jobScheduleShouldCreatesShifts() {
        Job_Recurrence_Schedule__c jobSchedule = createJobSchedule();
        jobSchedule.Schedule_Start_Date_Time__c = Date.newInstance(2012,1,1);
        jobSchedule.Schedule_End_Date__c = Date.newInstance(2012,12,31);
        jobSchedule.Weekly_Occurrence__c = 'Every';

        Test.startTest();
        insert jobSchedule;
        Test.stopTest();

        validateShifts(157, jobSchedule.Id);
    }

    @IsTest
    private static void hoursShouldGenerateWhenMatchingVolunteerScheduleExists() {
        Volunteer_Recurrence_Schedule__c volunteerSchedule = createVolunteerSchedule();
        volunteerSchedule.Days_of_Week__c = 'Monday;Friday';
        volunteerSchedule.Schedule_Start_Date_Time__c = Date.newInstance(2012,2,1);
        volunteerSchedule.Schedule_End_Date__c = Date.newInstance(2012,6,30);
        volunteerSchedule.Weekly_Occurrence__c = '1st';
        insert volunteerSchedule;

        Job_Recurrence_Schedule__c jobSchedule = createJobSchedule();
        jobSchedule.Schedule_Start_Date_Time__c = Date.newInstance(2012,1,1);
        jobSchedule.Schedule_End_Date__c = Date.newInstance(2012,12,31);
        jobSchedule.Weekly_Occurrence__c = 'Every';

        Test.startTest();
        insert jobSchedule;
        Test.stopTest();

        List<Volunteer_Hours__c> hours = getHours(volunteerSchedule.Id);
        System.assertEquals(10, hours.size(), 'Expected hours for the 1st Monday and Friday of every month to be created.');
        System.assertEquals(volunteerSchedule.Number_of_Volunteers__c, hours[0].Number_of_Volunteers__c, 'Expected number of volunteers from the schedule to be populated on hours.');
        System.assertEquals(volunteerSchedule.Comments__c, hours[0].Comments__c, 'Expected the comments from the schedule to be populated on the hours.');
    }

    @IsTest
    private static void hoursShouldDetachWhenVolunteerScheduleNoLongerMatches() {
        Volunteer_Recurrence_Schedule__c volunteerSchedule = createVolunteerSchedule();
        volunteerSchedule.Days_of_Week__c = 'Monday;Friday';
        volunteerSchedule.Schedule_Start_Date_Time__c = Date.newInstance(2012,2,1);
        volunteerSchedule.Schedule_End_Date__c = Date.newInstance(2012,6,30);
        volunteerSchedule.Weekly_Occurrence__c = '1st';
        insert volunteerSchedule;

        Job_Recurrence_Schedule__c jobSchedule = createJobSchedule();
        jobSchedule.Schedule_Start_Date_Time__c = Date.newInstance(2012,1,1);
        jobSchedule.Schedule_End_Date__c = Date.newInstance(2012,12,31);
        jobSchedule.Weekly_Occurrence__c = 'Every';

        Test.startTest();
        insert jobSchedule;
        Test.stopTest();

        List<Volunteer_Hours__c> hours = getHours(volunteerSchedule.Id);
        hours[0].Status__c = 'Completed';
        update hours[0];

        volunteerSchedule.Days_of_Week__c = 'Wednesday';
        volunteerSchedule.Weekly_Occurrence__c = 'Alternate';
        update volunteerSchedule;

        hours = getHours(null);
        System.assertEquals(10, hours.size(), 'Expected the original hours to be orphaned.');  // 10 old ones

        hours = getHours(volunteerSchedule.Id);
        System.assertEquals(11, hours.size(), 'Expected new hours to be generated for the updated volunteer schedule.');  // 11 new ones
    }

    @IsTest
    private static void volunteerScheduleShouldNoLongerExistWhenJobIsDeleted() {
        Volunteer_Recurrence_Schedule__c volunteerSchedule = createVolunteerSchedule();
        insert volunteerSchedule;

        List<Volunteer_Recurrence_Schedule__c> volunteerSchedules = [SELECT Id FROM Volunteer_Recurrence_Schedule__c WHERE Volunteer_Job__c = :jobId];
        System.assertEquals(1, volunteerSchedules.size(), 'Expected the volunteer schedule to exist.');

        delete new Volunteer_Job__c(Id = jobId);
        volunteerSchedules = [SELECT Id FROM Volunteer_Recurrence_Schedule__c WHERE Id = :volunteerSchedules[0].Id];
        System.assertEquals(0, volunteerSchedules.size(), 'Expected the volunteer schedule to be deleted.');
    }

    //******************************************************************************************************
    // Test updating existing Volunteer Recurrence Schedules
    @IsTest
    private static void existingHourStatusShouldNotChangeWhenScheduleStatusChanges() {
        Volunteer_Recurrence_Schedule__c volunteerSchedule = createVolunteerSchedule();
        volunteerSchedule.Schedule_End_Date__c = endOfNextMonth;
        insert volunteerSchedule;

        Job_Recurrence_Schedule__c jobSchedule = createJobSchedule();
        jobSchedule.Weekly_Occurrence__c = '2nd';
        jobSchedule.Schedule_End_Date__c = endOfNextMonth;
        Test.startTest();
        insert jobSchedule;
        Test.stopTest();

        validateShifts(9, jobSchedule.Id);

        List<Volunteer_Hours__c> hours = getHours(volunteerSchedule.Id);
        System.assertEquals(6, hours.size());
        System.assertEquals(volunteerSchedule.Number_of_Volunteers__c, hours[0].Number_of_Volunteers__c);
        System.assertEquals(volunteerSchedule.Comments__c, hours[0].Comments__c);

        hours[0].Status__c = 'No-Show';
        update hours[0];

        volunteerSchedule.Days_of_Week__c = 'Monday;Friday';
        volunteerSchedule.Volunteer_Hours_Status__c = 'Confirmed';
        update volunteerSchedule;

        hours = getHours(volunteerSchedule.Id);
        System.assertEquals(6, hours.size());

        hours = [SELECT Id, Status__c FROM Volunteer_Hours__c WHERE Status__c = 'Testing' and Volunteer_Recurrence_Schedule__c = :volunteerSchedule.Id];
        System.assert(hours.size() >= 0 && hours.size() <= 3);

        hours = [SELECT Id, Status__c FROM Volunteer_Hours__c WHERE Status__c = 'No-Show' and Volunteer_Recurrence_Schedule__c = :volunteerSchedule.Id];
        System.assertEquals(1, hours.size());

        hours = [SELECT Id, Status__c FROM Volunteer_Hours__c WHERE Status__c = 'Confirmed' and Volunteer_Recurrence_Schedule__c = :volunteerSchedule.Id];
        System.assert(hours.size() >= 3);
    }

    //******************************************************************************************************
    // Test updating existing Volunteer Recurrence Schedules deletes future Hours that no longer match VRS
    @IsTest
    private static void futureHoursShouldBeDeletedWhenScheduleIsModifiedToNoLongerMatche() {
        Date startDate = System.today().addmonths(1).toStartOfMonth();
        Date endDate = System.today().addmonths(3).toStartOfMonth().addDays(-1);

        Job_Recurrence_Schedule__c jobSchedule = createJobSchedule();
        jobSchedule.Schedule_Start_Date_Time__c = startDate;
        jobSchedule.Schedule_End_Date__c = endDate;
        jobSchedule.Days_of_Week__c = 'Monday;Wednesday;Friday';
        insert jobSchedule;

        validateShifts(6, jobSchedule.Id);

        Volunteer_Recurrence_Schedule__c volunteerSchedule = createVolunteerSchedule();
        volunteerSchedule.Schedule_Start_Date_Time__c = startDate;
        volunteerSchedule.Schedule_End_Date__c = endDate;
        insert volunteerSchedule;

        List<Volunteer_Hours__c> hours = getHours(volunteerSchedule.Id);
        System.assertEquals(4, hours.size());
        System.assertEquals(volunteerSchedule.Number_of_Volunteers__c, hours[0].Number_of_Volunteers__c);
        System.assertEquals(volunteerSchedule.Comments__c, hours[0].Comments__c);

        // update first Wednesday
        hours[1].Status__c = 'Completed';
        update hours[1];

        volunteerSchedule.Days_of_Week__c = 'Monday;Friday';
        volunteerSchedule.Volunteer_Hours_Status__c = 'Confirmed';
        Test.startTest();
        update volunteerSchedule;
        Test.stopTest();

        hours = [SELECT Id, Status__c, Planned_Start_Date_Time__c FROM Volunteer_Hours__c];
        System.assertEquals(5, hours.size());

        hours = [SELECT Id, Status__c FROM Volunteer_Hours__c WHERE Status__c = 'Testing'];
        System.assertEquals(2, hours.size());

        hours = [SELECT Id, Status__c FROM Volunteer_Hours__c WHERE Status__c = 'Completed'];
        System.assertEquals(1, hours.size());

        hours = [SELECT Id, Status__c FROM Volunteer_Hours__c WHERE Status__c = 'Confirmed'];
        System.assertEquals(2, hours.size());
    }

    //******************************************************************************************************
    // Test updating existing Volunteer Recurrence Schedules reuses, but updates, Hours
    @IsTest
    private static void futureHoursShouldSyncWithVolunteerScheduleChanges() {

        Job_Recurrence_Schedule__c jobSchedule = createJobSchedule();
        insert jobSchedule;

        validateShifts(6, jobSchedule.Id);

        Volunteer_Recurrence_Schedule__c volunteerSchedule = createVolunteerSchedule();
        insert volunteerSchedule;
        Volunteer_Recurrence_Schedule__c vrsOriginal = volunteerSchedule.clone();

        List<Volunteer_Hours__c> hours = getHours(volunteerSchedule.Id);
        System.assertEquals(4, hours.size());
        System.assertEquals(volunteerSchedule.Number_of_Volunteers__c, hours[0].Number_of_Volunteers__c);
        System.assertEquals(volunteerSchedule.Comments__c, hours[0].Comments__c);

        // update all fields that should update future hours, but not past hours
        volunteerSchedule.Volunteer_Hours_Status__c = 'Confirmed';
        volunteerSchedule.Duration__c = 1;
        volunteerSchedule.Number_of_Volunteers__c = 1;
        volunteerSchedule.Comments__c = 'new comments';
        volunteerSchedule.Schedule_Start_Date_Time__c = volunteerSchedule.Schedule_Start_Date_Time__c.addMinutes(10);
        Test.startTest();
        update volunteerSchedule;
        Test.stopTest();

        hours = [SELECT Id, Status__c, Planned_Start_Date_Time__c, Hours_Worked__c, Number_Of_Volunteers__c, Comments__c FROM Volunteer_Hours__c];
        System.assertEquals(4, hours.size());

        for (Volunteer_Hours__c hr : hours) {
            if (hr.Planned_Start_Date_Time__c.date() >= System.Today()) {
                System.assertEquals(vrsOriginal.Volunteer_Hours_Status__c, hr.Status__c); // no longer update Status!
                System.assertEquals(volunteerSchedule.Duration__c, hr.Hours_Worked__c);
                System.assertEquals(volunteerSchedule.Number_of_Volunteers__c, hr.Number_of_Volunteers__c);
                System.assertEquals(volunteerSchedule.Comments__c, hr.Comments__c);
                System.assertEquals(volunteerSchedule.Schedule_Start_Date_Time__c.Time(), hr.Planned_Start_Date_Time__c.Time());
            } else {
                System.assertEquals(vrsOriginal.Volunteer_Hours_Status__c, hr.Status__c);
                System.assertEquals(vrsOriginal.Duration__c, hr.Hours_Worked__c);
                System.assertEquals(vrsOriginal.Number_of_Volunteers__c, hr.Number_of_Volunteers__c);
                System.assertEquals(vrsOriginal.Comments__c, hr.Comments__c);
                System.assertEquals(vrsOriginal.Schedule_Start_Date_Time__c.Time(), hr.Planned_Start_Date_Time__c.Time());
            }
        }

    }

    //******************************************************************************************************
    // Test updating existing Volunteer Recurrence Schedule's job, deletes old hours and creates new hours.
    @IsTest
    private static void newHoursShouldGenerateWhenJobChanges() {
        Date startDate = System.today().addmonths(1).toStartOfMonth();
        Date endDate = System.today().addmonths(3).toStartOfMonth().addDays(-1);

        Id campaignId = [SELECT Id FROM Campaign LIMIT 1].Id;
        Volunteer_Job__c job2 = new Volunteer_Job__c(
            Name = 'Other Job',
            Campaign__c = campaignId
        );
        insert job2;

        Job_Recurrence_Schedule__c jobSchedule = createJobSchedule();
        jobSchedule.Schedule_Start_Date_Time__c = startDate;
        jobSchedule.Schedule_End_Date__c = endDate;
        insert jobSchedule;

        Job_Recurrence_Schedule__c jobSchedule2 = createJobSchedule();
        jobSchedule2.Volunteer_Job__c = job2.Id;
        jobSchedule2.Schedule_Start_Date_Time__c = startDate;
        jobSchedule2.Schedule_End_Date__c = endDate;
        insert jobSchedule2;

        validateShifts(6, jobSchedule.Id);
        validateShifts(6, jobSchedule2.Id);

        Volunteer_Recurrence_Schedule__c volunteerSchedule = createVolunteerSchedule();
        volunteerSchedule.Schedule_Start_Date_Time__c = startDate;
        volunteerSchedule.Schedule_End_Date__c = endDate;
        insert volunteerSchedule;

        List<Volunteer_Hours__c> hours = getHours(volunteerSchedule.Id);
        System.assertEquals(4, hours.size());
        System.assertEquals(volunteerSchedule.Number_of_Volunteers__c, hours[0].Number_of_Volunteers__c);
        System.assertEquals(volunteerSchedule.Comments__c, hours[0].Comments__c);

        volunteerSchedule.Volunteer_Job__c = job2.Id;
        Test.startTest();
        update volunteerSchedule;
        Test.stopTest();

        hours = [SELECT Id, Status__c, Planned_Start_Date_Time__c, Hours_Worked__c, Number_Of_Volunteers__c, Comments__c
            FROM Volunteer_Hours__c WHERE Volunteer_Job__c = :jobId];
        System.assertEquals(0, hours.size());

        hours = [SELECT Id, Status__c, Planned_Start_Date_Time__c, Hours_Worked__c, Number_Of_Volunteers__c, Comments__c
            FROM Volunteer_Hours__c WHERE Volunteer_Job__c = :job2.Id];
        System.assertEquals(4, hours.size());
   }

    //******************************************************************************************************
    // Test have a Contact with multiple  Volunteer Recurrence Schedules to same Job, both VRS's exist
    // before the jobSchedule is inserted
    @IsTest
    private static void duplicateHoursShouldNotGenerateWhenJobScheduleCreatedForVolunteerSchedulesWithOverlap() {
        Volunteer_Recurrence_Schedule__c volunteerSchedule = createVolunteerSchedule();
        volunteerSchedule.Days_of_Week__c = 'Monday';
        volunteerSchedule.Volunteer_Hours_Status__c = 'My Custom Status1';
        insert volunteerSchedule;

        Volunteer_Recurrence_Schedule__c volunteerSchedule2 = createVolunteerSchedule();
        volunteerSchedule2.Volunteer_Hours_Status__c = 'My Custom Status2';
        insert volunteerSchedule2;

        Job_Recurrence_Schedule__c jobSchedule = createJobSchedule();
        Test.startTest();
        insert jobSchedule;
        Test.stopTest();

        validateShifts(6, jobSchedule.Id);

        List<Volunteer_Hours__c> hours = [SELECT Id, Status__c, Number_of_Volunteers__c, Comments__c
            FROM Volunteer_Hours__c ORDER BY Planned_Start_Date_Time__c];
        System.assertEquals(4, hours.size());

        hours = getHours(volunteerSchedule.Id);
        System.assertEquals(2, hours.size());

        hours = getHours(volunteerSchedule2.Id);
        System.assertEquals(2, hours.size());

        hours = [SELECT Id, Status__c FROM Volunteer_Hours__c WHERE Status__c = 'My Custom Status1' ];
        System.assertEquals(2, hours.size());

        hours = [SELECT Id, Status__c FROM Volunteer_Hours__c WHERE Status__c = 'My Custom Status2' ];
        System.assertEquals(2, hours.size());
    }

    //******************************************************************************************************
    // Test have a Contact with multiple Volunteer Recurrence Schedules to same Job, One jobSchedule inserted, then
    // VRS insert, and then second VRS inserted.
    @IsTest
    private static void hoursShouldNotBeReparentedWhenVolunteerScheduleIsCreatedWithOverlap() {
        Volunteer_Recurrence_Schedule__c volunteerSchedule = createVolunteerSchedule();
        volunteerSchedule.Days_of_Week__c = 'Monday';
        volunteerSchedule.Volunteer_Hours_Status__c = 'My Custom Status1';
        insert volunteerSchedule;

        Job_Recurrence_Schedule__c jobSchedule = createJobSchedule();
        Test.startTest();
        insert jobSchedule;
        Test.stopTest();

        Volunteer_Recurrence_Schedule__c volunteerSchedule2 = createVolunteerSchedule();
        volunteerSchedule2.Volunteer_Hours_Status__c = 'My Custom Status2';
        insert volunteerSchedule2;

        validateShifts(6, jobSchedule.Id);

        List<Volunteer_Hours__c> hours = [SELECT Id, Status__c, Number_of_Volunteers__c, Comments__c
            FROM Volunteer_Hours__c ORDER BY Planned_Start_Date_Time__c];
        System.assertEquals(4, hours.size());

        hours = getHours(volunteerSchedule.Id);
        System.assertEquals(2, hours.size());

        hours = getHours(volunteerSchedule2.Id);
        System.assertEquals(2, hours.size());

        hours = [SELECT Id, Status__c FROM Volunteer_Hours__c WHERE Status__c = 'My Custom Status1' ];
        System.assertEquals(2, hours.size());

        hours = [SELECT Id, Status__c FROM Volunteer_Hours__c WHERE Status__c = 'My Custom Status2' ];
        System.assertEquals(2, hours.size());
    }

    //******************************************************************************************************
    // Test have a Contact with multiple Volunteer Recurrence Schedules to same Job, both VRS's exist
    // before the jobSchedule is inserted.  These VRS's don't overlap on dates.
    @IsTest
    private static void hoursShouldGenerateForMultipleVolunteerSchedulesSameContactWithoutOverlap() {
        DateTime startDate = Datetime.newInstance(System.today().addmonths(1).toStartOfMonth(), Time.newInstance(0,0,0,0));
        DateTime startDate2 = Datetime.newInstance(System.today().addmonths(2).toStartOfMonth(), Time.newInstance(0,0,0,0));
        Date endDate2 = System.today().addmonths(3).toStartOfMonth().addDays(-1);

        Volunteer_Recurrence_Schedule__c volunteerSchedule = createVolunteerSchedule();
        volunteerSchedule.Volunteer_Hours_Status__c = 'My Custom Status1';
        volunteerSchedule.Schedule_Start_Date_Time__c = startDate;
        volunteerSchedule.Schedule_End_Date__c = endOfNextMonth;
        insert volunteerSchedule;

        Volunteer_Recurrence_Schedule__c volunteerSchedule2 = createVolunteerSchedule();
        volunteerSchedule2.Volunteer_Hours_Status__c = 'My Custom Status2';
        volunteerSchedule2.Schedule_Start_Date_Time__c = startDate2;
        volunteerSchedule2.Schedule_End_Date__c = endDate2;
        insert volunteerSchedule2;

        Job_Recurrence_Schedule__c jobSchedule = createJobSchedule();
        jobSchedule.Schedule_Start_Date_Time__c = startDate;
        jobSchedule.Schedule_End_Date__c = endDate2;
        Test.startTest();
        insert jobSchedule;
        Test.stopTest();

        validateShifts(6, jobSchedule.Id);

        List<Volunteer_Hours__c> hours = [SELECT Id, Status__c, Planned_Start_Date_Time__c, Number_of_Volunteers__c, Comments__c
            FROM Volunteer_Hours__c ORDER BY Planned_Start_Date_Time__c];
        System.assertEquals(4, hours.size());

        hours = getHours(volunteerSchedule.Id);
        System.assertEquals(2, hours.size());

        hours = getHours(volunteerSchedule2.Id);
        System.assertEquals(2, hours.size());

        hours = [SELECT Id, Status__c FROM Volunteer_Hours__c WHERE Status__c = 'My Custom Status1' ];
        System.assertEquals(2, hours.size());

        hours = [SELECT Id, Status__c FROM Volunteer_Hours__c WHERE Status__c = 'My Custom Status2' ];
        System.assertEquals(2, hours.size());
    }

    //******************************************************************************************************
    // Test have two Contacts with VRS's to same Job, One jobSchedule inserted, then
    // VRS insert, and then second VRS inserted.  Hours from first VRS should not be affected.
    @IsTest
    private static void hoursShouldGenerateForMultipleVolunteerSchedulesDifferentContacts() {
        Contact contactRecord2 = new Contact(
            FirstName = 'Johnny',
            LastName = 'BeGood');
        insert contactRecord2;

        Volunteer_Recurrence_Schedule__c volunteerSchedule = createVolunteerSchedule();
        volunteerSchedule.Days_of_Week__c = 'Monday';
        volunteerSchedule.Schedule_End_Date__c = endOfNextMonth;
        insert volunteerSchedule;

        Job_Recurrence_Schedule__c jobSchedule = createJobSchedule();
        jobSchedule.Days_of_Week__c = 'Monday;';
        jobSchedule.Schedule_End_Date__c = endOfNextMonth;
        Test.startTest();
        insert jobSchedule;
        Test.stopTest();

        validateShifts(3, jobSchedule.Id);
        List<Volunteer_Shift__c> listShift = [SELECT Id, Name, Volunteer_Job__r.Name FROM Volunteer_Shift__c WHERE Job_Recurrence_Schedule__c = :jobSchedule.Id];
        System.assertEquals(3, listShift.size());

        // update both past and future Hours for c1
        List<Volunteer_Hours__c> hours = [SELECT Id, Status__c, Comments__c, Planned_Start_Date_Time__c FROM Volunteer_Hours__c ORDER BY Planned_Start_Date_Time__c];
        System.assertEquals(3, hours.size());
        for (Volunteer_Hours__c hr : hours) {
            hr.Status__c = 'My Manual Status1';
            hr.Comments__c = 'My Manual Comments1';
        }
        update hours;

        Volunteer_Recurrence_Schedule__c volunteerSchedule2 = createVolunteerSchedule();
        volunteerSchedule2.Contact__c = contactRecord2.Id;
        volunteerSchedule2.Days_of_Week__c = 'Monday;';
        volunteerSchedule2.Schedule_End_Date__c = endOfNextMonth;
        insert volunteerSchedule2;

        // make sure VRS1's hours untouched
        List<Volunteer_Hours__c> listHours1 = [SELECT Id, Status__c, Comments__c, Planned_Start_Date_Time__c FROM Volunteer_Hours__c WHERE Contact__c = :contactId ORDER BY Planned_Start_Date_Time__c];
        System.debug('****DJH listHours1: ' + listHours1);
        System.assertEquals(hours.size(), listHours1.size());
        for (integer i = 0; i < hours.size(); i++) {
            System.assertEquals(hours[i].Status__c, listHours1[i].Status__c);
            System.assertEquals(hours[i].Comments__c, listHours1[i].Comments__c);
        }

        // now verify VRS2's hours
        hours = [SELECT Id, Status__c, Comments__c, Planned_Start_Date_Time__c FROM Volunteer_Hours__c where Contact__c = :contactRecord2.Id ORDER BY Planned_Start_Date_Time__c];
        System.debug('****DJH listHours2: ' + hours);
        System.assertEquals(3, hours.size());
        for (integer i = 0; i < hours.size(); i++) {
            System.assertEquals(volunteerSchedule2.Volunteer_Hours_Status__c, hours[i].Status__c);
            System.assertEquals(volunteerSchedule2.Comments__c, hours[i].Comments__c);
        }
    }

    //******************************************************************************************************
    // Test deleting existing Volunteer Recurrence Schedules deletes future Hours, detaches past Hours
    @IsTest
    private static void pastHoursShouldDetachAndFutureHoursShouldBeDeletedWhenVolunteerScheduleIsDeleted() {
        Job_Recurrence_Schedule__c jobSchedule = createJobSchedule();
        jobSchedule.Days_of_Week__c = 'Monday;Wednesday;Friday';
        jobSchedule.Schedule_End_Date__c = endOfNextMonth;
        insert jobSchedule;

        validateShifts(9, jobSchedule.Id);

        Volunteer_Recurrence_Schedule__c volunteerSchedule = createVolunteerSchedule();
        volunteerSchedule.Schedule_End_Date__c = endOfNextMonth;
        insert volunteerSchedule;

        List<Volunteer_Hours__c> hours = getHours(volunteerSchedule.Id);
        System.assertEquals(6, hours.size());
        System.assertEquals(volunteerSchedule.Number_of_Volunteers__c, hours[0].Number_of_Volunteers__c);
        System.assertEquals(volunteerSchedule.Comments__c, hours[0].Comments__c);

        // update last Wednesday
        hours[5].Status__c = 'Completed';
        update hours[5];
        // update last Monday
        hours[4].Status__c = 'Canceled';
        update hours[4];

        integer cPastHrs = 0;
        integer cFutureHrs = 0;
        for (Volunteer_Hours__c hr : hours) {
            if (hr.Shift_Start_Date_Time__c < System.Today())
                cPastHrs++;
            else
                cFutureHrs++;
        }
        System.assertEquals(6, cPastHrs + cFutureHrs);

        Test.startTest();
        delete volunteerSchedule;
        Test.stopTest();

        hours = [SELECT Id, Status__c, Planned_Start_Date_Time__c FROM Volunteer_Hours__c];
        System.assertEquals(cPastHrs + 2, hours.size());

        hours = [SELECT Id, Status__c FROM Volunteer_Hours__c WHERE Status__c = 'Testing'];
        System.assertEquals(cPastHrs, hours.size());

        hours = [SELECT Id, Status__c FROM Volunteer_Hours__c WHERE Status__c = 'Completed'];
        System.assertEquals(1, hours.size());

        hours = [SELECT Id, Status__c FROM Volunteer_Hours__c WHERE Status__c = 'Canceled'];
        System.assertEquals(1, hours.size());
    }

    //******************************************************************************************************
    // Test shortening existing Volunteer Recurrence Schedules deletes future Hours, detaches past Hours
    @IsTest
    private static void pastHoursShouldDetachAndFutureHoursShouldBeDeletedWhenVolunteerScheduleIsShortened() {
        Date endDate = System.today().addmonths(3).toStartOfMonth().addDays(-1);

        Job_Recurrence_Schedule__c jobSchedule = createJobSchedule();
        jobSchedule.Schedule_End_Date__c = endDate;
        jobSchedule.Weekly_Occurrence__c = '2nd';
        insert jobSchedule;

        validateShifts(12, jobSchedule.Id);

        Volunteer_Recurrence_Schedule__c volunteerSchedule = createVolunteerSchedule();
        volunteerSchedule.Schedule_End_Date__c = endDate;
        insert volunteerSchedule;

        List<Volunteer_Hours__c> hours = getHours(volunteerSchedule.Id);
        System.assertEquals(8, hours.size());
        System.assertEquals(volunteerSchedule.Number_of_Volunteers__c, hours[0].Number_of_Volunteers__c);
        System.assertEquals(volunteerSchedule.Comments__c, hours[0].Comments__c);

        // update last Wednesday
        hours[7].Status__c = 'Completed';
        update hours[7];
        // update last Monday
        hours[6].Status__c = 'Canceled';
        update hours[6];

        Test.startTest();
        volunteerSchedule.Schedule_End_Date__c = System.today().addMonths(1).toStartOfMonth().addDays(-1);
        update volunteerSchedule;
        Test.stopTest();

        hours = [SELECT Id, Status__c, Planned_Start_Date_Time__c FROM Volunteer_Hours__c];
        // last month, this month, and the two futures we marked canceled/completed
        System.assertEquals(2 + 2 + 2, hours.size());

        hours = [SELECT Id, Status__c FROM Volunteer_Hours__c WHERE Status__c = 'Testing'];
        System.assertEquals(4, hours.size());

        hours = [SELECT Id, Status__c FROM Volunteer_Hours__c WHERE Status__c = 'Completed'];
        System.assertEquals(1, hours.size());

        hours = [SELECT Id, Status__c FROM Volunteer_Hours__c WHERE Status__c = 'Canceled'];
        System.assertEquals(1, hours.size());
    }

    /**
     * Verifies multiple volunteer recurrence schedules can exist for a single contact that is
     * signing up for multiple shifts that do not overlap.
     */
    @IsTest
    private static void hoursShouldGenerateForVolunteerSchedulesWithSameJobAndContactDifferentTimes() {
        DateTime startTime = DateTime.newInstance(System.today().addmonths(-1).toStartOfMonth(), Time.newInstance(10,0,0,0));

        Job_Recurrence_Schedule__c jobSchedule = createJobSchedule();
        jobSchedule.Days_of_Week__c = 'Monday;';
        jobSchedule.Weekly_Occurrence__c = '2nd';
        jobSchedule.Duration__c = 1;
        jobSchedule.Schedule_Start_Date_Time__c = startTime;
        jobSchedule.Schedule_End_Date__c = null;
        insert jobSchedule;

        List<Volunteer_Shift__c> shifts1 = getShifts(jobId);

        Job_Recurrence_Schedule__c jobSchedule2 = createJobSchedule();
        jobSchedule2.Days_of_Week__c = 'Monday;';
        jobSchedule2.Weekly_Occurrence__c = '2nd';
        jobSchedule2.Duration__c = 1;
        jobSchedule2.Schedule_Start_Date_Time__c = startTime.addHours(2);
        jobSchedule2.Schedule_End_Date__c = null;
        insert jobSchedule2;

        List<Volunteer_Shift__c> shifts2 = getShifts(jobId);
        System.assertEquals(shifts2.size(), shifts1.size()*2, 'Double the number of shifts should exist after second jobSchedule is inserted.');

        Volunteer_Recurrence_Schedule__c volunteerSchedule = createVolunteerSchedule();
        volunteerSchedule.Days_of_Week__c = 'Monday';
        volunteerSchedule.Schedule_Start_Date_Time__c = startTime;
        volunteerSchedule.Schedule_End_Date__c = null;
        insert volunteerSchedule;

        List<Volunteer_Hours__c> vrs1hours = getHours(volunteerSchedule.Id);

        System.assertEquals(6, vrs1hours.size(), 'The number of hours was not as expected.');

        Volunteer_Recurrence_Schedule__c volunteerSchedule2 = createVolunteerSchedule();
        volunteerSchedule2.Days_of_Week__c = 'Monday';
        volunteerSchedule2.Schedule_Start_Date_Time__c = startTime.addHours(2);

        Test.startTest();
        insert volunteerSchedule2;
        Test.stopTest();

        // make sure VRS1's hours untouched
        List<Volunteer_Hours__c> vrs1hoursAfterUpdate = getHours(volunteerSchedule.Id);

        System.assertEquals(vrs1hours.size(), vrs1hoursAfterUpdate.size(), 'The number of hours was not expected to change.');
    }


    ///
    /// Helpers
    ///

    /**
     * Validate shifts were created
     */
    private static void validateShifts(Integer expectedSize, Id jobScheduleId) {
        List<Volunteer_Shift__c> shifts = getShifts(jobScheduleId);
        System.assertEquals(expectedSize, shifts.size(), 'The number of shifts was not as expected.');
    }

    private static List<Volunteer_Hours__c> getHours(Id volunteerScheduleId) {
        return [
            SELECT Id, Status__c, Number_of_Volunteers__c, Comments__c, Shift_Start_Date_Time__c
            FROM Volunteer_Hours__c
            WHERE Volunteer_Recurrence_Schedule__c = :volunteerScheduleId
        ];
    }

    /**
     * Returns the shifts related to the jobScheduleId provided
     */
    private static List<Volunteer_Shift__c> getShifts(Id jobScheduleId) {
        return [SELECT Id, Name, Volunteer_Job__r.Name FROM Volunteer_Shift__c WHERE Job_Recurrence_Schedule__c = :jobScheduleId];
    }

    /**
     * Create a Volunteer Schedule with default data
     */
    private static Volunteer_Recurrence_Schedule__c createVolunteerSchedule() {
        Volunteer_Recurrence_Schedule__c volunteerSchedule = new Volunteer_Recurrence_Schedule__c(
            Contact__c = contactId,
            Volunteer_Job__c = jobId,
            Volunteer_Hours_Status__c = 'Testing',
            Days_of_Week__c = 'Monday;Wednesday',
            Duration__c = 1.5,
            Number_of_Volunteers__c = 2,
            Comments__c = 'One starfish!',
            Schedule_Start_Date_Time__c = startOfLastMonth,
            Schedule_End_Date__c = startOfLastMonth.addMonths(2),
            Weekly_Occurrence__c = '2nd'
        );

        return volunteerSchedule;
    }

    /**
     * Create a Job Recurrence schedule with default data
     */
    private static Job_Recurrence_Schedule__c createJobSchedule() {
        Job_Recurrence_Schedule__c jobSchedule = new Job_Recurrence_Schedule__c(
            Volunteer_Job__c = jobId,
            Days_of_Week__c = 'Monday;Wednesday;Friday',
            Duration__c = 4,
            Schedule_Start_Date_Time__c = startOfLastMonth,
            Schedule_End_Date__c = startOfLastMonth.addMonths(2),
            Weekly_Occurrence__c = '2nd',
            Desired_Number_of_Volunteers__c = 5
        );

        return jobSchedule;
    }
}