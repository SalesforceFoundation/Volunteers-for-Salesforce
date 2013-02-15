// Written by David Habib, copyright (c) 2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

trigger VOL_Job_Before on Volunteer_Job__c (before delete) {
	
	// since Volunteer Recurrence Schedules are not true children of Jobs,
	// and only hold a lookup field to Job, we must manually delete them.
	if (trigger.isDelete) {
		set<ID> setJobId = new set<ID>();
		for (SObject obj : trigger.old) {
			setJobId.add(obj.Id);
		}
		delete [select Id from Volunteer_Recurrence_Schedule__c where Volunteer_Job__c in :setJobId];
	}

}