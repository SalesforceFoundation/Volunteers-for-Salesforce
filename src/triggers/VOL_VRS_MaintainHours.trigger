trigger VOL_VRS_MaintainHours on Volunteer_Recurrence_Schedule__c (after insert, after undelete, after update, before delete) {

    if (trigger.isInsert || trigger.isUpdate || trigger.isUnDelete) {
        VOL_VRS.ProcessListVRS(trigger.new);  
    }

    if (trigger.isDelete) {
        VOL_VRS.DeleteListVRS(trigger.old);        
    }
}