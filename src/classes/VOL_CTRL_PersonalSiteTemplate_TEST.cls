// Written by David Habib, copyright (c) 2010-2014 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@isTest
public with sharing class VOL_CTRL_PersonalSiteTemplate_TEST {

    //==================== TEST METHOD(s) ======================================
    
    @isTest(SeeAllData=true)
    public static void TestPersonalSiteTemplate() {

        //point to our VF page
        PageReference p = new PageReference('Page.PersonalSiteTemplate');
        Test.setCurrentPageReference(p);
        
        //instantiate the controller for this page
        VOL_CTRL_PersonalSiteTemplate ctrl = new VOL_CTRL_PersonalSiteTemplate();
		system.assertNotEquals(null, ctrl.strURLtoCSSFile);
    }    	

}