/*******************************************************************************************************
* @author David Habib
* @date 7/1/2011
* @description Page Controller class for the Open Report visualforce page. 
*
* Written by David Habib, copyright (c) 2011-2013 DJH Consulting, djhconsulting.com 
* This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/
********************************************************************************************************/
public with sharing class VOL_CTRL_OpenReport {
	
	//---------------------------------------------------------------------------------------------
	// Main routine that gets invoked as a page action to redirect to open the specified report.
	// note that it expects a DeveloperName, and it will append any Url parameters to the report,
	// so that you can filter the report.
	//---------------------------------------------------------------------------------------------
	public PageReference OpenReportDevName() {
		string strDevName = ApexPages.currentPage().getParameters().get('ReportDevName');
		if (strDevName == null || strDevName == '') {
			return null;
		}
				
		//redirect to newly created opp in edit mode
		ID reportId = reportIdFromDevName(strDevName);
		if (reportId != null) {
			string strParams = ApexPages.currentPage().getUrl();
			integer iparams = strParams.indexOf('?');
			if (iparams >= 0){
				strParams = strParams.substring(iparams);
			} else {
				strParams = '';
			}
			PageReference page = new PageReference('/' + reportId + strParams);
        	page.setRedirect(true);
        	return page;
		} 
		
		return null;		
	}
 
	/*******************************************************************************************************
	* @description Static method to lookup a reportId given its Developer Name.  This is useful when creating
	* custom links and buttons in Salesforce, that want to load a report, without having to know its specific
	* id in the given Salesforce instance.
	* @param strDevName DeveloperName of the report 
	* @return reportId
	********************************************************************************************************/
	public static ID reportIdFromDevName(string strDevName) { 
		Id reportId = null;
		Report[] rpts = [select Id from Report where DeveloperName = :strDevName];
		if (!rpts.isEmpty()) reportId = rpts[0].Id;
		return reportId;
	}
	
}