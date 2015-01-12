// Written by David Habib, copyright (c) 2010-2014 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

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
	
}