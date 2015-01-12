// Written by David Habib, copyright (c) 2010-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

global with sharing class VOL_CTRL_PersonalSiteContactLookup {

    // constructor
    global VOL_CTRL_PersonalSiteContactLookup() {

		// initial values for potential parameters
    	strLanguage = 'en-us'; 
    	strResult = null;

        // handle optional page parameters (must use string, not ID, to handle null)
        map<string, string> params = ApexPages.currentPage().getParameters();
        string p = params.get('Language');
        if (p != null && p != '') strLanguage = p;
    }	
	
	// returns the correct URL for the CSS override file
    global string strURLtoCSSFile { 
        get { 
            if (strURLtoCSSFile == null) {
                list<Document> listDocs = [SELECT Name, Id From Document WHERE Name = 'VolunteersPersonalSiteCSS.css' LIMIT 1 ];
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
    
    global Contact contact {
        get {
            if (contact == null) contact = new Contact();
            return contact;
        }       
        set; 
    }

	global string strResult { get; set; }
    global string strLanguage { get; set; }
	
	// the action method called from the page to lookup the contact, and to send them email if found.
	global PageReference LookupContact() {
		
		list<Contact> listCon = VOL_SharedCode.LookupContact(contact, null);
		if (listCon == null || listCon.size() == 0) {
			strResult = System.Label.labelContactLookupNotFound;
		} else {
			SendEmailToContact(listCon[0]);
		}				
		return null;
	}
	
	// get the Id of the Email Template to use
	public ID emailTemplateId {
		get {
			if (emailTemplateId == null) {
				list<EmailTemplate> listT = [select Id from EmailTemplate where Name='Volunteers Personal Site Contact Lookup' limit 1];
				if (listT.size() > 0) emailTemplateId = listT[0].Id;
			}
			return emailTemplateId;
		}
		set;
	}
	
	// get the Id of the Org-wide Email Address to use
	public ID orgWideEmailId {
		get {
			if (orgWideEmailId == null) {
				string strOwa = VOL_SharedCode.VolunteersSettings.Personal_Site_Org_Wide_Email_Name__c;
				if (strOwa != null) {
					list<OrgWideEmailAddress> listOwa = [select id from OrgWideEmailAddress	where DisplayName = :strOwa];
					if (listOwa.size() > 0) orgWideEmailId = listOwa[0].Id;
				}
			}
			return orgWideEmailId;
		}
		set;
	}
		
	// send the email to the passed in contact
	public void SendEmailToContact(Contact con) {
		strResult = null;			
    	Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setTargetObjectId(con.Id);
		mail.setSaveAsActivity(true);
		mail.setTemplateID(emailTemplateId);	
		if (orgWideEmailId != null) {
			mail.setOrgWideEmailAddressId(orgWideEmailId);
		}		
		list<Messaging.SendEmailResult> listSER;
		listSER = Messaging.sendEmail(new Messaging.Email[] { mail }, false);
		if (listSER[0].isSuccess()) {
			strResult = System.Label.labelContactLookupSuccess;
		} else {
			list<Messaging.SendEmailError> listSEE = listSER[0].getErrors();
			for (Messaging.SendEmailError see : listSEE) {
				ID objId = see.getTargetObjectId();
				if (objId == null) {
					// see if we can parse it out of the error string.
					string strErr = see.getMessage();
					integer ich = strErr.lastIndexOf(' for id : ');
					if (ich > = 0) {
						objId = strErr.substring(ich + 10);
					}
				}
				list<Contact> listCon = [select Name, Email from Contact where Id =: objId];
				string strDetails = '';
				if (listCon.size() > 0) 
					strDetails = ' ' + listCon[0].Name + ' (' + listCon[0].Email + ') '; 
				strResult += see.getStatusCode() + ': ' + see.getMessage() + strDetails;
			}
		}			
	}					

}