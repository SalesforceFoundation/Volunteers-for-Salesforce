// Written by David Habib, copyright (c) 2010-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

global virtual with sharing class VOL_CTRL_VolunteersSignup {
            
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
        
    global virtual PageReference Save() {
        // Save behavior is modified by using Custom Settings:
        // Signup_Matches_Existing_Contacts__c
        // Signup_Creates_Contacts_If_No_Match__c
        // Signup_Bucket_Account_On_Create__c
                 
        VOL_SharedCode.CreateContactOrLead(contact,
            VOL_SharedCode.VolunteersSettings.Signup_Matches_Existing_Contacts__c,
            VOL_SharedCode.VolunteersSettings.Signup_Creates_Contacts_If_No_Match__c);   
                         
        StrSaveResult = 'Thank you for signing up for volunteering.';
        contact = null; // so fields get reset to null.
        return null;
        }

    global String StrSaveResult { get; set; }

	// this was a testmethod which can't be compiled in this class under api 31.  
	// but because it was marked global, it could not be completely removed.
    global static void CodeCoverageTests() {}
    
}