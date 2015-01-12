// Written by David Habib, copyright (c) 2010-2014 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@isTest
public with sharing class VOL_JRS_TEST {

    //******************************************************************************************************
    // Test Job Recurrence Schedules    
    public static testmethod void TestJRS() {

		// create test data
        Campaign cmp = new Campaign(recordtypeid=VOL_SharedCode.recordtypeIdVolunteersCampaign, 
        	name='Job Calendar Test Campaign', IsActive=true);
        insert cmp;
        Volunteer_Job__c job = new Volunteer_Job__c(name='Job1', campaign__c=cmp.Id);
        insert job;
        Volunteer_Shift__c shift = new Volunteer_Shift__c(Volunteer_Job__c=job.Id, Duration__c=1, 
        	Start_Date_Time__c=date.newInstance(2012, 1, 1));  // 1/1/2012 was a Sunday
        insert shift;
        Job_Recurrence_Schedule__c jrs = new Job_Recurrence_Schedule__c(Volunteer_Job__c = job.Id);
		jrs.Days_of_Week__c = 'Monday;Wednesday;Friday';
		jrs.Duration__c = 1;

		jrs.Schedule_Start_Date_Time__c = date.newInstance(2012, 1, 1);
		jrs.Weekly_Occurrence__c = 'Every';
		jrs.Desired_Number_of_Volunteers__c = 5;
		insert jrs;
		
		// test Day of Week
		boolean isSun = VOL_JRS.isSundayFirstOfWeek();		
		system.assertEquals(isSun ? 1 : 7, VOL_JRS.nDayOfWeek(date.valueOf('2012-1-1')));
		system.assertEquals(isSun ? 7 : 6, VOL_JRS.nDayOfWeek(date.valueOf('2012-1-7')));
		system.assertEquals(isSun ? 3 : 2, VOL_JRS.nDayOfWeek(date.valueOf('2012-1-31')));
		system.assertEquals(isSun ? 4 : 3, VOL_JRS.nDayOfWeek(date.valueOf('2012-2-1')));
		system.assertEquals(isSun ? 4 : 3, VOL_JRS.nDayOfWeek(date.valueOf('2012-2-29')));
		
		// test dtNthDay
		system.assertEquals(Date.Today(), VOL_JRS.dtNthDay(2012, 1, 1, 1));
		
		// test Every week.
		Date dtNext =  VOL_JRS.dtNextDateforJRS(jrs, date.valueOf(shift.Start_Date_Time__c));
		system.assertEquals(1, VOL_JRS.cWeeksNext(jrs, dtNext, false));
		system.assertEquals(date.valueOf('2012-1-2'), dtNext); 	
		dtNext =  VOL_JRS.dtNextDateforJRS(jrs, dtNext);
		system.assertEquals(date.valueOf('2012-1-4'), dtNext); 	
		dtNext =  VOL_JRS.dtNextDateforJRS(jrs, dtNext);
		system.assertEquals(date.valueOf('2012-1-6'), dtNext); 	
		dtNext =  VOL_JRS.dtNextDateforJRS(jrs, dtNext);
		system.assertEquals(date.valueOf('2012-1-9'), dtNext); 	
		
		// test Alternate weeks.
		jrs.Weekly_Occurrence__c = 'Alternate';
		update jrs;
		system.assertEquals(2, VOL_JRS.cWeeksNext(jrs, dtNext, true));		
		dtNext =  VOL_JRS.dtNextDateforJRS(jrs, dtNext);
		system.assertEquals(date.valueOf('2012-1-11'), dtNext); 	
		dtNext =  VOL_JRS.dtNextDateforJRS(jrs, dtNext);
		system.assertEquals(date.valueOf('2012-1-13'), dtNext); 	
		dtNext =  VOL_JRS.dtNextDateforJRS(jrs, dtNext);
		system.assertEquals(date.valueOf('2012-1-23'), dtNext); 
		
		// test figuring out occurrence of day in month
		system.assertEquals(1, VOL_JRS.nWeekOfDate(date.valueOf('2012-1-1')));
		system.assertEquals(1, VOL_JRS.nWeekOfDate(date.valueOf('2012-1-7')));
		system.assertEquals(2, VOL_JRS.nWeekOfDate(date.valueOf('2012-1-8')));
		system.assertEquals(5, VOL_JRS.nWeekOfDate(date.valueOf('2012-1-29')));
		system.assertEquals(5, VOL_JRS.nWeekOfDate(date.valueOf('2012-1-31')));
		system.assertEquals(1, VOL_JRS.nWeekOfDate(date.valueOf('2012-2-1')));
		system.assertEquals(1, VOL_JRS.nWeekOfDate(date.valueOf('2012-2-4')));
		system.assertEquals(1, VOL_JRS.nWeekOfDate(date.valueOf('2012-2-5')));
		system.assertEquals(5, VOL_JRS.nWeekOfDate(date.valueOf('2012-2-29')));
		system.assertEquals(1, VOL_JRS.nWeekOfDate(date.valueOf('2012-2-6')));
		
		// test Nth week of Month
		jrs.Weekly_Occurrence__c = '3rd';
		update jrs;
		list<boolean> listWhichWeeks = VOL_JRS.WhichWeeksJRS(jrs);
		system.assertEquals(false, listWhichWeeks[0]);
		system.assertEquals(false, listWhichWeeks[1]);
		system.assertEquals(false, listWhichWeeks[2]);
		system.assertEquals(true, listWhichWeeks[3]);
		system.assertEquals(false, listWhichWeeks[4]);
		system.assertEquals(false, listWhichWeeks[5]);

		system.assertEquals(2, VOL_JRS.cWeeksNext(jrs, date.valueOf('2012-1-1'), false));		
		system.assertEquals(2, VOL_JRS.cWeeksNext(jrs, date.valueOf('2012-1-7'), false));		
		system.assertEquals(1, VOL_JRS.cWeeksNext(jrs, date.valueOf('2012-1-8'), false));		
		system.assertEquals(1, VOL_JRS.cWeeksNext(jrs, date.valueOf('2012-1-14'), false));		
		system.assertEquals(5, VOL_JRS.cWeeksNext(jrs, date.valueOf('2012-1-15'), false));		

		dtNext =  VOL_JRS.dtNextDateforJRS(jrs, date.valueOf('2012-1-7')); 
		system.assertEquals(date.valueOf('2012-1-16'), dtNext); 

		jrs.Days_of_Week__c = 'Monday';
		update jrs;
		dtNext =  VOL_JRS.dtNextDateforJRS(jrs, date.valueOf('2012-4-16'));
		system.assertEquals(date.valueOf('2012-5-21'), dtNext); 

		jrs.Days_of_Week__c = 'Wednesday';
		update jrs;
		dtNext =  VOL_JRS.dtNextDateforJRS(jrs, date.valueOf('2012-4-18'));
		system.assertEquals(date.valueOf('2012-5-16'), dtNext); 

		jrs.Weekly_Occurrence__c = '1st';
		jrs.Days_of_Week__c = 'Monday';
		update jrs;
		dtNext =  VOL_JRS.dtNextDateforJRS(jrs, date.valueOf('2012-2-6'));
		system.assertEquals(date.valueOf('2012-3-5'), dtNext); 
		
		jrs.Weekly_Occurrence__c = '2nd;4th;';
		jrs.Days_of_Week__c = 'Sunday';
		update jrs;
		dtNext =  VOL_JRS.dtNextDateforJRS(jrs, date.valueOf('2012-8-1'));
		system.assertEquals(date.valueOf('2012-8-12'), dtNext);  
		
		// test batch calculations
       	VOL_BATCH_Recurrence r = new VOL_BATCH_Recurrence();
    	r.execute(null);	
		
		// test deleting the JRS
		list<Volunteer_Shift__c> listShift = [select Id, Name from Volunteer_Shift__c where Job_Recurrence_Schedule__c = :jrs.Id];
		system.assert(listShift.size() > 0);
		delete jrs;
		listShift = [select Id, Name from Volunteer_Shift__c where Job_Recurrence_Schedule__c = :jrs.Id];
		system.assertEquals(0, listShift.size());
		
    }   

}