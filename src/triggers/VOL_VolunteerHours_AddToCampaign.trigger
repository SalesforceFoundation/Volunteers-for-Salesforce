// Written by David Habib, copyright (c) 2010-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

trigger VOL_VolunteerHours_AddToCampaign on Volunteer_Hours__c (after insert, after update) {

	// TASK1: Adding to Campaigns
	// given a list of hours, we need to keep track of all the contacts for a given campaign.
	// with that info, we'll need to see if they have CampaignMember records.
	// if they don't, we'll create a CampaignMember.
	// if they do, we might need to update the CampaignMember.
	set<Id> setContactId = new set<Id>();
	set<Id> setCampaignId = new set<Id>();
	
	// TASK2: Setting Contact's Volunteer Status 
	// if the volunteer hours are being marked confirmed or completed, mark them active.
	set<Id> setContactIdMarkActive = new set<Id>();	
	
	// the lists of Campaign Members to add and update
	list<CampaignMember> listCMToAdd = new list<CampaignMember>();
	list<CampaignMember> listCMToUpdate = new list<CampaignMember>();
	set<Id> setCMIdToUpdate = new set<Id>();
	
	// first we go through the new/updated hours, and find the volunteers and their campaigns
	if (trigger.new != null) {
		for (Volunteer_Hours__c hr : trigger.new) {
			setContactId.add(hr.Contact__c);
			setCampaignId.add(hr.Volunteer_Campaign__c);
		}						
	}
	
	// also need to look for CampaignMember record thats were already there in the update case
	if (trigger.old != null) {
		for (Volunteer_Hours__c hr : trigger.old) {
			setContactId.add(hr.Contact__c);
			setCampaignId.add(hr.Volunteer_Campaign__c);
		}						
	}
	
	// now find all the potential CampaignMembers.  Unfortunately, we can't do a soql
	// that will give us the exact match, so this really is the list of potential CM's.
	// this map's keys will be a concatenation of contactID & campaignID 
	map<string,CampaignMember> mapComboIdToCM = new map<string,CampaignMember>();
	for (CampaignMember cm : [Select Id, ContactId, CampaignId, Status, HasResponded From CampaignMember 
			WHERE ContactId IN :setContactId AND CampaignId IN :setCampaignId]) {
		string comboId = cm.ContactID + '|' + cm.CampaignId;
		mapComboIdToCM.put(comboId, cm);
	}
	
	// now go through our list of hours again, and look for their CampaignMembers
	if (trigger.new != null) {
		for (Volunteer_Hours__c hr : trigger.new) {
			// CAUTION!! Since the Volunteer_Campaign__c calculated field is text, need to cast it to ID to get full 18 chars!
			string comboId = hr.Contact__c + '|' + (ID)hr.Volunteer_Campaign__c;
			
			// do they already have a CampaignMember
			CampaignMember cm = mapComboIdToCM.get(comboId);
			if (cm == null) {
				cm = new CampaignMember(CampaignId = hr.Volunteer_Campaign__c, ContactId = hr.Contact__c, Status=hr.Status__c);
				listCMToAdd.add(cm);
				mapComboIdToCM.put(comboId, cm);	// add it to the map to avoid creating duplicate CM's
			} else {
				cm.Status = hr.Status__c; // NOTE: last hour record wins the CM status.  Too hard to define precedence rules and heuristics.
				// use the set to only put cm's on the list once!
				if (setCMIdToUpdate.add(cm.id)) listCMToUpdate.add(cm);
				mapComboIdToCM.put(comboId, cm);	// add it to the map to avoid creating duplicate CM's
			}

			// keep track of the active volunteers
			if (hr.Status__c == 'Confirmed' || hr.Status__c == 'Completed') {
				setContactIdMarkActive.add(hr.Contact__c);
			}

		}
		
		insert listCMToAdd;
		update listCMToUpdate;
		
		// now take care of setting the active volunteers
		list<Contact> listContactMarkActive = new list<Contact>();
		for (Contact con : [select Id, Volunteer_Status__c from Contact where Id in :setContactIdMarkActive]) {
			if (con.Volunteer_Status__c != 'Active') {
				con.Volunteer_Status__c = 'Active';				
				listContactMarkActive.add(con);
			}
		}
		update listContactMarkActive;
	}

}