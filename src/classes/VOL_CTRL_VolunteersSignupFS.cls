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
	        ID contactId = VOL_SharedCode.CreateOrUpdateContactFS(null, contact, contact.Volunteer_Organization__c, listStrFields);
			
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
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage())); 		    		
    	}
        return null;
    }


    //==================== TEST METHOD(s) ======================================
    global static testmethod void CodeCoverageTests() {

        // create test bucket account
        Account acc = new Account(Name='Test Individual Bucket Account');
        insert acc;
        
        // exercise some initial settings code
        System.Assert(VOL_SharedCode.VolunteersSettings != null);
        
        // specify our settings        
        Volunteers_Settings__c settings = new Volunteers_Settings__c();
        settings.Signup_Bucket_Account_On_Create__c = 'Test Individual Bucket Account';
        VOL_SharedCode.getVolunteersSettingsForTests(settings);
        
        PageReference pageRef=Page.VolunteersSignupFS; 
        pageRef.getParameters().put('FileUploadLabel', 'Upload a test file');        
        Test.setCurrentPage(pageRef); 

        //instantiate the controller 
        VOL_CTRL_VolunteersSignupFS ctrl = new VOL_CTRL_VolunteersSignupFS();

        // scenario 1: creating a new contact to the bucket account.
        Contact contact = ctrl.contact;
        System.Assert(contact != null);
        contact.FirstName = 'TestFirstName';
        contact.LastName = 'TestLastName';
        contact.Email = 'foovolunteer@bar.com';
        ctrl.Save();
        System.AssertEquals(system.label.labelVolunteerSignupThankYou, ctrl.StrSaveResult);
                
        // make sure it got created correctly
        contact = [select Id, AccountId from Contact where Email='foovolunteer@bar.com' and Firstname='TestFirstName' limit 1];
        System.Assert(contact.Id != null);
        System.AssertEquals(VOL_SharedCode.SettingsBucketAccountId, contact.AccountId);
        
        
        // scenario 2: creating a new contact to an existing account
        Account acc2 = new Account(Name='My GW Volunteers Test Company');
        insert acc2;
        contact = ctrl.contact;
        System.Assert(contact != null);
        contact.FirstName = 'TestFirstName2';
        contact.LastName = 'TestLastName2';
        contact.Email = 'foo2volunteer@bar.com';
        contact.Volunteer_Organization__c = 'My GW Volunteers Test Company';      
        ctrl.Save();
        System.AssertEquals(system.label.labelVolunteerSignupThankYou, ctrl.StrSaveResult);
                
        // make sure it got created
        contact = [select Id, AccountId from Contact where Email='foo2volunteer@bar.com' and Firstname='TestFirstName2' limit 1];
        System.Assert(contact.Id != null);
        System.AssertEquals(acc2.Id, contact.AccountId);
        
        
        // scenario 3: update to an existing contact
        contact = ctrl.contact;
        System.Assert(contact != null);
        contact.FirstName = 'TestFirstName2';
        contact.LastName = 'TestLastName2';
        contact.Email = 'foo2volunteer@bar.com';
        contact.Phone = '425-123-4567';
        contact.HomePhone = '206-123-4567';
        ctrl.Save();
        System.AssertEquals(system.label.labelVolunteerSignupThankYou, ctrl.StrSaveResult);
                
        // make sure the existing contact's volunteer status field was updated          
        contact = [select Id, Volunteer_Status__c, Phone from Contact where Email='foo2volunteer@bar.com' and Firstname='TestFirstName2' limit 1];
        System.AssertEquals('New Sign Up', contact.Volunteer_Status__c);
        System.Assert(('425-123-4567' == contact.Phone) || ('206-123-4567' == contact.Phone));
                
        // anything else
        System.Assert(ctrl.strURLtoCSSFile == ctrl.strURLtoCSSFile);
        
        // attachments
        System.assert(ctrl.attachment != null);
        ctrl.attachment.Body = Blob.valueof('some random test string');
        System.assert(ctrl.attachment.body != null);
        ctrl.Save();
        
    }       

}