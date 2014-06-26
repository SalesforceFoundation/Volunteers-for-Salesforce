// Written by David Habib, copyright (c) 2010-2014 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

global with sharing class VOL_CTRL_PersonalSiteReportHours {

    // constructor
    global VOL_CTRL_PersonalSiteReportHours() {

		// initial values for potential parameters
    	strLanguage = 'en-us'; 

        // handle optional page parameters (must use string, not ID, to handle null)
        map<string, string> params = ApexPages.currentPage().getParameters();
        string p = params.get('Language');
        if (p != null && p != '') strLanguage = p;
    }
    
    global string strLanguage { get; set; }
}