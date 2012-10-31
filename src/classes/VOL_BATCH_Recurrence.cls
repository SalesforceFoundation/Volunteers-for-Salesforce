global with sharing class VOL_BATCH_Recurrence implements Database.Batchable<Sobject>, Schedulable {

	private string strSoql { get; set; }

    /*******************************************************************************************************
	* @description This constructor is needed to allow this class to be schedulable.
	*/
    global VOL_BATCH_Recurrence() { }
    
    /*******************************************************************************************************
	* @description Standard schedulable execute method.  This simply gets the batch started when called from 
	* a scheduled job.  
	*/    
    global void execute(SchedulableContext sc) {
		database.executebatch(this);                 
    }
    
    /*******************************************************************************************************
	* @description Standard batch start method.    
	*/    
    global Database.QueryLocator start(Database.BatchableContext bc) { 
    	Date dt = system.today();
    	strSoql = 'select Id, Name, Days_of_Week__c, Desired_Number_of_Volunteers__c, Duration__c, Description__c, ' +
    		' Schedule_End_Date__c, Schedule_Start_Date_Time__c, Volunteer_Job__c, Weekly_Occurrence__c ' +
    		' from Job_Recurrence_Schedule__c where ' +
    		' Schedule_End_Date__c = null or Schedule_End_Date__c > :dt';
        return Database.getQueryLocator(strSoql);
    }

    /*******************************************************************************************************
	* @description The main batch execute method.  
	*/
    global void execute(Database.BatchableContext BC, List<Sobject> listSObj) {
    	VOL_JRS.ProcessListJRS(listSObj, false);	
    }

    /*******************************************************************************************************
	* @description The standard batch finish method.  
	*/      
    global void finish(Database.BatchableContext bc) {

    }
}