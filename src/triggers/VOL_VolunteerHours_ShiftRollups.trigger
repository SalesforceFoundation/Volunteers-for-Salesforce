// Written by David Habib, copyright (c) 2010-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

trigger VOL_VolunteerHours_ShiftRollups on Volunteer_Hours__c (before delete, after insert, after undelete, after update) {
	
	// the trigger logic was moved to a seperate class so that we
	// can also use it in scenarios where Salesforce doesn't fire the trigger:
	// ie, deleting, undeleting, and merging a Contact doesn't fire triggers on its children (Hours)
	VOL_SharedCode.VolunteerHoursTrigger(trigger.old, trigger.new, false);

}