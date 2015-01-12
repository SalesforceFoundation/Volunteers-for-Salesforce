// Written by David Habib, copyright (c) 2010-2014 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

global with sharing class VOL_SharedCode { 

    // the list of Campaigns that have Volunteer Jobs
    global list<SelectOption> listSOCampaignsWithJobs {
        get {
            list<SelectOption> listSO = new list<SelectOption>();
            listSO.add(new SelectOption('', ''));
            for (Campaign c : [select Name, Id, StartDate from Campaign where RecordTypeId = :recordtypeIdVolunteersCampaign 
            	and IsActive = true order by StartDate desc limit 999]) {
                listSO.add(new SelectOption(c.id, c.name));
            }       
            return listSO;
        }
    }

    // the list of Volunteer Jobs for the specified Campaign
    global list<SelectOption> listSOVolunteerJobsOfCampaignId(ID campaignId) {
        list<SelectOption> listSO = new list<SelectOption>();
        listSO.add(new SelectOption('', ''));
        for (Volunteer_Job__c vj : [select Name, Id from Volunteer_Job__c where Campaign__c = :campaignId order by name limit 999]) {
            listSO.add(new SelectOption(vj.id, vj.name));
        }       
        return listSO;
    }

    // the list of Volunteer Job Shifts for the specified Job
    global list<SelectOption> listSOVolunteerShiftsOfVolunteerJobId(ID volunteerJobId, Date dtStart, Date dtEnd, boolean fIncludeShiftName, boolean fIncludeNumberNeeded) {
        list<SelectOption> listSO = new list<SelectOption>();
        listSO.add(new SelectOption('', ''));
        dtEnd = dtEnd.addDays(1);
        for (Volunteer_Shift__c vs : [select Id, Name, Start_Date_Time__c, Number_of_Volunteers_Still_Needed__c from Volunteer_Shift__c 
        	where Volunteer_Job__c = :volunteerJobId 
        		and Start_Date_Time__c >= :dtStart and Start_Date_Time__c < :dtEnd
        	order by Start_Date_Time__c limit 999]) {
            SelectOption so = new SelectOption(vs.id, vs.Start_Date_Time__c.format() + 
            	(fIncludeShiftName ? '&nbsp;&nbsp;&nbsp;&nbsp;(' + vs.name + ')' : '' ) +
            	(fIncludeNumberNeeded ? '&nbsp;&nbsp;' + 
            		(vs.Number_of_Volunteers_Still_Needed__c > 0 ? 
            			system.label.labelCalendarStillNeeded + vs.Number_of_Volunteers_Still_Needed__c : system.label.labelCalendarShiftFull) +
            		' ' : '' ));
            so.setEscapeItem(false); 
            listSO.add(so);
        }       
        return listSO;
    }
    
    // Volunteer Custom Settings object.  Loads an existing, and if not found creates one with default values.
    global static Volunteers_Settings__c VolunteersSettings {
        get {
            if (VolunteersSettings == null) {
                VolunteersSettings = Volunteers_Settings__c.getInstance();  
                
                if (VolunteersSettings.Id == null) {
	                VolunteersSettings = Volunteers_Settings__c.getOrgDefaults();                  	
                }
                
                if (VolunteersSettings.Id == null) {
					VolunteersSettings.Setupownerid = UserInfo.getOrganizationId();

                    // create reasonable defaults
                    VolunteersSettings.Signup_Matches_Existing_Contacts__c = false;
                    VolunteersSettings.Signup_Creates_Contacts_If_No_Match__c = false;
                    VolunteersSettings.Signup_Bucket_Account_On_Create__c = null;
                    VolunteersSettings.Recurring_Job_Future_Months__c = 4;
                    VolunteersSettings.Contact_Match_Email_Fields__c = null;
                    VolunteersSettings.Contact_Match_First_Name_Fields__c = null;
                    VolunteersSettings.Personal_Site_Org_Wide_Email_Name__c = null;
                    VolunteersSettings.Contact_Matching_Rule__c = 'Firstname;Lastname;Email';
                    upsert VolunteersSettings;
                } else if (VolunteersSettings.Contact_Matching_Rule__c == null) {
                    VolunteersSettings.Contact_Matching_Rule__c = 'Firstname;Lastname;Email';
                    upsert VolunteersSettings;                	
                }
            }
            return VolunteersSettings;
        }
        
        set;
    }
    
    // helper to get the AccoutId of the Bucket Account specified in Custom Settings.
    global static ID SettingsBucketAccountId {
        get {
            if (SettingsBucketAccountId == null) {
                if (VolunteersSettings.Signup_Bucket_Account_On_Create__c != null) {
                    Account[] acc = [select Id from Account where name = :VolunteersSettings.Signup_Bucket_Account_On_Create__c limit 1];
                    if (acc.size() > 0) SettingsBucketAccountId = acc[0].Id;
                }
            } 
            return SettingsBucketAccountId;
        }
        
        set;
    }

    // test helper that allows one to override the users's Custom Settings with the settings we want to test with.
    global static Volunteers_Settings__c getVolunteersSettingsForTests(Volunteers_Settings__c mySettings) {
        
        //clear out whatever settings exist
        delete [select id from Volunteers_Settings__c];
        SettingsBucketAccountId = null;
        
        //create our own based on what's passed in from the test
        VolunteersSettings = new Volunteers_Settings__c (
            Signup_Matches_Existing_Contacts__c = mySettings.Signup_Matches_Existing_Contacts__c,
            Signup_Creates_Contacts_If_No_Match__c = mySettings.Signup_Creates_Contacts_If_No_Match__c,
            Signup_Bucket_Account_On_Create__c = mySettings.Signup_Bucket_Account_On_Create__c,
            Recurring_Job_Future_Months__c = mySettings.Recurring_Job_Future_Months__c,
            Contact_Match_Email_Fields__c = mySettings.Contact_Match_Email_Fields__c,
            Contact_Match_First_Name_Fields__c = mySettings.Contact_Match_First_Name_Fields__c,
            Contact_Matching_Rule__c = mySettings.Contact_Matching_Rule__c,
            Personal_Site_Org_Wide_Email_Name__c = mySettings.Personal_Site_Org_Wide_Email_Name__c
            );
        insert VolunteersSettings;                      
        return VolunteersSettings;
    }

    // global helper to get the Volunteers Campaign recordtype.
	private class MyException extends Exception {}
    global static Id recordtypeIdVolunteersCampaign {
    	get {
    		if (recordtypeIdVolunteersCampaign == null) {
    			list<RecordType> listRT = [SELECT Id FROM RecordType WHERE DeveloperName='Volunteers_Campaign'];
    			if (listRT.size() == 0) {
					throw (new MyException('The Volunteers Campaign Record Type is missing and must be restored.'));    				
    			}
    			recordtypeIdVolunteersCampaign = listRT[0].Id;
    		}
    		return recordtypeIdVolunteersCampaign;
    	}
    	set;
    }
    
    // shared routine to get all Fields names form the specified Field Set on Contact
    // also explicitly adds additional Contact fields that we will always use in our Sites pages.
    global static list<string> listStrFieldsFromContactFieldSet(Schema.FieldSet fs) {
        set<string> setStrFields = new set<string>();
        for (Schema.FieldSetMember f : fs.getFields()) {
            setStrFields.add(f.getFieldPath().toLowerCase());
        }  
        // also add the fields we explicitly refer to in CreateOrUpdateContactFS()
        // we use a set (with lowercase) to avoid creating duplicates.
        setStrFields.add('firstname');
        setStrFields.add('lastname');
        setStrFields.add('email');
        //setStrFields.add(VOL_SharedCode.StrTokenNSPrefix('volunteer_status__c').tolowerCase());
        //setStrFields.add(VOL_SharedCode.StrTokenNSPrefix('volunteer_notes__c').toLowerCase());        
        list<string> listStrFields = new list<string>();
        listStrFields.addAll(setStrFields);
        return listStrFields;
    }
    
    // shared routine to get all Fields names form the specified Field Set 
    global static list<string> listStrFieldsFromFieldSet(Schema.FieldSet fs) {
        list<string> listStrFields = new list<string>();
        for (Schema.FieldSetMember f : fs.getFields()) {
            listStrFields.add(f.getFieldPath());
        }  
        return listStrFields;
    }

    // global code to create a new lead or contact for web volunteer signup.  
    // this code is used by both the VolunteersSignup page, and the VolunteersJobListing page.
    // it uses the custom setting for the bucket account, but takes parameters for
    // matching existing contacts, and create contacts vs. leads.  this is because the two pages have different use cases.
    // it also assumes that the contact that is passed in is the dummy record from the web page, and thus isn't real, and
    // uses the Department field to track the user's company name.
    global static ID CreateContactOrLead(Contact contact, boolean fMatchExistingContacts, boolean fCreateContacts) {
        // update the date before we start
        contact.Volunteer_Last_Web_Signup_Date__c = system.today();

        // let's see if we can find any matching Contacts.
        list<Contact> listCon = [select Id, Lastname, Firstname, Email, Phone, HomePhone,
        		Volunteer_Availability__c, Volunteer_Notes__c, Volunteer_Last_Web_Signup_Date__c, 
        		Volunteer_Status__c, Volunteer_Skills__c, Volunteer_Organization__c from Contact 
                where Lastname=:contact.Lastname and Firstname=:contact.Firstname and Email=:contact.Email];

        // if we can match existing contacts, and we found a match, update them.                        
        if (fMatchExistingContacts && listCon.size() > 0) {                   
            for (Contact con : listCon) {
            	con.Volunteer_Last_Web_Signup_Date__c = contact.Volunteer_Last_Web_Signup_Date__c;
                con.Volunteer_Availability__c = contact.Volunteer_Availability__c;
                string strNotes = con.Volunteer_Notes__c;
                if (strNotes != '') strNotes += '  '; 
                if (contact.Volunteer_Notes__c != null) {
                    con.Volunteer_Notes__c = strNotes + '[' + string.valueof(System.today()) + ']: ' + contact.Volunteer_Notes__c;
                }                   
                con.Volunteer_Skills__c = contact.Volunteer_Skills__c;
                if (con.Volunteer_Status__c == null) con.Volunteer_Status__c = 'New Sign Up';
                if (contact.Phone != null) con.Phone = contact.Phone;
                if (contact.HomePhone != null) con.HomePhone = contact.HomePhone; 
                // NOTE: if we find existing contact(s), we don't worry about doing anything with Company.
                // but we can at least put it in the new Volunteer_Organization__c field.
                if (contact.Department != null) con.Volunteer_Organization__c = contact.Department;
            }
            update listCon;
            return listCon[0].Id;
        } else if (fCreateContacts) {  // No Match found, create a Contact
            contact.LeadSource = 'Web Volunteer Signup';
            contact.Volunteer_Status__c = 'New Sign Up';
            
            Account accToUse = null;
            
            // see if we can find their company (which we assume the form used Department to record.)
            if (contact.Department != null) {
                list<Account> listAccount = [select Id, Name from Account where Name = :contact.Department limit 1];
                if (listAccount.size() > 0) accToUse = listAccount.get(0);
                contact.Volunteer_Organization__c = contact.Department;
            }
            
            // if company found, use it
            if (accToUse != null) {
                contact.AccountId = accToUse.Id;
            } else { // otherwise use the bucket account (which may be null and imply the 1:1 model in NPSP)
                contact.AccountId = VOL_SharedCode.SettingsBucketAccountId;                             
            }
            
            insert contact;
            return contact.Id;
        } else { // No Match found, create a Lead
            Lead lead = new lead();
            lead.FirstName = contact.FirstName;
            lead.LastName = contact.LastName;
            lead.Company = (contact.Department == null ? '[not provided]' : contact.Department);
            lead.Email = contact.Email;
            lead.Phone = contact.Phone;
            lead.MobilePhone = contact.HomePhone; // leads don't have a home phone!
            lead.Volunteer_Availability__c = contact.Volunteer_Availability__c;
            lead.Volunteer_Notes__c = contact.Volunteer_Notes__c;
            lead.Volunteer_Skills__c = contact.Volunteer_Skills__c;
            lead.Volunteer_Status__c = 'New Sign Up';
            lead.LeadSource = 'Web Volunteer Signup';
            insert lead;      
            return lead.Id;              
        }
    }   
    
    // global code to lookup an existing contact
    // listStrFields are optional fields to include in the soql call
    global static list<Contact> LookupContact(Contact contact, list<string> listStrFields) {    
    
        // let's see if we can find any matching Contacts.
        // we need to use dynamic soql, since we allow the user to modify the FieldSet of fields to edit.
        string strSoql = 'select ';
        string strComma = '';
        if (listStrFields == null) {
        	strSoql += 'Id';
        } else {
	        for (string strF : listStrFields) {
	        	strSoql += strComma + strF;
	        	strComma = ', ';
	        }
        }        
        strSoql += ' from Contact ';
        string strAnd = ' where ';
        
        // make sure their settings haven't been completely cleared
        if (VolunteersSettings.Contact_Matching_Rule__c == null || VolunteersSettings.Contact_Matching_Rule__c == '') {
        	VolunteersSettings.Contact_Matching_Rule__c = 'Firstname;Lastname;Email';
        }
        
        if (isLastnameInContactMatchRules) {
            strSoql += strAnd + ' (Lastname=\'' + StrEscape(contact.Lastname) + '\') ';
            strAnd = ' and ';
        }
        if (isFirstnameInContactMatchRules) {
            strSoql += strAnd + ' (Firstname=\'' + StrEscape(contact.Firstname) + '\'';
            strAnd = ' and ';

	        // any additional firstname fields to check
	        if (VolunteersSettings.Contact_Match_First_Name_Fields__c != null) {
		        list<string> listStrFname = new list<string>();
	    	    listStrFname = VolunteersSettings.Contact_Match_First_Name_Fields__c.split(';');
	        	for (string str : listStrFname) {
	        		strSoql += ' or ' + str + '=\'' + StrEscape(contact.Firstname) + '\'';
	        	}
	        }
	        strSoql += ') ';
        }
        if (isEmailInContactMatchRules) {
            strSoql += strAnd + ' (Email=\'' + contact.Email + '\'';
            strAnd = ' and ';
	        // any additional email fields to check
	        if (VolunteersSettings.Contact_Match_Email_Fields__c != null) {
		        list<string> listStrEmail = new list<string>();
	    	    listStrEmail = VolunteersSettings.Contact_Match_Email_Fields__c.split(';');
	        	for (string str : listStrEmail) {
	        		strSoql += ' or ' + str + '=\'' + contact.Email + '\'';
	        	}
	        }
	       	// handle NPSP email fields 
	       	if (IsNPSPInstalled) {
				strSoql += ' or npe01__AlternateEmail__c=\'' + contact.Email + '\'';
				strSoql += ' or npe01__HomeEmail__c=\'' + contact.Email + '\'';
				strSoql += ' or npe01__WorkEmail__c=\'' + contact.Email + '\'';
	       	}
	       	strSoql += ') ';
        }        
        strSoql += ' limit 999 ';      
        list<Contact> listCon = Database.Query(strSoql); 
		return listCon;
	}

    // global code to create a new contact, or update an existing contact, for web volunteer signup.  
    // this code is used by both the VolunteersSignupFS page, and the VolunteersJobListingFS page.
    // if creating a new Contact, it uses the custom setting for the bucket account, but takes parameters for
    // the account name to try to lookup and match.
    // It also takes the list of fields on the contact object to copy over.
    global static ID CreateOrUpdateContactFS(string contactIdExisting, Contact contact, string strAccountName, list<string> listStrFields) {
    	return CreateOrUpdateContactFS(contactIdExisting, contact, strAccountName, listStrFields, true); 
    }
    
    global static ID CreateOrUpdateContactFS(string contactIdExisting, Contact contact, string strAccountName, list<string> listStrFields, boolean setLastWebSignup) {
    	
    	// listStrFields is the specific list of fields on the form's fieldset, which we should assume we want to save.
    	// we also need to special case several fields we will potentially set, but we also need to know,
    	// if they are in the fieldset or not.
    	set<string> setStrFields = new set<string>();

    	// store all fields in lower case
    	for (string strField : listStrFields)
    		setStrFields.add(strField.toLowerCase());
    		
    	boolean isStatusInFS = !setStrFields.add(VOL_SharedCode.StrTokenNSPrefix('volunteer_status__c').tolowerCase());
        boolean isNotesInFS = !setStrFields.add(VOL_SharedCode.StrTokenNSPrefix('volunteer_notes__c').toLowerCase());    
        
        // create a new list with all the fields
        list<string> listStrFieldsAll = new list<string>(setStrFields);
        
		list<Contact> listCon = LookupContact(contact, listStrFieldsAll);

        // if we found a match                      
        if (listCon.size() > 0) {
        	Contact conExisting = null;
        	
        	// match the one that has the same Id
        	if (contactIdExisting != null && contactIdExisting != '') {
	        	for (integer i = 0; i < listCon.size(); i++) { 
	        		if (listCon[i].Id == contactIdExisting) 
	        			conExisting = listCon[i];
	        	}
        	}
        	// use first one if no match found.
        	if (conExisting == null) {
    			conExisting = listCon[0];
        	}                  
    		
    		// special case appending Volunteer Notes, rather than overwriting.
    		if (isNotesInFS) {
	            if (contact.Volunteer_Notes__c != null && contact.Volunteer_Notes__c != conExisting.Volunteer_Notes__c) {
	                contact.Volunteer_Notes__c = (conExisting.Volunteer_Notes__c != null ? (conExisting.Volunteer_Notes__c + '  ') : '') + 
	                	'[' + string.valueof(System.today()) + ']: ' + contact.Volunteer_Notes__c;
	            } else {
	            	contact.Volunteer_Notes__c = conExisting.Volunteer_Notes__c;
	            }
    		}
    		            
            // special case setting Volunteer Status, only if not currently set.
            if (conExisting.Volunteer_Status__c != null) {
            	contact.Volunteer_Status__c = null;
            } else {
            	conExisting.Volunteer_Status__c = 'New Sign Up';
            }
            
            // now copy over all the non-null fields from the form's contact to the existing contact.
            // avoid overwriting existing first name or existing email, since we might match it from in a different field.
            // special case address fields
            boolean hasMailingAddress = false;
            boolean hasOtherAddress = false;
            for (string strF : listStrFields) {
            	strF = strF.toLowerCase();
            	if (strF != 'id' && strF != 'firstname' && strF != 'email' && contact.get(strF) != null) {
            		if (strF.contains('mailing')) {
            			hasMailingAddress = true;
            			continue;
            		}
            		if (strF.contains('other')) {
            			hasOtherAddress = true;
            			continue;
            		}
            		conExisting.put(strF, contact.get(strF));
            	}
            }            
            if (hasMailingAddress)
            	VOL_StateCountryPicklists.copyAddressStdSObj(contact, 'Mailing', conExisting, 'Mailing');
            if (hasOtherAddress)
            	VOL_StateCountryPicklists.copyAddressStdSObj(contact, 'Other', conExisting, 'Other');
            	
	        if (setLastWebSignup)
	        	conExisting.Volunteer_Last_Web_Signup_Date__c = system.today();
        
            update conExisting;
            // null out notes, so another update won't append them again!
            contact.Volunteer_Notes__c = null;
            return conExisting.Id;
        } else  {  // No Match found, create a Contact

            // don't assume the contact object wasn't already used.
            // since we can't null out Id for the insert, copy all
            // the fields to a new object and use it.
        	Contact conNew = new Contact();
            //  now copy over all the non-null fields from the form's contact to the existing contact.
            // special case address fields
            boolean hasMailingAddress = false;
            boolean hasOtherAddress = false;
            for (string strF : listStrFields) {
            	strF = strF.toLowerCase();
            	if (strF != 'id' && contact.get(strF) != null) {
            		if (strF.contains('mailing')) {
            			hasMailingAddress = true;
            			continue;
            		}
            		if (strF.contains('other')) {
            			hasOtherAddress = true;
            			continue;
            		}
            		conNew.put(strF, contact.get(strF));
            	}
            }
            if (hasMailingAddress)
            	VOL_StateCountryPicklists.copyAddressStdSObj(contact, 'Mailing', conNew, 'Mailing');
            if (hasOtherAddress)
            	VOL_StateCountryPicklists.copyAddressStdSObj(contact, 'Other', conNew, 'Other');

            // see if we can find their company 
            Account accToUse = null;            
            if (strAccountName != null) {
                list<Account> listAccount = [select Id, Name from Account where Name = :strAccountName limit 1];
                if (listAccount.size() > 0) accToUse = listAccount.get(0);
            }
            
            // if company found, use it
            if (accToUse != null) {
                conNew.AccountId = accToUse.Id;
            } else { // otherwise use the bucket account (which may be null and imply the 1:1 model in NPSP)
                conNew.AccountId = VOL_SharedCode.SettingsBucketAccountId;                             
            }
            
	        if (setLastWebSignup)
	        	conNew.Volunteer_Last_Web_Signup_Date__c = system.today();
            conNew.LeadSource = 'Web Volunteer Signup';
            conNew.Volunteer_Status__c = 'New Sign Up';

            insert conNew;
            // null out notes, so another update won't append them again!
            contact.Volunteer_Notes__c = null;
            return conNew.Id;
        }
    }    

	// global utility to escape a string.
	global static string StrEscape(string str) {
		if (str == null) return null;
		return string.escapeSingleQuotes(str);
	}
	
	// global utility to load up an existing object and copy it to the provided object
	global static void LoadAndCopyObject(ID id, SObject sobj) {
		
		// this code moved to VOL_SharedCodeAPI25 to keep it running with api 25
		// behavior, which is that the Sites Guest User Profile can still edit
		// this new contact object we created.  Under api 31, the contact object is readonly.
		// we needed to update the rest of this class to api 31 to handle state & country picklists.
		VOL_SharedCodeAPI25.LoadAndCopyObject(id, sobj);
	}
	
	public static void VolunteerHoursTrigger(list<Volunteer_Hours__c> listHoursOld, list<Volunteer_Hours__c> listHoursNew, boolean resetTotals) {
		
		// consider both newMap and oldMap.
		// for each hours object, there are two potential shifts it interacts with.
		// within a batch of hours changes (import scenario), multiple hours can affect the same shift.
		// thus need to keep track of the shifts to update, their original value, and the sum of their changed values.
		
		// Insert scenario: status=Confirmed or Completed. Shift <> null. Number of Volunteers <> null.
		// Delete scenario: status=Confirmed or Completed.  Shift <> null. Number of Volunteers <> null.
		// Update scenario: just treat as a delete and an insert, since we already have to handle multiple changes to same job!
		
	
		// WARNING: deleting, undeleting, or merging a Contact, does NOT call any trigger on the Hours!
		// thus I've manually called this from the before delete & after undelete trigger on Contacts (VOL_Contact_MaintainHours).
		
		map<Id, Double> mpShiftIdDelta = new map<Id, Double>();
		
		// first we go through the new hours, and add up the number of volunteers per shift
		if (listHoursNew != null) {
			for (Volunteer_Hours__c hr : listHoursNew) {
				if ((hr.Status__c == 'Confirmed' || hr.Status__c == 'Completed') &&
					(hr.Volunteer_Shift__c <> null && hr.Number_Of_Volunteers__c != null)) {
						Double numVols = mpShiftIdDelta.get(hr.Volunteer_Shift__c);
						if (numVols == null) numVols = 0;
						numVols += hr.Number_of_Volunteers__c;
						mpShiftIdDelta.put(hr.Volunteer_Shift__c, numVols);
					}
			} 
		}
		
		// second we go through the old hours, and subtract the number of volunteers per shift		
		if (listHoursOld != null) {
			for (Volunteer_Hours__c hr : listHoursOld) {
				if ((hr.Status__c == 'Confirmed' || hr.Status__c == 'Completed') &&
					(hr.Volunteer_Shift__c <> null && hr.Number_Of_Volunteers__c != null)) {
						Double numVols = mpShiftIdDelta.get(hr.Volunteer_Shift__c);
						if (numVols == null) numVols = 0;
						numVols -= hr.Number_of_Volunteers__c;
						mpShiftIdDelta.put(hr.Volunteer_Shift__c, numVols);
					}
			} 
		}
		
		// bail out if nothing found (to avoid runtime error!)
		if (mpShiftIdDelta.size() == 0)
			return;
			
		// now that we have the Id's of the shifts, let's get them from the database, update them by the number of volunteers, and then commit.
		list<Volunteer_Shift__c> listShifts = new list<Volunteer_Shift__c>();
		listShifts = [select Id, Total_Volunteers__c from Volunteer_Shift__c where Id in :mpShiftIdDelta.keySet()];
		
		// loop through and update them
		for (Volunteer_Shift__c shift : listShifts) {
			Double numVols = shift.Total_Volunteers__c;
			if (numVols == null || resetTotals) numVols = 0;
			shift.Total_Volunteers__c = numVols + mpShiftIdDelta.get(shift.Id);
		}
		update listShifts;
	}
	
	
	// global utility used to detect whether the Non Profit Starter Pack is installed in this instance.
	private static boolean fCheckedForNPSP = false;
	global static boolean IsNPSPInstalled {
		get {
			if (!fCheckedForNPSP) {
				Schema.SObjectType token = Schema.getGlobalDescribe().get('npe01__OppPayment__c');
				IsNPSPInstalled = (token != null);
				fCheckedForNPSP = true;
			}
			return IsNPSPInstalled;
		}
		set;
	}	
	
    // global utility used to detect whether the Volunteers is running in a managed instance or unmanaged instance
    private static boolean fCheckedForVolunteersNamespace = false;
    global static boolean IsManagedCode {
        get {
            if (!fCheckedForVolunteersNamespace) {
            	// in order for this call to work as expected, we must be API Version 28, but we
            	// want to stay at version 25, so let's find another way!!
                //Schema.SObjectType token = Schema.getGlobalDescribe().get('GW_Volunteers__Volunteer_Job__c');
                //IsManagedCode = (token != null);

    			Map<String, Schema.SObjectField> M = Schema.SObjectType.Contact.fields.getMap();
    			Schema.SObjectField fld = M.get('gw_volunteers__volunteer_status__c');
				IsManagedCode = (fld != null);
                
                fCheckedForVolunteersNamespace = true;
            }
            return IsManagedCode;
        }
        set;
    }   

    /*******************************************************************************************************
    * @description Static method that takes a string
    * If we are in a managed package, tokens in dynamic SOQL must include the package namespace prefix.
    * If you ever deploy this package as unmanaged, this routine will do nothing!
    * @param str token name 
    * @return token name, with namespace prefix, if required.
    ********************************************************************************************************/
    global static string StrTokenNSPrefix(string str) {
        if (!IsManagedCode) return str;
        str = 'GW_Volunteers__' + str;
        return str;
    }
  
    private static boolean isFirstnameInContactMatchRules {
    	get {
    		string str = VolunteersSettings.Contact_Matching_Rule__c;
    		if (str == null || str == '')
                return false;
    		return str.contains('Firstname');
    	}
    }

    private static boolean isLastnameInContactMatchRules {
        get {
            string str = VolunteersSettings.Contact_Matching_Rule__c;
            if (str == null || str == '')
                return false;
            return str.contains('Lastname');
        }
    }

    private static boolean isEmailInContactMatchRules {
        get {
            string str = VolunteersSettings.Contact_Matching_Rule__c;
            if (str == null || str == '')
                return false;
            return str.contains('Email');
        }
    } 

	// utility to verify all the specified fields are accessible to the current user.
	// fields that are not accessible will have a pageMessage added to the current page
	// so the warning is displayed to the user.
	global static void testObjectFieldVisibility(string strObj, list<string>listStrField) {
		
		Map<String, Schema.SObjectType> gd;
		Schema.DescribeSObjectResult sobjDescr;
		Map<String, Schema.SObjectField> mapFieldDesc;
		
		// Obtaining the field name/token map for the object
	    gd = Schema.getGlobalDescribe();
	    if (gd != null)
	    	sobjDescr = gd.get(strObj).getDescribe();
	    if (sobjDescr != null)
	    	mapFieldDesc = sobjDescr.fields.getMap();
	    if (mapFieldDesc !=  null)
		    for (String strField : listStrField) {
				// Check if the user has access on the each field
		        // note that fields in our own package must not have their prefix for the Describe Field Map  
		        Schema.SObjectField fld = mapFieldDesc.get(strField.replace('GW_Volunteers__', ''));     
		        if (fld != null && !fld.getDescribe().isAccessible()) {
		        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Field ' + strObj + '.' + strField +
		          		' needs to have field level security enabled on the Site\'s Guest User profile. Please see the V4S Installation & Configuration Guide.'));
		        } 
		    }
	}

     
}