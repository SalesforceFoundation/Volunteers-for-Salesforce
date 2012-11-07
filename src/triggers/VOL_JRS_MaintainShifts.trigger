trigger VOL_JRS_MaintainShifts on Job_Recurrence_Schedule__c (after insert, after undelete, after update, before delete) {
	
    if (trigger.isInsert || trigger.isUpdate || trigger.isUnDelete) {
        VOL_JRS.ProcessListJRS(trigger.new, true);  
    }
    
    if (trigger.isDelete) {
        VOL_JRS.DeleteListJRS(trigger.old);        
    }
}