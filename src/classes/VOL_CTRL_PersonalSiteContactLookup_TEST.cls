// Written by David Habib, copyright (c) 2010-2014 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@isTest
public with sharing class VOL_CTRL_PersonalSiteContactLookup_TEST {

    //==================== TEST METHOD(s) ======================================
    
    @isTest(SeeAllData=true)
    public static void TestPersonalSiteContactLookup() {

        //point to our VF page
        PageReference p = new PageReference('Page.PersonalSiteContactLookup');
        Test.setCurrentPageReference(p);
        
        //instantiate the controller for this page
        VOL_CTRL_PersonalSiteContactLookup ctrl = new VOL_CTRL_PersonalSiteContactLookup();
		system.assertNotEquals(null, ctrl.strURLtoCSSFile);
		system.assertNotEquals(null, ctrl.contact);
		system.assertNotEquals(null, ctrl.strLanguage);
		system.assertEquals(null, ctrl.strResult);
		system.assertNotEquals(null, ctrl.emailTemplateId);
		system.assert(ctrl.orgWideEmailId == ctrl.orgWideEmailId);
    	
    	// test empty contact
    	ctrl.contact.Firstname = null;
    	ctrl.contact.Lastname = null;
    	ctrl.contact.Email = null;
    	system.assertEquals(null, ctrl.LookupContact());
    	system.assertEquals(System.Label.labelContactLookupNotFound, ctrl.strResult);
    	
    	// test bogus contact
    	ctrl.contact.Firstname = 'Not There';
    	ctrl.contact.Lastname = 'Not There';
    	ctrl.contact.Email = 'NotThere@NotThere.com';
    	system.assertEquals(null, ctrl.LookupContact());
    	system.assertEquals(System.Label.labelContactLookupNotFound, ctrl.strResult);

		// create a temp contact
		Contact con = new Contact();
		con.FirstName = 'LookupTestFirstName';
		con.LastName = 'LookupTestLastName';
		con.Email = 'LookupTestEmail@email.com';
		insert con;
		
		// test existing contact
   		ctrl.contact.FirstName = 'LookupTestFirstName';
		ctrl.contact.LastName = 'LookupTestLastName';
		ctrl.contact.Email = 'LookupTestEmail@email.com';
    	system.assertEquals(null, ctrl.LookupContact());
    	system.assertEquals(System.Label.labelContactLookupSuccess, ctrl.strResult);
				    
		// test error email handling
		con.Email = null;
		update con;
		ctrl.SendEmailToContact(con);
    	system.assertNotEquals(System.Label.labelContactLookupSuccess, ctrl.strResult);
    }
		
}