global class VOL_AutoCompleter implements Schedulable {
    global void execute(SchedulableContext sc) {
        List<Volunteer_Hours__c> hoursToProcess = [SELECT Id FROM Volunteer_Hours__c 
                                                                 WHERE Status__c = 'Confirmed'
                                                                 AND Shift_Start_Date_Time__c < TODAY
                                                                 AND Do_Not_AutoComplete__c != true];
        
        for(Volunteer_Hours__c hr : hoursToProcess) {
            hr.Status__c = 'Completed';
        }
        
        update hoursToProcess;
    }
}