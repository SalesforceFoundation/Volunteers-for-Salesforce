// Written by David Habib, copyright (c) 2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

trigger VOL_Contact_MaintainHours on Contact (before delete, after delete, after undelete) {

	// Hours are true children of Contacts, but Salesforce doesn't
	// have the cascading delete fire events on the child objects.
	// So we have to call the trigger ourselves.
	if (trigger.isDelete && trigger.isBefore) {
		set<ID> setContactId = new set<ID>();
		for (SObject obj : trigger.old) {
			setContactId.add(obj.Id);
		}
		list<Volunteer_Hours__c> listHours = new list<Volunteer_Hours__c>();
		listHours = [select Id, Status__c, Volunteer_Shift__c, Volunteer_Job__c, Number_Of_Volunteers__c from Volunteer_Hours__c where Contact__c in :setContactId];
		
		VOL_SharedCode.VolunteerHoursTrigger(listHours, null, false);		
	}

	// in the case of Merge, we've removed the hours from the old shift during the Before Delete.
	// now in the After Delete, we are able to see who the winning contacts are.
	// unfortunately, we can't tell which are the Hours that got moved to the winning contact,
	// so we have to recalc the Shifts rollups for all its hours.
	if (trigger.isDelete && trigger.isAfter) {
		set<ID> setContactId = new set<ID>();
		for (Contact obj : trigger.old) {
			setContactId.add(obj.MasterRecordId);
		}
		list<Volunteer_Hours__c> listHours = new list<Volunteer_Hours__c>();
		listHours = [select Id, Status__c, Volunteer_Shift__c, Volunteer_Job__c, Number_Of_Volunteers__c from Volunteer_Hours__c where Contact__c in :setContactId];
		
		// get all the Hours for the affected Shifts
		set<ID> setShiftId = new set<ID>();
		for (Volunteer_Hours__c hr : listHours) {
			if (hr.Volunteer_Shift__c != null)
				setShiftId.add(hr.Volunteer_Shift__c);
		}
		if (setShiftId.size() > 0) {
			listHours = [select Id, Status__c, Volunteer_Shift__c, Volunteer_Job__c, Number_Of_Volunteers__c from Volunteer_Hours__c where Volunteer_Shift__c in :setShiftId];
			
			VOL_SharedCode.VolunteerHoursTrigger(null, listHours, true);
		}		
	}

	// similar issue with undeletes of contacts.  
	// Salesforce won't fire an undelete trigger on the hours.
	// So we have to call the trigger ourselves.
	if (trigger.isUndelete) {
		set<ID> setContactId = new set<ID>();
		for (SObject obj : trigger.new) {
			setContactId.add(obj.Id);
		}
		list<Volunteer_Hours__c> listHours = new list<Volunteer_Hours__c>();
		listHours = [select Id, Status__c, Volunteer_Shift__c, Volunteer_Job__c, Number_Of_Volunteers__c from Volunteer_Hours__c where Contact__c in :setContactId];
		
		VOL_SharedCode.VolunteerHoursTrigger(null, listHours, false);		
	}


}