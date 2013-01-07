// Written by David Habib, copyright (c) 2012
// This program is free software; you can redistribute it and/or modify it under the terms of the 
// GNU General Public License version 3 as published by the Free Software Foundation. http://www.gnu.org/licenses/gpl.html

global virtual with sharing class VOL_CTRL_VolunteersReportHours {
  
    private VOL_SharedCode volSharedCode;
     
    // constructor
    global VOL_CTRL_VolunteersReportHours() {
        volSharedCode = new VOL_SharedCode();

		// initial values for potential parameters
    	strLanguage = 'en-us'; 

        // handle optional page parameters (must use string, not ID, to handle null)
        map<string, string> params = ApexPages.currentPage().getParameters();
        string p = params.get('Language');
        if (p != null && p != '') strLanguage = p;

		// initialize the list of all fields on Contact.
		// ideally, we'd only include the fields in the Field Set,
		// but Apex currently has no way to see what those are.
		// so for now, we just include all fields on Contact.
		Map<String, Schema.SObjectField> mapS = Schema.SObjectType.Contact.fields.getMap();
		listStrFields = new list<string>();
		listStrFields.addAll(mapS.keySet());    		
    } 
            
	// holds the contact fields on the page            
    global Contact contact { 
        get {
            if (contact == null) contact = new Contact();
            return contact;
        }       
        set; 
    }
    
	// holds the dates and hours fields on the page
    global Volunteer_Hours__c vhours {
    	get {
    		if (vhours == null) vhours = new Volunteer_Hours__c();
    		return vhours;
    	}
    	set;
    }

	// returns the correct URL for the CSS override file
    global string strURLtoCSSFile { 
        get { 
            if (strURLtoCSSFile == null) {
                list<Document> listDocs = [SELECT Name, Id From Document WHERE Name = 'VolunteersReportHoursCSS.css' LIMIT 1 ];
                if (listDocs.size() > 0) {
                    Document doc = listDocs[0];
                    string imageid = doc.id;
                    imageid = imageid.substring(0,15);
                    strURLToCSSFile = '/servlet/servlet.FileDownload?file=' + imageid;
                }
            }
            return strURLtoCSSFile;
        }  
        
        set;
    }
    
    // global properties
    global string strLanguage { get; set; }
    global list<string> listStrFields { get; set; } 

    // status string for reporting the results of saving.
    global String strSaveResult { get; set; }
    
    
    // holds the currently select Job in the Job dropdown
    global ID volunteerJobId { get; set; }
    
    // the list of Volunteer Jobs to put in the dropdown
    global list<SelectOption> listSOVolunteerJobs {
        get {
            if (listSOVolunteerJobs == null) {            	
		        listSOVolunteerJobs = new list<SelectOption>();
		        listSOVolunteerJobs.add(new SelectOption('', ''));
		        for (Volunteer_Job__c vj : [select Name, Id from Volunteer_Job__c where 
		        	Campaign__r.IsActive = true and Inactive__c = false order by name limit 999]) {
		            listSOVolunteerJobs.add(new SelectOption(vj.id, vj.name));
		        }       
            }
            return listSOVolunteerJobs;
        }
        
        set;
    }

    // the user has changed the Volunteer Job dropdown
    global virtual PageReference ChangeVolunteerJob() {
        // clear out all state that is specific to the Job
        strSaveResult = null;
        listSOVolunteerShifts = null;
        volunteerShiftId = null;
        ChangeVolunteerShift();
        return null;
    }

    // holds the currently select Job Shift in the Job Shift dropdown
    global ID volunteerShiftId { get; set; }
    
    // the list of Volunteer Shifts to put in the dropdown
    global list<SelectOption> listSOVolunteerShifts {
        get {
            if (listSOVolunteerShifts == null && volunteerJobId != null) {
                listSOVolunteerShifts = volSharedCode.listSOVolunteerShiftsOfVolunteerJobId(volunteerJobId, 
                	system.today().addMonths(-2), system.today().addMonths(1), false); 
            }
            return listSOVolunteerShifts;
        }
        
        set;
    }

	// specifies whether the currently selected Job has any Shifts.
    global boolean hasShifts { 
    	get {
    		return listSOVOlunteerShifts != null && listSOVolunteerShifts.size() > 1;
    	}
    	set; 
    }


    // the user has changed the Volunteer Shift dropdown
    global virtual PageReference ChangeVolunteerShift() {
    	// clear out info
        strSaveResult = null;    	
    	vhours.Start_Date__c = null;
    	vhours.End_Date__c = null;
    	vhours.Hours_Worked__c = null;
       	vhours.Volunteer_Job__c = volunteerJobId;
       	vhours.Volunteer_Shift__c = volunteerShiftId;
    	
        // set date and hours from shift
        if (volunteerShiftId != null) {
	        Volunteer_Shift__c shift = [select Start_Date_Time__c, Duration__c from Volunteer_Shift__c
	        	where Id = :volunteerShiftId];
        	vhours.Start_Date__c = shift.Start_Date_Time__c.Date();
        	vhours.End_Date__c = vhours.Start_Date__c;
        	vhours.Hours_Worked__c = shift.Duration__c;
        }
        return null;        
    }

	private class MyException extends Exception {}


    // action method for saving the the volunteer's hours.    
    global virtual PageReference Save() {  
    	try { 
    		// because we need to use actionSupport immediate=false to support the combo's,
    		// we couldn't actually use visualforce's required=true property on fields.
    		// so we must manually enforce the fields we want required ourselves.
    		boolean hasErrors = false;

			// first deal with fields on the contact.
	        for (Schema.FieldSetMember f : SObjectType.Contact.FieldSets.GW_Volunteers__VolunteersReportHoursFS.getFields()) {
	        	if (contact.get(f.getFieldPath()) == null && (f.getDBRequired() || f.getRequired())) {
		    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 
		    			String.Format(system.label.labelVolunteerReportHoursErrorRequiredField, new string[] { f.getLabel() }))); 	
		    		hasErrors = true;	
	        	}    		
	        }   
	        	         		
    		if (volunteerJobId == null) {
	    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 
	    			String.Format(system.label.labelVolunteerReportHoursErrorRequiredField, new string[] { Schema.sObjectType.Volunteer_Hours__c.fields.Volunteer_Job__c.getLabel() }))); 	
	    		hasErrors = true;	    		
    		}
    		if (vhours.Start_Date__c == null) {
	    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 
	    			String.Format(system.label.labelVolunteerReportHoursErrorRequiredField, new string[] { Schema.sObjectType.Volunteer_Hours__c.fields.Start_Date__c.getLabel() }))); 	
	    		hasErrors = true;	    		
    		}
    		if (vhours.End_Date__c == null) {
	    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 
	    			String.Format(system.label.labelVolunteerReportHoursErrorRequiredField, new string[] { Schema.sObjectType.Volunteer_Hours__c.fields.End_Date__c.getLabel() }))); 	
	    		hasErrors = true;	    		
    		}
    		if (vhours.Hours_Worked__c == null) {
	    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 
	    			String.Format(system.label.labelVolunteerReportHoursErrorRequiredField, new string[] { Schema.sObjectType.Volunteer_Hours__c.fields.Hours_Worked__c.getLabel() }))); 	
	    		hasErrors = true;	    		
    		}
			// now bail out if any required fields are missing.    					
			if (hasErrors) {
	    		strSaveResult = null;
				return null;			
			}    		
			
    		// save or update the contact              
	        ID contactId = VOL_SharedCode.CreateOrUpdateContactFS(contact.Id, contact, contact.Volunteer_Organization__c, listStrFields);
	        
	        list<Volunteer_Hours__c> listHours = null;

	        if (volunteerShiftId != null) {
		        // search for an existing Hours record to update, if they specified a Shift
	        	listHours = [select Id from Volunteer_Hours__c where 
	        		Volunteer_Shift__c = :volunteerShiftId and Contact__c = :contactId];
	        } else {
		        // search for an existing Hours record to update for this job 
		        // match non-committed hours, or committed where the start date is the same.
	        	listHours = [select Id from Volunteer_Hours__c where 
	        		Volunteer_Job__c = :volunteerJobId and Contact__c = :contactId and 
	        		(Status__c <> 'Completed' or Start_Date__c = :vhours.Start_Date__c) ];	        	
	        }

			// if we found a matching Hours, just update it
        	if (listHours != null && listHours.size() > 0) {
        		listHours[0].Status__c = 'Completed';
        		listHours[0].Start_Date__c = vhours.Start_Date__c;
        		listHours[0].End_Date__c = vhours.End_Date__c;
        		listHours[0].Hours_Worked__c = vhours.Hours_Worked__c;
        		update listHours[0];
        	} else {        
		        // create new hours if needed
	        	vhours.Volunteer_Job__c = volunteerJobId;
	        	vhours.Volunteer_Shift__c = volunteerShiftId;
	        	vhours.Status__c = 'Completed';
	        	vhours.Contact__c = contactId;
	        	vhours.Number_of_Volunteers__c = 1;
	        	insert vhours;
	        }
	        
	        // clear current job & shift info
	        volunteerJobId = null;
	        ChangeVolunteerJob();
        	vhours = null;
			
	        strSaveResult = system.label.labelVolunteerReportHoursThankYou;
    	} catch (exception ex) {
    		strSaveResult = null;
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage())); 		    		
    	}
        return null;
    }


    //==================== TEST METHOD(s) ======================================
    global static testmethod void CodeCoverageTests() {

        // create test bucket account
        Account acc = new Account(Name='Test Individual Bucket Account');
        insert acc;

        Campaign cmp = new Campaign(recordtypeid=VOL_SharedCode.recordtypeIdVolunteersCampaign, name='Test Job Campaign', IsActive=true);
        insert cmp;
        Volunteer_Job__c job = new Volunteer_Job__c(name='Job1', campaign__c=cmp.Id, Display_on_Website__c=true);
        insert job;
        Volunteer_Shift__c shift = new Volunteer_Shift__c(Volunteer_Job__c=job.Id, Duration__c=1, Start_Date_Time__c=System.now());
        insert shift;        
        
        // exercise some initial settings code
        System.Assert(VOL_SharedCode.VolunteersSettings != null);
        
        // specify our settings        
        Volunteers_Settings__c settings = new Volunteers_Settings__c();
        settings.Signup_Bucket_Account_On_Create__c = 'Test Individual Bucket Account';
        VOL_SharedCode.getVolunteersSettingsForTests(settings);
        
        PageReference pageRef=Page.VolunteersReportHours; 
        Test.setCurrentPage(pageRef); 

        //instantiate the controller 
        VOL_CTRL_VolunteersReportHours ctrl = new VOL_CTRL_VolunteersReportHours();

        // scenario 1: creating a new contact to the bucket account.
        Contact contact = ctrl.contact;
        System.Assert(contact != null);
        contact.FirstName = 'TestFirstName';
        contact.LastName = 'TestLastName';
        contact.Email = 'foovolunteer@bar.com';
        ctrl.volunteerJobId = job.Id;
        ctrl.vhours.Start_Date__c = System.Today();
        ctrl.vhours.End_Date__c = System.Today();
        ctrl.vhours.Hours_Worked__c = 1;
        ctrl.Save();
        System.AssertEquals(system.label.labelVolunteerReportHoursThankYou, ctrl.strSaveResult);
                
        // make sure it got created correctly
        contact = [select Id, AccountId from Contact where Email='foovolunteer@bar.com' and Firstname='TestFirstName' limit 1];
        System.Assert(contact.Id != null);
        System.AssertEquals(VOL_SharedCode.SettingsBucketAccountId, contact.AccountId);        
        Volunteer_Hours__c vh = [select Id, Status__c from Volunteer_Hours__c where contact__c = :contact.Id];
        system.assertEquals('Completed', vh.Status__c);
        
        // scenario 2: update to an existing contact
        contact = ctrl.contact;
        System.Assert(contact != null);
        contact.FirstName = 'TestFirstName';
        contact.LastName = 'TestLastName';
        contact.Email = 'foovolunteer@bar.com';
        contact.Phone = '425-123-4567';
        contact.HomePhone = '206-123-4567';
        ctrl.volunteerJobId = job.Id;
        ctrl.volunteerShiftId = shift.Id;
        ctrl.ChangeVolunteerShift();
        ctrl.Save();
        System.AssertEquals(system.label.labelVolunteerReportHoursThankYou, ctrl.strSaveResult);
                
        // make sure the existing contact's volunteer status field was updated          
        contact = [select Id, Volunteer_Status__c, Phone from Contact where Email='foovolunteer@bar.com' and Firstname='TestFirstName' limit 1];
        System.AssertEquals('Active', contact.Volunteer_Status__c);
        System.Assert(('425-123-4567' == contact.Phone) || ('206-123-4567' == contact.Phone));
        Volunteer_Hours__c vh2 = [select Id, Status__c, Hours_Worked__c from Volunteer_Hours__c where Volunteer_Shift__c = :shift.Id];
        system.assertEquals('Completed', vh2.Status__c);
        system.assertEquals(1, vh2.Hours_Worked__c);
        
        // scenario 3: update existing Hours record
        ctrl.volunteerJobId = job.Id;
        ctrl.volunteerShiftId = shift.Id;
        ctrl.ChangeVolunteerShift();
		ctrl.vhours.Hours_Worked__c = 2;
        ctrl.Save();
        System.AssertEquals(system.label.labelVolunteerReportHoursThankYou, ctrl.strSaveResult);
        vh2 = [select Id, Status__c, Hours_Worked__c from Volunteer_Hours__c where Volunteer_Shift__c = :shift.Id];
        system.assertEquals('Completed', vh2.Status__c);
        system.assertEquals(2, vh2.Hours_Worked__c);
        
                
        // anything else
        System.Assert(ctrl.strURLtoCSSFile == ctrl.strURLtoCSSFile);
        System.Assert(ctrl.listSOVolunteerJobs != null);
        ctrl.volunteerJobId = job.Id;
        ctrl.ChangeVolunteerJob();
        System.Assert(ctrl.listSOVolunteerShifts != null);
        system.assertEquals(true, ctrl.hasShifts);
        
               
    }       

}