// Written by David Habib, copyright (c) 2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

trigger VOL_Contact_MaintainHours on Contact (before delete) {

	// Hours are true children of Contacts, but Salesforce doesn't
	// have the cascading delete fire events on the child objects.
	// So let's delete them manually ourselves, so the Hours trigger will get fired.
	if (trigger.isDelete) {
		set<ID> setContactId = new set<ID>();
		for (SObject obj : trigger.old) {
			setContactId.add(obj.Id);
		}
		delete [select Id from Volunteer_Hours__c where Contact__c in :setContactId];
	}

}