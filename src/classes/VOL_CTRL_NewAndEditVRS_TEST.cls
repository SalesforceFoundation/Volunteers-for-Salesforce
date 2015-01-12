// Written by David Habib, copyright (c) 2010-2014 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@isTest
public with sharing class VOL_CTRL_NewAndEditVRS_TEST {

    //******************************************************************************************************
    // Test Methods
    public static testmethod void TestNewAndEditVRS() {

		// create test data
        Campaign cmp = new Campaign(recordtypeid=VOL_SharedCode.recordtypeIdVolunteersCampaign, 
        	name='Job Test Campaign', IsActive=true);
        insert cmp;
        Volunteer_Job__c job = new Volunteer_Job__c(name='Job1', campaign__c=cmp.Id);
        insert job;
		Contact contact = new Contact(firstname='test', lastname='test');
		insert contact;
        Job_Recurrence_Schedule__c jrs = new Job_Recurrence_Schedule__c(Volunteer_Job__c = job.Id);
		jrs.Days_of_Week__c = 'Monday;Wednesday;Friday';
		jrs.Duration__c = 1;
		jrs.Schedule_Start_Date_Time__c = datetime.newInstance(2012, 1, 1, 3, 30, 0);
		jrs.Schedule_End_Date__c = date.newInstance(2012, 12, 31);
		jrs.Weekly_Occurrence__c = 'Every';
		jrs.Desired_Number_of_Volunteers__c = 5;
		insert jrs;
		
		// scenario 1: creating a new VRS
		Volunteer_Recurrence_Schedule__c vrs = new Volunteer_Recurrence_Schedule__c();
		ApexPages.StandardController stdCtrl = new ApexPages.StandardController(vrs);		
		VOL_CTRL_NewAndEditVRS ctrl = new VOL_CTRL_NewAndEditVRS(stdCtrl);
		ctrl.vrs.Contact__c = contact.Id; 
		ctrl.vrs.Volunteer_Job__c = job.Id;
		ctrl.vrs.Days_of_Week__c = 'Monday;Friday';
		ctrl.vrs.Duration__c = 1.5;
		ctrl.vrs.Schedule_Start_Date_Time__c = datetime.newInstance(2012, 2, 1, 3, 30, 0);
		ctrl.vrs.Schedule_End_Date__c = date.newInstance(2012, 6, 3);
		ctrl.vrs.Weekly_Occurrence__c = '1st';
		stdCtrl.Save();
		
		// verify it got saved
		list<Volunteer_Recurrence_Schedule__c> listVRS = [select Id from Volunteer_Recurrence_Schedule__c where Volunteer_Job__c = :job.Id];
		system.assertEquals(1, listVRS.size());
		
		// scenario 2: updating an existing VRS
		vrs = [select Id, Days_of_Week__c from Volunteer_Recurrence_Schedule__c where Id = :listVRS[0].Id];
		ApexPages.StandardController stdCtrl2 = new ApexPages.StandardController(vrs);		
		VOL_CTRL_NewAndEditVRS ctrl2 = new VOL_CTRL_NewAndEditVRS(stdCtrl2);
		system.assertEquals('Monday;Friday', ctrl2.vrs.Days_of_Week__c);
		ctrl2.vrs.Days_of_Week__c = 'Saturday';
		stdCtrl.Save();
		vrs = [select Id, Days_of_Week__c from Volunteer_Recurrence_Schedule__c where Id = :listVRS[0].Id];
		system.assertEquals('Saturday', ctrl2.vrs.Days_of_Week__c);
		
		// scneario 3: copying from an existing JRS
		ctrl.vrs.Volunteer_Job__c = job.Id;
		system.assert(ctrl.refreshListSOJRS() == null);
		system.assertEquals(2, ctrl.listSOJRS.size());
		ctrl.jrsId = jrs.Id;
		system.assert(ctrl.copyScheduleFromJRS() == null);
		system.assertEquals('Monday;Wednesday;Friday', ctrl.vrs.Days_of_Week__c);
						
    }
	
}