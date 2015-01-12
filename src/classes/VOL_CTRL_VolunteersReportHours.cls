// Written by David Habib, copyright (c) 2010-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

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

        // we now get the fields from the fieldset
        listStrFields = VOL_SharedCode.listStrFieldsFromContactFieldSet(Schema.SObjectType.Contact.fieldSets.VolunteersReportHoursFS);
		
        // output error page messages for any field that doesn't have visibility correctly set.
        VOL_SharedCode.testObjectFieldVisibility('Contact', listStrFields);

		// we can derive whether we are within the Personal Site or not, so no need for parameter.
    	fPersonalSite = ApexPages.currentPage().getUrl().contains('PersonalSite');		   		
    } 
            
	// holds the contact fields on the page            
    global Contact contact { 
        get {
            if (contact == null) {
           		contact = new Contact();

		        // when used within the Personal Site, we should use the appropriate Contact
		        contactIdPersonalSite = null;
		        Cookie cId = ApexPages.currentPage().getCookies().get('contactIdPersonalSite');
		        if (cId != null) contactIdPersonalSite = cId.getValue();
				if (contactIdPersonalSite != null && contactIdPersonalSite != '') {
            		VOL_SharedCodeAPI25.LoadAndCopyObject(contactIdPersonalSite, contact);            		
            	}
            }
            return contact;
        }       
        set; 
    }
    
    private string contactIdPersonalSite { get; set; }
    
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
        	if (fPersonalSite) return null;	// just use whatever CSS the Site Template includes.

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
    global boolean fPersonalSite { get; set; }

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
                	system.today().addMonths(-2), system.today().addMonths(1), false, false); 
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
	        for (Schema.FieldSetMember f : SObjectType.Contact.FieldSets.VolunteersReportHoursFS.getFields()) {
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
	        ID contactId = VOL_SharedCode.CreateOrUpdateContactFS(contactIdPersonalSite, contact, contact.Volunteer_Organization__c, listStrFields, false);
	        
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

	// this was a testmethod which can't be compiled in this class under api 31.  
	// but because it was marked global, it could not be completely removed.
    global static void CodeCoverageTests() {}

}