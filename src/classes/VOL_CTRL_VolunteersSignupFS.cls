// Written by David Habib, copyright (c) 2010-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

global virtual with sharing class VOL_CTRL_VolunteersSignupFS {
     
    // constructor
    global VOL_CTRL_VolunteersSignupFS() {

		// initial values for potential parameters
    	strLanguage = 'en-us'; 
    	strFileUploadLabel = null;
    	attachment = null;

        // handle optional page parameters (must use string, not ID, to handle null)
        map<string, string> params = ApexPages.currentPage().getParameters();
        string p = params.get('Language');
        if (p != null && p != '') strLanguage = p;
        p = params.get('FileUploadLabel');
        if (p != null && p != '') {
        	strFileUploadLabel = p;
        	attachment = new Attachment();
        }

        // we now get the fields from the fieldset
        listStrFields = VOL_SharedCode.listStrFieldsFromContactFieldSet(Schema.SObjectType.Contact.fieldSets.VolunteersSignupFS);

        // output error page messages for any field that doesn't have visibility correctly set.
        VOL_SharedCode.testObjectFieldVisibility('Contact', listStrFields);
    } 
            
    global Contact contact { 
        get {
            if (contact == null) contact = new Contact();
            return contact;
        }       
        set; 
    }

    global string strURLtoCSSFile { 
        get { 
            if (strURLtoCSSFile == null) {
                list<Document> listDocs = [SELECT Name, Id From Document WHERE Name = 'VolunteersSignupCSS.css' LIMIT 1 ];
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
    global string strFileUploadLabel { get; set; }
    global String StrSaveResult { get; set; }    
    global list<string> listStrFields { get; set; } 
    global Attachment attachment { get; set; }   
        
    global virtual PageReference Save() {  
    	try { 
    		// save or update the contact              
	        ID contactId = VOL_SharedCode.CreateOrUpdateContactFS(null, contact, contact.Volunteer_Organization__c, listStrFields, true);
			
			// upload any attachment
			if (contactId != null && attachment != null && attachment.body != null) {
				attachment.ParentId = contactId;
				attachment.Description = strFileUploadLabel + ' ' + system.label.labelFileUploadDescription;
				insert attachment;
				attachment = new Attachment();
			}
	        StrSaveResult = system.label.labelVolunteerSignupThankYou;
	        contact = null; // so fields get reset to null.
    	} catch (exception ex) {
    		StrSaveResult = ex.getMessage(); 
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, strSaveResult)); 
    	}
        return null;
    }

	// this was a testmethod which can't be compiled in this class under api 31.  
	// but because it was marked global, it could not be completely removed.
    global static void CodeCoverageTests() {}

}