// Written by David Habib, copyright (c) 2010-2014 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@isTest
public with sharing class VOL_CTRL_SendBulkEmail_TEST {
    
    //==================== TEST METHOD(s) ======================================
    public static testmethod void TestJobAndShift() {
    
        // set up intial test data
        Account acc = new Account(name='Individual Test Account');
        insert acc;
        Contact con = new Contact(Lastname='Testy', Email='testy@foo.com', AccountId=acc.Id);
        insert con;
        Campaign cmp = new Campaign(recordtypeid=VOL_SharedCode.recordtypeIdVolunteersCampaign, 
        	name='Test Campaign', IsActive=true);
        insert cmp;
        Volunteer_Job__c job = new Volunteer_Job__c(name='Job1', campaign__c=cmp.Id);
        insert job;
        Volunteer_Shift__c shift = new Volunteer_Shift__c(Volunteer_Job__c=job.Id, Duration__c=1, Start_Date_Time__c=System.now());
        insert shift;
        list<Volunteer_Hours__c> listHours = new list<Volunteer_Hours__c>();   
        integer cHours = 1;     
        for (integer i = 0; i < cHours; i++) {
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
        
        //point to our VF page
        PageReference p = new PageReference('Page.SendBulkEmail');
        p.getParameters().put('jobId', job.id);
        p.getParameters().put('shiftId', shift.id);
        Test.setCurrentPageReference(p);
        
        //instantiate the controller for this opp
        VOL_CTRL_SendBulkEmail ctrl = new VOL_CTRL_SendBulkEmail();
        System.AssertEquals(job.Id, ctrl.jobId);
        System.AssertEquals(shift.Id, ctrl.shiftId);
        System.Assert(ctrl.getlistSOTemplates().size() > 1);
        System.Assert(ctrl.getlistSOFromEmails().size() >= 1);
        
        // load a template
        EmailTemplate et = [select Id from EmailTemplate where DeveloperName='Volunteer_Shift_Reminder'];
        ctrl.templateId = et.Id;
        ctrl.LoadEmailTemplate();
        System.assert(ctrl.strSubject != null);
        System.assert(ctrl.strMessage != null);
        
        // find contacts
        ctrl.hourStatus.Status__c = 'Confirmed';
        ctrl.StatusChanged();
        System.assertEquals(1, ctrl.numberOfContacts);
		
		PageReference p1 = ctrl.Cancel();
		system.assert(p1 != null);
		
		ctrl.fLogActivity = false; // upgraders might not have Activities on for Jobs and Shifts
		PageReference p2 = ctrl.SendMail();
		system.assertEquals(null, p2);
		
		// misc 
		system.assert(ctrl.OpenEmailTemplateFolder() != null);
		system.assert(ctrl.EditEmailTemplate() != null);

		// test no template
		ctrl.templateId = null;
        ctrl.LoadEmailTemplate();
        System.assert(ctrl.strSubject == null);
        System.assert(ctrl.strMessage == null);
		system.assertEquals(null, ctrl.SendMail());
		
		// test no contacts found
		ctrl.hourStatus.Status__c = 'Bogus';
        ctrl.StatusChanged();
        System.assertEquals(0, ctrl.numberOfContacts);
		system.assertEquals(null, ctrl.SendMail()); 	
		
    }
        
    public static testmethod void TestJobOnly() {
    
        // set up intial test data
        Account acc = new Account(name='Individual Test Account');
        insert acc;
        Contact con = new Contact(Lastname='Testy', Email='testy@foo.com', AccountId=acc.Id);
        insert con;
        Campaign cmp = new Campaign(recordtypeid=VOL_SharedCode.recordtypeIdVolunteersCampaign, 
        	name='Test Campaign', IsActive=true);
        insert cmp;
        Volunteer_Job__c job = new Volunteer_Job__c(name='Job1', campaign__c=cmp.Id);
        insert job;
        list<Volunteer_Hours__c> listHours = new list<Volunteer_Hours__c>();   
        integer cHours = 1;     
        for (integer i = 0; i < cHours; i++) {
            Volunteer_Hours__c hours = new Volunteer_Hours__c(
                Volunteer_Job__c=job.id, 
                Contact__c=con.Id,
                Number_of_Volunteers__c=3,
                Start_Date__c=System.today(), 
                Status__c='Confirmed'
                );
            listHours.add(hours);
        }                       
        insert listHours;
        
        //point to our VF page
        PageReference p = new PageReference('Page.SendBulkEmail');
        p.getParameters().put('jobId', job.id);
        Test.setCurrentPageReference(p);
        
        //instantiate the controller for this opp
        VOL_CTRL_SendBulkEmail ctrl = new VOL_CTRL_SendBulkEmail();
        System.AssertEquals(job.Id, ctrl.jobId);
        System.AssertEquals(null, ctrl.shiftId);
        System.Assert(ctrl.getlistSOTemplates().size() > 1);
        System.Assert(ctrl.getlistSOFromEmails().size() >= 1);
        
        // load a template
        EmailTemplate et = [select Id from EmailTemplate where DeveloperName='Volunteer_Shift_Reminder'];
        ctrl.templateId = et.Id;
        ctrl.LoadEmailTemplate();
        System.assert(ctrl.strSubject != null);
        System.assert(ctrl.strMessage != null);
        
        // find contacts
        ctrl.hourStatus.Status__c = 'Confirmed';
        ctrl.StatusChanged();
        System.assertEquals(1, ctrl.numberOfContacts);
		
		PageReference p1 = ctrl.Cancel();
		system.assert(p1 != null);
		
		ctrl.fLogActivity = false; // upgraders might not have Activities on for Jobs and Shifts
		PageReference p2 = ctrl.SendMail();
		system.assertEquals(null, p2);
		
		// test bounced email handling
		con.EmailBouncedReason = 'testing';
		con.EmailBouncedDate = system.Today();
		update con;
		system.assertEquals(null, ctrl.SendMail());		
		
    }
    
	public static testmethod void TestCampaign() {
    
        // set up intial test data
        Account acc = new Account(name='Individual Test Account');
        insert acc;
        Contact con = new Contact(Lastname='Testy', Email='testy@foo.com', AccountId=acc.Id);
        insert con;
        Campaign cmp = new Campaign(recordtypeid=VOL_SharedCode.recordtypeIdVolunteersCampaign, 
        	name='Test Campaign', IsActive=true);
        insert cmp;
        Volunteer_Job__c job = new Volunteer_Job__c(name='Job1', campaign__c=cmp.Id);
        insert job;
        list<Volunteer_Hours__c> listHours = new list<Volunteer_Hours__c>();   
        integer cHours = 3;     
        for (integer i = 0; i < cHours; i++) {
            Volunteer_Hours__c hours = new Volunteer_Hours__c(
                Volunteer_Job__c=job.id, 
                Contact__c=con.Id,
                Number_of_Volunteers__c=3,
                Start_Date__c=System.today(), 
                Status__c='Confirmed'
                );
            listHours.add(hours);
        }                       
        insert listHours;
        
        //point to our VF page
        PageReference p = new PageReference('Page.SendBulkEmail');
        p.getParameters().put('campaignId', cmp.id);
        Test.setCurrentPageReference(p);
        
        //instantiate the controller for this opp
        VOL_CTRL_SendBulkEmail ctrl = new VOL_CTRL_SendBulkEmail();
        System.AssertEquals(cmp.Id, ctrl.campaignId);
        System.AssertEquals(null, ctrl.jobId);
        System.AssertEquals(null, ctrl.shiftId);
        System.Assert(ctrl.strJobName != null);
        
        // load a template
        EmailTemplate et = [select Id from EmailTemplate where DeveloperName='Volunteer_Shift_Reminder'];
        ctrl.templateId = et.Id;
        ctrl.LoadEmailTemplate();
        System.assert(ctrl.strSubject != null);
        System.assert(ctrl.strMessage != null);
        
        // find contacts
		ctrl.fEmailContactsOnlyOnce = false;
        ctrl.hourStatus.Status__c = 'Confirmed';
        ctrl.StatusChanged();
        System.assertEquals(cHours, ctrl.numberOfContacts);
		
		PageReference p1 = ctrl.Cancel();
		system.assert(p1 != null);
		
		ctrl.fLogActivity = false; // upgraders might not have Activities on for Jobs and Shifts
		PageReference p2 = ctrl.SendMail();
		system.assertEquals(null, p2);
		
		// test fEmailContactsOnlyOnce
		ctrl.fEmailContactsOnlyOnce = true;
        ctrl.StatusChanged();
        System.assertEquals(1, ctrl.numberOfContacts);		
    }   

}