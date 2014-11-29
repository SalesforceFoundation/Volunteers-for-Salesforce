// Written by David Habib, copyright (c) 2010-2014 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@isTest
public with sharing class VOL_SharedCode_TEST {


    //==================== TEST METHOD(s) ======================================
    static testmethod void CodeCoverageTests() {
        // since this class is all shared code, it gets heavily exercised by all other test code.       
        // we just need to add a test for hitting the scenario where there aren't any settings specified in the instance.
        
        //clear out whatever settings exist
        delete [select id from Volunteers_Settings__c];
        System.Assert(VOL_SharedCode.VolunteersSettings != null);
        System.Assert(VOL_SharedCode.VolunteersSettings.Signup_Bucket_Account_On_Create__c == null);
        
        Contact c = new Contact(lastname='foo');
        insert c;
        Contact c2 = new Contact();
        VOL_SharedCode.LoadAndCopyObject(c.Id, c2);
        System.assertEquals('foo', c2.LastName);
            
        Contact c3 = new Contact();
        VOL_SharedCodeAPI25.LoadAndCopyObject(c.Id, c3);
        System.assertEquals('foo', c3.LastName);
    }
    
    /*******************************************************************************************************
    * @description test methods to test all permutations of the Contact Matching Rule.
    * @return void
    */ 
    static testmethod void testContactMatchRule1() {
    	testContactMatchRule('Firstname;Lastname;Email');
    }
    static testmethod void testContactMatchRule2() {
    	testContactMatchRule('Firstname;Lastname');
    }
    static testmethod void testContactMatchRule3() {
    	testContactMatchRule('Firstname;Email');
    }
    static testmethod void testContactMatchRule4() {
    	testContactMatchRule('Lastname;Email');
    }
    static testmethod void testContactMatchRule5() {
    	testContactMatchRule('');
    }
    static testmethod void testContactMatchRule6() {
    	testContactMatchRule('Firstname;');
    }
    static testmethod void testContactMatchRule7() {
    	testContactMatchRule('Lastname');
    }
    static testmethod void testContactMatchRule8() {
    	testContactMatchRule('Email');
    }
    static void testContactMatchRule(string strRule) {

        Volunteers_Settings__c settings = new Volunteers_Settings__c();
        settings.Signup_Creates_Contacts_If_No_Match__c = true;
        settings.Signup_Matches_Existing_Contacts__c = true;
        settings.Contact_Matching_Rule__c = strRule;
        VOL_SharedCode.getVolunteersSettingsForTests(settings);

		// test data
		list<Contact> listCon = new list<Contact>();
		listCon.add(new Contact(Firstname='Fred', Lastname='Smith', Email='fred@smith.com'));
		listCon.add(new Contact(Firstname='Fred', Lastname='Smith', Email=null));
		listCon.add(new Contact(Firstname='Fred', Lastname='Smith', Email='NOTfred@smith.com'));
		listCon.add(new Contact(Firstname='NOTFred', Lastname='Smith', Email='fred@smith.com'));
		listCon.add(new Contact(Firstname='Fred', Lastname='NOTSmith', Email='fred@smith.com'));
		insert listCon;
		
        list<string> listStrFields = new list<string>{'Id', 'Firstname', 'Lastname', 'Email'};        
		list<Contact> listCon2 = VOL_SharedCode.LookupContact(listCon[0], listStrFields);
		
		if (strRule == 'Firstname;Lastname;Email') {
			system.assertEquals(1, listCon2.size());
		}
		if (strRule == 'Firstname;Email') {
			system.assertEquals(2, listCon2.size());
		}
		if (strRule == 'Lastname;Email') {
			system.assertEquals(2, listCon2.size());
		}
		if (strRule == 'Firstname;Lastname') {
			system.assertEquals(3, listCon2.size());
		}
		if (strRule == 'Email') {
			system.assertEquals(3, listCon2.size());
		}
		if (strRule == 'Firstname') {
			system.assertEquals(4, listCon2.size());
		}
		if (strRule == 'Lastname') {
			system.assertEquals(4, listCon2.size());
		}
		if (strRule == '') {  // we treat blank as 'Firstname;Lastname;Email'
			system.assertEquals(1, listCon2.size());
		}
    }


}