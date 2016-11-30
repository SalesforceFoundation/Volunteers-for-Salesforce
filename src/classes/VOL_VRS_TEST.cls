/*
    Copyright (c) 2010, 2016, David Habib, DJH Consulting, djhconsulting.com
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    1. Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
    2. Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
    3. Neither the name of the copyright holder nor the names of
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
public with sharing class VOL_VRS_TEST {

    //******************************************************************************************************
    // Test Volunteer Recurrence Schedules
    public static testmethod void TestVRS() {

        // create test data
        Campaign cmp = new Campaign(recordtypeid=VOL_SharedCode.recordtypeIdVolunteersCampaign, 
            name='Job Calendar Test Campaign', IsActive=true);
        insert cmp;
        Volunteer_Job__c job = new Volunteer_Job__c(name='Job1', campaign__c=cmp.Id);
        insert job;
        Contact contact = new Contact(firstname='test', lastname='test');
        insert contact;
        
        Volunteer_Recurrence_Schedule__c vrs = new Volunteer_Recurrence_Schedule__c(
            Contact__c = contact.Id, 
            Volunteer_Job__c = job.Id,
            Days_of_Week__c = 'Monday;Friday',
            Duration__c = 1.5,
            Number_of_Volunteers__c = 2,
            Comments__c = 'my comments!',
            Schedule_Start_Date_Time__c = date.newInstance(2012,2,1),
            Schedule_End_Date__c = date.newInstance(2012,6,30),
            Weekly_Occurrence__c = '1st');
        insert vrs;
        
        system.assertEquals(true, VOL_VRS.alternateWeekVRS(vrs, date.newInstance(2012,2,1)));
        system.assertEquals(true, VOL_VRS.alternateWeekVRS(vrs, date.newInstance(2012,2,4)));
        system.assertEquals(false, VOL_VRS.alternateWeekVRS(vrs, date.newInstance(2012,2,6)));
        system.assertEquals(false, VOL_VRS.alternateWeekVRS(vrs, date.newInstance(2012,2,11)));
        system.assertEquals(true, VOL_VRS.alternateWeekVRS(vrs, date.newInstance(2012,2,13)));
            
        Job_Recurrence_Schedule__c jrs = new Job_Recurrence_Schedule__c(Volunteer_Job__c = job.Id);
        jrs.Days_of_Week__c = 'Monday;Wednesday;Friday';
        jrs.Duration__c = 1;
        jrs.Schedule_Start_Date_Time__c = date.newInstance(2012,1,1);
        jrs.Schedule_End_Date__c = date.newInstance(2012,12,31);
        jrs.Weekly_Occurrence__c = 'Every';
        jrs.Desired_Number_of_Volunteers__c = 5;
        Test.startTest();
        insert jrs;
        Test.stopTest(); 
        
        list<Volunteer_Shift__c> listShift = [select Id, Name, Volunteer_Job__r.Name from Volunteer_Shift__c where Job_Recurrence_Schedule__c = :jrs.Id];
        system.debug(listShift);
        system.assertEquals(157, listShift.size());
        
        list<Volunteer_Hours__c> listHours = [select Id, Status__c, Number_of_Volunteers__c, Comments__c 
            from Volunteer_Hours__c where Volunteer_Recurrence_Schedule__c = :vrs.Id];
        system.assertEquals(10, listHours.size());
        system.assertEquals(vrs.Number_of_Volunteers__c, listHours[0].Number_of_Volunteers__c);
        system.assertEquals(vrs.Comments__c, listHours[0].Comments__c);
        
        listHours[0].Status__c = 'Completed';
        update listHours[0];
        
        vrs.Days_of_Week__c = 'Wednesday';
        vrs.Weekly_Occurrence__c = 'Alternate';
        update vrs;
        
        listHours = [select Id, Status__c from Volunteer_Hours__c where Volunteer_Recurrence_Schedule__c = :vrs.Id];
        system.assertEquals(12, listHours.size());  // 11 new ones, plus the completed one saved.
        
        // remember those hours
        set<ID> setHoursId = new set<ID>();
        for (Volunteer_Hours__c hour : listHours) {
            setHoursId.add(hour.Id);
        }
        
        // test deleting the vrs to cleanup non committed hours
        delete vrs;     
        listHours = [select Id, Status__c from Volunteer_Hours__c where Id in :setHoursId];
        system.assertEquals(1, listHours.size());
        
        // test deleting a Job will also delete the vrs's
        vrs = new Volunteer_Recurrence_Schedule__c(
            Contact__c = contact.Id, 
            Volunteer_Job__c = job.Id,
            Days_of_Week__c = 'Monday;Friday',
            Duration__c = 1.5,
            Schedule_Start_Date_Time__c = date.newInstance(2012, 2, 1),
            Schedule_End_Date__c = date.newInstance(2012,6,30),
            Weekly_Occurrence__c = '1st');
        insert vrs;
        
        list<Volunteer_Recurrence_Schedule__c> listVRS = [select Id from Volunteer_Recurrence_Schedule__c where Volunteer_Job__c = :job.Id];
        system.assertEquals(1, listVRS.size());
        delete job;
        listVRS = [select Id from Volunteer_Recurrence_Schedule__c where Id = :listVRS[0].Id];
        system.assertEquals(0, listVRS.size());
                        
    }
    
    //******************************************************************************************************
    // Test updating existing Volunteer Recurrence Schedules
    public static testmethod void TestVRSUpdate() {

        // create test data
        Campaign cmp = new Campaign(recordtypeid=VOL_SharedCode.recordtypeIdVolunteersCampaign, 
            name='Job Calendar Test Campaign', IsActive=true);
        insert cmp;
        Volunteer_Job__c job = new Volunteer_Job__c(name='Job1', campaign__c=cmp.Id);
        insert job;
        Contact contact = new Contact(firstname='test', lastname='test');
        insert contact;
        
        Volunteer_Recurrence_Schedule__c vrs = new Volunteer_Recurrence_Schedule__c(
            Contact__c = contact.Id, 
            Volunteer_Job__c = job.Id,
            Volunteer_Hours_Status__c = 'My Custom Status',
            Days_of_Week__c = 'Monday;Wednesday',
            Duration__c = 1.5,
            Number_of_Volunteers__c = 2,
            Comments__c = 'my comments!',
            Schedule_Start_Date_Time__c = date.newInstance(2016,11,1),
            Schedule_End_Date__c = date.newInstance(2016,12,31),
            Weekly_Occurrence__c = '2nd');
        insert vrs;
        
        Job_Recurrence_Schedule__c jrs = new Job_Recurrence_Schedule__c(Volunteer_Job__c = job.Id);
        jrs.Days_of_Week__c = 'Monday;Wednesday;Friday';
        jrs.Duration__c = 1;
        jrs.Schedule_Start_Date_Time__c = date.newInstance(2016,11,1);
        jrs.Schedule_End_Date__c = date.newInstance(2016,12,31);
        jrs.Weekly_Occurrence__c = '2nd';
        jrs.Desired_Number_of_Volunteers__c = 5;
        Test.startTest();
        insert jrs;
        Test.stopTest(); 
        
        list<Volunteer_Shift__c> listShift = [select Id, Name, Volunteer_Job__r.Name from Volunteer_Shift__c where Job_Recurrence_Schedule__c = :jrs.Id];
        //system.debug(listShift);
        system.assertEquals(6, listShift.size());
        
        list<Volunteer_Hours__c> listHours = [select Id, Status__c, Number_of_Volunteers__c, Comments__c 
            from Volunteer_Hours__c where Volunteer_Recurrence_Schedule__c = :vrs.Id order by Planned_Start_Date_Time__c];
        system.assertEquals(4, listHours.size());
        system.assertEquals(vrs.Number_of_Volunteers__c, listHours[0].Number_of_Volunteers__c);
        system.assertEquals(vrs.Comments__c, listHours[0].Comments__c);
        
        listHours[0].Status__c = 'No-Show';
        //system.debug('****DJH updating hr: '+ listHours[0]); 
        update listHours[0];
        
        vrs.Days_of_Week__c = 'Monday;Friday';
        vrs.Volunteer_Hours_Status__c = 'Confirmed';
        update vrs;

        listHours = [select Id, Status__c, Planned_Start_Date_Time__c from Volunteer_Hours__c where Volunteer_Recurrence_Schedule__c = :vrs.Id order by Planned_Start_Date_Time__c];
        //system.debug('****DJH listHours: ' + listHours);
        
        listHours = [select Id, Status__c from Volunteer_Hours__c where Status__c = 'My Custom Status' and Volunteer_Recurrence_Schedule__c = :vrs.Id];
        system.assertEquals(1, listHours.size());  // first Monday was changed to no-show
        
        listHours = [select Id, Status__c from Volunteer_Hours__c where Status__c = 'No-Show' and Volunteer_Recurrence_Schedule__c = :vrs.Id];
        system.assertEquals(1, listHours.size());  

        listHours = [select Id, Status__c from Volunteer_Hours__c where Status__c = 'Confirmed' and Volunteer_Recurrence_Schedule__c = :vrs.Id];
        system.assertEquals(2, listHours.size());  
    }
    
    //******************************************************************************************************
    // Test updating existing Volunteer Recurrence Schedules deletes Hours that no longer match VRS
    public static testmethod void TestVRSHoursDelete() {

        // create test data
        Campaign cmp = new Campaign(recordtypeid=VOL_SharedCode.recordtypeIdVolunteersCampaign, 
            name='Job Calendar Test Campaign', IsActive=true);
        insert cmp;
        Volunteer_Job__c job = new Volunteer_Job__c(name='Job1', campaign__c=cmp.Id);
        insert job;
        Contact contact = new Contact(firstname='test', lastname='test');
        insert contact;
        
        Job_Recurrence_Schedule__c jrs = new Job_Recurrence_Schedule__c(Volunteer_Job__c = job.Id);
        jrs.Days_of_Week__c = 'Monday;Wednesday;Friday';
        jrs.Duration__c = 1;
        jrs.Schedule_Start_Date_Time__c = date.newInstance(2016,11,1);
        jrs.Schedule_End_Date__c = date.newInstance(2016,12,31);
        jrs.Weekly_Occurrence__c = '2nd';
        jrs.Desired_Number_of_Volunteers__c = 5;
        insert jrs;
        
        list<Volunteer_Shift__c> listShift = [select Id, Name, Volunteer_Job__r.Name from Volunteer_Shift__c where Job_Recurrence_Schedule__c = :jrs.Id];
        system.assertEquals(6, listShift.size());
        
        Volunteer_Recurrence_Schedule__c vrs = new Volunteer_Recurrence_Schedule__c(
            Contact__c = contact.Id, 
            Volunteer_Job__c = job.Id,
            Volunteer_Hours_Status__c = 'My Custom Status',
            Days_of_Week__c = 'Monday;Wednesday',
            Duration__c = 1.5,
            Number_of_Volunteers__c = 2,
            Comments__c = 'my comments!',
            Schedule_Start_Date_Time__c = date.newInstance(2016,11,1),
            Schedule_End_Date__c = date.newInstance(2016,12,31),
            Weekly_Occurrence__c = '2nd');
        insert vrs;
        
        list<Volunteer_Hours__c> listHours = [select Id, Status__c, Number_of_Volunteers__c, Comments__c 
            from Volunteer_Hours__c where Volunteer_Recurrence_Schedule__c = :vrs.Id order by Planned_Start_Date_Time__c];
        system.assertEquals(4, listHours.size());
        system.assertEquals(vrs.Number_of_Volunteers__c, listHours[0].Number_of_Volunteers__c);
        system.assertEquals(vrs.Comments__c, listHours[0].Comments__c);
        
        listHours[0].Status__c = 'Completed';
        update listHours[0];
        
        vrs.Days_of_Week__c = 'Monday;Friday';
        vrs.Volunteer_Hours_Status__c = 'Confirmed';
        Test.startTest();
        update vrs;
        Test.stopTest(); 

        listHours = [select Id, Status__c, Planned_Start_Date_Time__c from Volunteer_Hours__c];
        system.assertEquals(4, listHours.size());
        
        listHours = [select Id, Status__c from Volunteer_Hours__c where Status__c = 'My Custom Status'];
        system.assertEquals(1, listHours.size());  
        
        listHours = [select Id, Status__c from Volunteer_Hours__c where Status__c = 'Completed'];
        system.assertEquals(1, listHours.size());  
        
        listHours = [select Id, Status__c from Volunteer_Hours__c where Status__c = 'Confirmed'];
        system.assertEquals(2, listHours.size());  
    }

    //******************************************************************************************************
    // Test updating existing Volunteer Recurrence Schedules reuses, but updates, Hours
    public static testmethod void TestVRSHoursHoursReuse() {

        // create test data
        Campaign cmp = new Campaign(recordtypeid=VOL_SharedCode.recordtypeIdVolunteersCampaign, 
            name='Job Calendar Test Campaign', IsActive=true);
        insert cmp;
        Volunteer_Job__c job = new Volunteer_Job__c(name='Job1', campaign__c=cmp.Id);
        insert job;
        Contact contact = new Contact(firstname='test', lastname='test');
        insert contact;
        
        Job_Recurrence_Schedule__c jrs = new Job_Recurrence_Schedule__c(Volunteer_Job__c = job.Id);
        jrs.Days_of_Week__c = 'Monday;Wednesday;Friday';
        jrs.Duration__c = 1;
        jrs.Schedule_Start_Date_Time__c = system.today().toStartOfMonth();
        jrs.Schedule_End_Date__c = system.today().addMonths(2).toStartOfMonth().addDays(-1);
        jrs.Weekly_Occurrence__c = '2nd';
        jrs.Desired_Number_of_Volunteers__c = 5;
        insert jrs;
        
        list<Volunteer_Shift__c> listShift = [select Id, Name, Volunteer_Job__r.Name from Volunteer_Shift__c where Job_Recurrence_Schedule__c = :jrs.Id];
        system.assertEquals(6, listShift.size());
        
        Volunteer_Recurrence_Schedule__c vrs = new Volunteer_Recurrence_Schedule__c(
            Contact__c = contact.Id, 
            Volunteer_Job__c = job.Id,
            Volunteer_Hours_Status__c = 'My Custom Status',
            Days_of_Week__c = 'Monday;Wednesday',
            Duration__c = 1.5,
            Number_of_Volunteers__c = 2,
            Comments__c = 'my comments!',
            Schedule_Start_Date_Time__c = system.today().toStartOfMonth(),
            Schedule_End_Date__c = system.today().addMonths(2).toStartOfMonth().addDays(-1),
            Weekly_Occurrence__c = '2nd');
        insert vrs;
        Volunteer_Recurrence_Schedule__c vrsOriginal = vrs.clone();
        
        list<Volunteer_Hours__c> listHours = [select Id, Status__c, Number_of_Volunteers__c, Comments__c 
            from Volunteer_Hours__c where Volunteer_Recurrence_Schedule__c = :vrs.Id order by Planned_Start_Date_Time__c];
        system.assertEquals(4, listHours.size());
        system.assertEquals(vrs.Number_of_Volunteers__c, listHours[0].Number_of_Volunteers__c);
        system.assertEquals(vrs.Comments__c, listHours[0].Comments__c);
        
        // update all fields that should update future hours, but not past hours
        vrs.Volunteer_Hours_Status__c = 'Confirmed';
        vrs.Duration__c = 1;
        vrs.Number_of_Volunteers__c = 1;
        vrs.Comments__c = 'new comments';
        vrs.Schedule_Start_Date_Time__c = vrs.Schedule_Start_Date_Time__c.addMinutes(10);
        Test.startTest();
        update vrs;
        Test.stopTest(); 

        listHours = [select Id, Status__c, Planned_Start_Date_Time__c, Hours_Worked__c, Number_Of_Volunteers__c, Comments__c from Volunteer_Hours__c];
        system.assertEquals(4, listHours.size());
        
        for (Volunteer_Hours__c hr : listHours) {
            if (hr.Planned_Start_Date_Time__c >= system.Today()) {
                system.assertEquals(vrs.Volunteer_Hours_Status__c, hr.Status__c);
                system.assertEquals(vrs.Duration__c, hr.Hours_Worked__c);
                system.assertEquals(vrs.Number_of_Volunteers__c, hr.Number_of_Volunteers__c);
                system.assertEquals(vrs.Comments__c, hr.Comments__c);
                system.assertEquals(vrs.Schedule_Start_Date_Time__c.Time(), hr.Planned_Start_Date_Time__c.Time());
            } else {
                system.assertEquals(vrsOriginal.Volunteer_Hours_Status__c, hr.Status__c);
                system.assertEquals(vrsOriginal.Duration__c, hr.Hours_Worked__c);
                system.assertEquals(vrsOriginal.Number_of_Volunteers__c, hr.Number_of_Volunteers__c);
                system.assertEquals(vrsOriginal.Comments__c, hr.Comments__c);
                system.assertEquals(vrsOriginal.Schedule_Start_Date_Time__c.Time(), hr.Planned_Start_Date_Time__c.Time());
            }
        }
        
    }
}