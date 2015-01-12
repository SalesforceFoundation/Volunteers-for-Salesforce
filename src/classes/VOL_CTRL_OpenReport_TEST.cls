// Written by David Habib, copyright (c) 2010-2014 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@isTest
public with sharing class VOL_CTRL_OpenReport_TEST {

	//---------------------------------------------------------------------------------------------
	// TEST CODE
	//---------------------------------------------------------------------------------------------
	@isTest(SeeAllData=true) static void TestOpenReport() {
		PageReference pageRef = Page.OpenReport; 
		Test.setCurrentPage(pageRef); 

		// test no parameters
		VOL_CTRL_OpenReport ctrl = new VOL_CTRL_OpenReport();
		system.assertEquals(null, ctrl.OpenReportDevName());	

		// test null parameters
		ApexPages.currentPage().getParameters().put('ReportDevName', null);
		ctrl = new VOL_CTRL_OpenReport();
		system.assertEquals(null, ctrl.OpenReportDevName());	

		// test bogus parameters
		ApexPages.currentPage().getParameters().put('bogus', 'bogus');
		ctrl = new VOL_CTRL_OpenReport();
		system.assertEquals(null, ctrl.OpenReportDevName());	

		// test bad report name parameters
		ApexPages.currentPage().getParameters().put('ReportDevName', 'bogus report');
		ctrl = new VOL_CTRL_OpenReport();
		system.assertEquals(null, ctrl.OpenReportDevName());	

		// test good report name parameters
		ApexPages.currentPage().getParameters().put('ReportDevName', 'Upcoming_Shifts_with_Volunteers');
		ctrl = new VOL_CTRL_OpenReport();
		system.assertNotEquals(null, ctrl.OpenReportDevName());	
	}
	

}