/**
*
* @author Christian Carter, @cdcarter
* @date 10/6/2015
* @description AutoCompleter finds all Hours records related to Shifts that are in the past, and 
* marks ones that were 'Confirmed' as 'Completed'. This makes it so the volunteer manager only
* has to enter no-show volunteers, instead of spend time entering people who show up. It relies
* on Shift information. It is a schedulable job.
*
**/

global class VOL_AutoCompleter implements Database.Batchable<SObject>, Schedulable {
    /**********************************************************************************************
    * @description contains the query that will find all Confimed hours records from shifts
    * in the past.
    */
    global static String query = 'SELECT Id,Hours_Worked__c,'+
            'Volunteer_Shift__r.Duration__c '+
            'FROM Volunteer_Hours__c '+
            'WHERE Status__c = \'Confirmed\' '+
            'AND Shift_Start_Date_Time__c < TODAY '+
            'AND Do_Not_AutoComplete__c != true';

    /**********************************************************************************************
    * @description Standard schedulable execute method.  This simply gets the batch started 
    * when called from a scheduled job.  
    *
    * @param sc The system SchedulableContext
    */    

    global void execute(SchedulableContext sc) {
        Database.executeBatch(this,100);
    }
    
    /**********************************************************************************************
    * @description Standard batch start method.
    *
    * @param bc The system BatchableContext 
    *
    * @return a QueryLocator for the Hours objects to be updated, as defined 
    * in VOL_AutoCompleter.query
    */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(VOL_AutoCompleter.query);
    }

    /**********************************************************************************************
    * @description The main batch execute method
    *
    * @param bc The system BatchableContext
    * @param listSobj The Volunteer_Hours__c objects to be processed in this batch
    */

    global void execute(Database.BatchableContext bc, List<Sobject> listSobj) {
        VOL_AutoCompleter.autoCompleteHours((List<Volunteer_Hours__c>) listSobj);
    }
    /**********************************************************************************************
    * @description An empty batch finish method
    */

    global void finish(Database.BatchableContext bc) {
        return;
    }

    /**********************************************************************************************
    * @description The meat of the job. It updates the status to Complete (all records passed in 
    * had a status of 'Confirmed' when run by the classes static query) and sets the Hours Worked
    * to the duration of the shift, if appropriate
    * 
    * @param hoursToProcess the list of Volunteer_Hours__c objects to process in this batch.
    */
    
    global static void autoCompleteHours(List<Volunteer_Hours__c> hoursToProcess) {
        for(Volunteer_Hours__c hr : hoursToProcess) {
            if(hr.Hours_Worked__c == null) {
                hr.Hours_Worked__c = hr.Volunteer_Shift__r.Duration__c;
            } 
            hr.Status__c = 'Completed';
        }
        
        update hoursToProcess;
    }

}