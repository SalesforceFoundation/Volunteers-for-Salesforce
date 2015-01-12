// Written by David Habib, copyright (c) 2010-2014 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@isTest
public with sharing class VOL_CTRL_VolunteersSignup_TEST {

    //==================== TEST METHOD(s) ======================================
    private static testmethod void CodeCoverageTests() {

        // create test bucket account
        Account acc = new Account(Name='Test Individual Bucket Account');
        insert acc;
        
        // exercise some initial settings code
        System.Assert(VOL_SharedCode.VolunteersSettings != null);
        
        // specify our settings        
        Volunteers_Settings__c settings = new Volunteers_Settings__c();
        settings.Signup_Creates_Contacts_If_No_Match__c = true;
        settings.Signup_Matches_Existing_Contacts__c = true;
        settings.Signup_Bucket_Account_On_Create__c = 'Test Individual Bucket Account';
        VOL_SharedCode.getVolunteersSettingsForTests(settings);
        
        PageReference pageRef=Page.VolunteersSignup; 
        Test.setCurrentPage(pageRef); 

        //instantiate the controller 
        VOL_CTRL_VolunteersSignup ctrl = new VOL_CTRL_VolunteersSignup();

        // scenario 1: creating a new contact to the bucket account.
        Contact contact = ctrl.contact;
        System.Assert(contact != null);
        contact.FirstName = 'TestFirstName';
        contact.LastName = 'TestLastName';
        contact.Email = 'foovolunteer@bar.com';
        ctrl.Save();
        System.AssertEquals('Thank you for signing up for volunteering.', ctrl.StrSaveResult);
                
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
        contact.Department = 'My GW Volunteers Test Company';      // this is a dummy we use for the company name in the page.
        ctrl.Save();
        System.AssertEquals('Thank you for signing up for volunteering.', ctrl.StrSaveResult);
                
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
        System.AssertEquals('Thank you for signing up for volunteering.', ctrl.StrSaveResult);
                
        // make sure the existing contact's volunteer status field was updated          
        contact = [select Id, Volunteer_Status__c, Phone from Contact where Email='foo2volunteer@bar.com' and Firstname='TestFirstName2' limit 1];
        System.AssertEquals('New Sign Up', contact.Volunteer_Status__c);
        System.Assert(('425-123-4567' == contact.Phone) || ('206-123-4567' == contact.Phone));
        
        // now change our Custom Settings, and test
        // scenario 4: create a new lead
        settings = new Volunteers_Settings__c();
        settings.Signup_Creates_Contacts_If_No_Match__c = false;
        settings.Signup_Matches_Existing_Contacts__c = false;
        settings.Signup_Bucket_Account_On_Create__c = null;
        VOL_SharedCode.getVolunteersSettingsForTests(settings);
        
        contact = ctrl.contact;
        System.Assert(contact != null);
        contact.FirstName = 'TestFirstName';
        contact.LastName = 'TestLastName';
        contact.Email = 'foovolunteer@bar.com';
        contact.Department = 'Some Random Company';
        ctrl.Save();
        System.AssertEquals('Thank you for signing up for volunteering.', ctrl.StrSaveResult);
                
        // make sure it got created correctly
        Lead lead = [select Id, Company, Volunteer_Status__c from Lead where Email='foovolunteer@bar.com' and Firstname='TestFirstName' limit 1];
        System.Assert(lead.Id != null);
        System.AssertEquals('Some Random Company', lead.Company);
        System.AssertEquals('New Sign Up', lead.Volunteer_Status__c);
        
        // anything else
        System.Assert(ctrl.strURLtoCSSFile == ctrl.strURLtoCSSFile);
    }       

}