// Written by David Habib, copyright (c) 2010-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

trigger VOL_VolunteerHours_ShiftRollups on Volunteer_Hours__c (after delete, after insert, after undelete, after update) {
	
	// consider both newMap and oldMap.
	// for each hours object, there are two potential shifts it interacts with.
	// within a batch of hours changes (import scenario), multiple hours can affect the same shift.
	// thus need to keep track of the shifts to update, their original value, and the sum of their changed values.
	
	// Insert scenario: status=Confirmed or Completed. Shift <> null. Number of Volunteers <> null.
	// Delete scenario: status=Confirmed or Completed.  Shift <> null. Number of Volunteers <> null.
	// Update scenario: just treat as a delete and an insert, since we already have to handle multiple changes to same job!
	

	map<Id, Double> mpShiftIdDelta = new map<Id, Double>();
	
	// first we go through the new hours, and add up the number of volunteers per shift
	if (trigger.new != null) {
		for (Volunteer_Hours__c hr : trigger.new) {
			if ((hr.Status__c == 'Confirmed' || hr.Status__c == 'Completed') &&
				(hr.Volunteer_Shift__c <> null && hr.Number_Of_Volunteers__c != null)) {
					Double numVols = mpShiftIdDelta.get(hr.Volunteer_Shift__c);
					if (numVols == null) numVols = 0;
					numVols += hr.Number_of_Volunteers__c;
					mpShiftIdDelta.put(hr.Volunteer_Shift__c, numVols);
				}
		} 
	}
	
	// second we go through the old hours, and subtract the number of volunteers per shift		
	if (trigger.old != null) {
		for (Volunteer_Hours__c hr : trigger.old) {
			if ((hr.Status__c == 'Confirmed' || hr.Status__c == 'Completed') &&
				(hr.Volunteer_Shift__c <> null && hr.Number_Of_Volunteers__c != null)) {
					Double numVols = mpShiftIdDelta.get(hr.Volunteer_Shift__c);
					if (numVols == null) numVols = 0;
					numVols -= hr.Number_of_Volunteers__c;
					mpShiftIdDelta.put(hr.Volunteer_Shift__c, numVols);
				}
		} 
	}
		
	// now that we have the Id's of the shifts, let's get them from the database, update them by the number of volunteers, and then commit.
	list<Volunteer_Shift__c> listShifts = new list<Volunteer_Shift__c>();
	listShifts = [select Id, Total_Volunteers__c from Volunteer_Shift__c where Id in :mpShiftIdDelta.keySet()];
	
	// loop through and update them
	for (Volunteer_Shift__c shift : listShifts) {
		Double numVols = shift.Total_Volunteers__c;
		if (numVols == null) numVols = 0;
		shift.Total_Volunteers__c = numVols + mpShiftIdDelta.get(shift.Id);
	}
	update listShifts;

}