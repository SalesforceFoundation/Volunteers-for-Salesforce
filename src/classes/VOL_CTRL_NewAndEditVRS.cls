/*******************************************************************************************************
* @author David Habib
* @date 12/1/2012
* @description controller class for the New and Update Volunteer Recurrence Schedules visualforce page. 
*
* Written by David Habib, copyright (c) 2013 DJH Consulting, djhconsulting.com 
* This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/
********************************************************************************************************/
public with sharing class VOL_CTRL_NewAndEditVRS {

	public Volunteer_Recurrence_Schedule__c vrs { get; set; }
	public ID jrsId { get; set; }

	//constructor
	public VOL_CTRL_NewAndEditVRS (ApexPages.StandardController controller) {

		//get record from standard controller
        vrs = (Volunteer_Recurrence_Schedule__c)controller.getRecord();	
	}
	
    // the list of Job Recurrence Schedules for the current job
    public list<SelectOption> listSOJRS {
    	get {
    		if (listSOJRS == null) {
		        list<SelectOption> listSO = new list<SelectOption>();
		        listSO.add(new SelectOption('', ''));
		        ID jobId = vrs.Volunteer_Job__c;
		        
		        for (Job_Recurrence_Schedule__c jrs : [select Id, Name, Days_of_Week__c, Duration__c, 
		        	Schedule_Start_Date_Time__c, Schedule_End_Date__c, Weekly_Occurrence__c from Job_Recurrence_Schedule__c 
		        	where Volunteer_Job__c = :jobId limit 999]) {
		            SelectOption so = new SelectOption(jrs.id, jrs.Weekly_Occurrence__c + ' ' + jrs.Days_of_Week__c + ' ' + jrs.Schedule_Start_Date_Time__c.format() + '&nbsp;&nbsp;&nbsp;&nbsp;(' + jrs.name + ')' );
		            so.setEscapeItem(false); 
		            listSO.add(so);
		        }
		        listSOJRS = listSO;
    		}       
	        return listSOJRS;
    	}
    	set;
    }	
    
    // action method called by the page when the Job has changed.
    // this allows us to refresh the lsit of JRS's for the new job.
    public PageReference refreshListSOJRS() {
    	listSOJRS = null;
    	return null;
    }
    
    // action method called by the page when the user chooses a JRS to copy from.
    public PageReference copyScheduleFromJRS() {
		if (jrsId != null) {
			Job_Recurrence_Schedule__c jrs = [select Days_of_Week__c, Duration__c, 
		        	Schedule_Start_Date_Time__c, Schedule_End_Date__c, Weekly_Occurrence__c from Job_Recurrence_Schedule__c 
		        	where Id = :jrsId ];
		    
		    // copy appropriate values
		    vrs.Days_of_Week__c = jrs.Days_of_Week__c;
		    vrs.Duration__c = jrs.Duration__c;
		    vrs.Schedule_Start_Date_Time__c = datetime.newInstance(system.today(), jrs.Schedule_Start_Date_Time__c.time());
		    vrs.Schedule_End_Date__c = jrs.Schedule_End_Date__c;
		    vrs.Weekly_Occurrence__c = jrs.Weekly_Occurrence__c;
		}    	
		return null;
    }

}