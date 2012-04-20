// Written by David Habib, copyright (c) 2011 Groundwire, 1402 3rd Avenue, Suite 1000, Seattle, WA 98101
// This program is free software; you can redistribute it and/or modify it under the terms of the 
// GNU General Public License version 3 as published by the Free Software Foundation. http://www.gnu.org/licenses/gpl.html

public with sharing class VOL_CTRL_SendBulkEmail {

	public string strSubject { get; set; }
	public string strMessage { get; set; }
	public Volunteer_Hours__c hourStatus { get; set; }
	public ID templateId { get; set; }
	public integer numberOfContacts { get; set; }
	public ID fromEmailId { get; set; }
	public string strJobName { get; set; }
	public boolean fLogActivity { get; set; }

	private ID folderId { get; set; }
	private ID shiftId { get; set; }
	private ID jobId { get; set; }
	
	// constructor
	public VOL_CTRL_SendBulkEmail() { 
		
		// figure out what object we were invoked from
		jobId = ApexPages.currentPage().getParameters().get('jobId');
		shiftId = ApexPages.currentPage().getParameters().get('shiftId');
		
		if (jobId != null) {
			Volunteer_Job__c job = [select Name from Volunteer_Job__c where Id = :jobId];
			strJobName = job.Name;
		}
		hourStatus = new Volunteer_Hours__c();
		numberOfContacts = 0;
		fLogActivity = true;
		
		// get the folderId for our Volunteer email templates
		list<Folder> listf = [select Id from Folder where DeveloperName='Volunteers_Email_Templates'];
		if (listf.size() > 0) folderId = listf[0].Id;		
	}
		
    // the list of Email Templates
    public list<SelectOption> getlistSOTemplates() {
        list<SelectOption> listSO = new list<SelectOption>();
        listSO.add(new SelectOption('', ''));
        for (EmailTemplate et : [select Id, Name, Subject, Body from EmailTemplate 
        		where isActive=true and FolderId=:folderId order by name limit 999]) {
            listSO.add(new SelectOption(et.id, et.name));
        }       
        return listSO;
    }	
	
    // the list of Org Wide Email Addresses
    public list<SelectOption> getlistSOFromEmails() { 
        list<SelectOption> listSO = new list<SelectOption>();
		User thisUser = [Select Name, Email from User where id = :UserInfo.getUserId()];
        listSO.add(new SelectOption('', thisUser.Name + ' <' + thisUser.Email + '>'));
		for (OrgWideEmailAddress owa : [select id, Address, DisplayName from OrgWideEmailAddress]) {
            listSO.add(new SelectOption(owa.id, owa.DisplayName + ' <' + owa.Address + '>'));
        }       
        return listSO;
    }
	
	// action method to load up the email template the user has chosen
	public PageReference LoadEmailTemplate() {
		if (templateId != null) {
        	EmailTemplate et = [select Id, Name, Subject, HtmlValue, Body from EmailTemplate where Id = :templateId];
        	strSubject = et.Subject;
        	strMessage = (et.HtmlValue != null) ? et.HtmlValue : et.Body;
		} else {
			strSubject = null;
			strMessage = null;		
		}
		return null;
	}
	
	// action method to view the templates folder
	public PageReference OpenEmailTemplateFolder() {
		if (folderId != null) {
			PageReference p = new PageReference('/' + folderId);
	        p.setRedirect(true);
	        return p;
		}
		return null;
	}

	// action method to view the templates folder
	public PageReference EditEmailTemplate() {
		if (templateId != null) {
			PageReference p = new PageReference('/' + templateId);
	        p.setRedirect(true);
	        return p;
		}
		return null;
	}

    // action method called when status picklist has changed.  requery for number of contacts to email.
    public PageReference StatusChanged() {
    	if (shiftId != null) {
    		NumberOfContacts = [select count() from Volunteer_Hours__c where Status__c = :hourStatus.Status__c and Volunteer_Shift__c = :shiftId];    		
    	} else {
    		NumberOfContacts = [select count() from Volunteer_Hours__c where Status__c = :hourStatus.Status__c and Volunteer_Job__c = :jobId];
    	}
    	return null;
    }

	// action method to send the email
	public PageReference SendMail() {
	
		// do our validation
		if (numberOfContacts == 0) {		
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.labelMassEmailErrorNoContacts)); 
            return null; 
		}
		
		if (templateId == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.labelMassEmailErrorNoTemplate)); 
            return null; 			
		}
		
		
		try {
			list<Messaging.SingleEmailMessage> listEmail = new list<Messaging.SingleEmailMessage>();

			// handle a job with no shifts, a job with shift(s), and a single specific shift.
			list<Volunteer_Shift__c> listShift = new list<Volunteer_Shift__c>();
			if (shiftId != null) {
				listShift = [select Id from Volunteer_Shift__c where Id = :shiftId];
			} else {
				listShift = [select Id from Volunteer_Shift__c where Volunteer_Job__c = :jobId];
			}
			
			if (listShift.size() == 0) {
		    	for (Volunteer_Hours__c hr : [select Contact__c from Volunteer_Hours__c 
		    			where Status__c = :hourStatus.Status__c and Volunteer_Job__c = :jobId 
		    			and Contact__r.Email != null ]) {
			    	Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
					mail.setTargetObjectId(hr.Contact__c);
					mail.setWhatId(jobId);
					mail.setSaveAsActivity(fLogActivity);
					if (fromEmailId != null) {
						mail.setOrgWideEmailAddressId(fromEmailId);
					}
					mail.setTemplateID(templateId);	
					listEmail.add(mail);					
		    	}								
			} else {
				for (Volunteer_Shift__c shift : listShift) {					
			    	for (Volunteer_Hours__c hr : [select Contact__c from Volunteer_Hours__c 
			    			where Status__c = :hourStatus.Status__c and Volunteer_Shift__c = :shift.Id 
			    			and Contact__r.Email != null ]) {
				    	Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
						mail.setTargetObjectId(hr.Contact__c);
						mail.setWhatId(shift.Id);
						mail.setSaveAsActivity(fLogActivity);
						if (fromEmailId != null) {
							mail.setOrgWideEmailAddressId(fromEmailId);
						}
						mail.setTemplateID(templateId);	
						listEmail.add(mail);					
			    	}				
				}
			}
						
			// send the email and return
			if (listEmail.size() > 0) {
				Messaging.sendEmail(listEmail);
			}
			return Cancel(); // this will take us back to our calling page.
						
		} catch (exception ex) {
            ApexPages.addMessages(ex);   
            if (fLogActivity) {
	            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 
	            	'Logging of Activities must be enabled for Volunteer Jobs and Volunteer Shifts.  Please see the Volunteers for Salesforce Installation and Configuration Guide.'));                    	
            }
            return null;			
		}
	}
	
    // action method that user wants to close this page
    public PageReference Cancel() {
        string strURL = ApexPages.currentPage().getParameters().get('retURL');
        if (strURL == null || strURL == '') strURL = '\\';
        PageReference p = new PageReference(strURL);
        p.setRedirect(true);
        return p;
    }
    
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
		system.assertEquals(p1.getUrl(), p2.getUrl());
		
		// test no template
		ctrl.templateId = null;
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
		system.assertEquals(p1.getUrl(), p2.getUrl());
		
    }
}