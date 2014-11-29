// Written by David Habib, copyright (c) 2010-2014 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@isTest
public with sharing class VOL_StateCountryPicklists_TEST {

    /*******************************************************************************************************
    * @description test method to verify the handling of "State and Country Picklist" feature when enabled 
    * in Salesforce, when updating an existing contact.
    * @return void
    */ 
	static testmethod void testStateCountryPicklistUpdateExisting() {
		
        // create test bucket account
        Account acc = new Account(Name='Test Individual Bucket Account');
        insert acc;		
		
		// save a contact
		Contact con = new Contact();
		con.Firstname = 'test';
		con.Lastname = 'test';
		con.Email = 'test@test.com';
		con.AccountId = acc.Id;
		insert con;
		
		// create our in-memory contact who should match the one we saved
		Contact conEdit = new Contact();
		conEdit.Firstname = 'test';
		conEdit.Lastname = 'test';
		conEdit.Email = 'test@test.com';
		conEdit.MailingCity = 'Seattle';
		conEdit.MailingState = 'wa';
		
		// call our code to match and update the existing contact
		list<string> listStrFields = new list<string>{'Id','Firstname','Lastname','Email','MailingCity','MailingState','MailingCountry'};
		ID id = VOL_SharedCode.CreateOrUpdateContactFS(null, conEdit, null, listStrFields); 
		
		// verify the address fields copied correctly
		Contact conVerify = [select Id, Lastname, Email, MailingCity, MailingState, MailingCountry from Contact where Id = :id];
		system.assertEquals('Seattle', conVerify.MailingCity);
		if (VOL_StateCountryPicklists.isStateCountryPicklistsEnabled) {
			system.assertEquals('Washington', conVerify.MailingState);
			system.assertEquals('United States', conVerify.MailingCountry);
		} else {
			system.assertEquals('wa', conVerify.MailingState);
			system.assertEquals(null, conVerify.MailingCountry);			
		}
	}

    /*******************************************************************************************************
    * @description test method to verify the handling of "State and Country Picklist" feature when enabled 
    * in Salesforce, when creating a new contact.
    * @return void
    */ 
	static testmethod void testStateCountryPicklistInsertNew() {
		
        // create test bucket account
        Account acc = new Account(Name='Test Individual Bucket Account');
        insert acc;		
		
		// settings initialization
        Volunteers_Settings__c settings = new Volunteers_Settings__c();
        settings.Signup_Bucket_Account_On_Create__c = 'Test Individual Bucket Account';
        VOL_SharedCode.getVolunteersSettingsForTests(settings);
		
		// create our in-memory contact who should match no one.
		Contact conEdit = new Contact();
		conEdit.Firstname = 'testNew';
		conEdit.Lastname = 'testNew';
		conEdit.Email = 'test@test.com';
		conEdit.MailingCity = 'Seattle';
		conEdit.MailingState = 'wa';
		
		// call our code to match and update the existing contact
		list<string> listStrFields = new list<string>{'Id','Firstname','Lastname','Email','MailingCity','MailingState','MailingCountry'};
		ID id = VOL_SharedCode.CreateOrUpdateContactFS(null, conEdit, null, listStrFields); 
		
		// verify the address fields copied correctly
		Contact conVerify = [select Id, Lastname, Email, MailingCity, MailingState, MailingCountry from Contact where Id = :id];
		system.assertEquals('Seattle', conVerify.MailingCity);
		if (VOL_StateCountryPicklists.isStateCountryPicklistsEnabled) {
			system.assertEquals('Washington', conVerify.MailingState);
			system.assertEquals('United States', conVerify.MailingCountry);
		} else {
			system.assertEquals('wa', conVerify.MailingState);
			system.assertEquals(null, conVerify.MailingCountry);			
		}
	}


}