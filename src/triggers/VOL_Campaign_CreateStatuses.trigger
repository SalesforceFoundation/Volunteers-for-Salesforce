// Written by David Habib, copyright (c) 2010-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

trigger VOL_Campaign_CreateStatuses on Campaign (after insert) {

	// this will hold the id's of all volunteer campaigns.
	set<ID> setCmpId = new set<ID>();
	
    // this list will hold all the new CampaignMembers we will add.
    list<CampaignMemberStatus> listCMSToAdd = new list<CampaignMemberStatus>();
    
    for (Campaign cmp : trigger.new) {
    	
    	// only do work if it's a volunteer campaign
    	if (cmp.RecordTypeId == VOL_SharedCode.recordtypeIdVolunteersCampaign) {
    		
    		// remember the campaign
    		setCmpId.add(cmp.Id);
	    
		    CampaignMemberStatus cms1 = new CampaignMemberStatus(
		        Label = 'Prospect',
		        CampaignId = cmp.Id,
		        HasResponded = false,
		        SortOrder = 100,
		        IsDefault = true
		    );
		    listCMSToAdd.add(cms1);
		
		    CampaignMemberStatus cms2 = new CampaignMemberStatus(
		        Label = 'Confirmed',
		        CampaignId = cmp.Id,
		        HasResponded = true,
		        SortOrder = 200
		    );
		    listCMSToAdd.add(cms2);
		
		    CampaignMemberStatus cms3 = new CampaignMemberStatus(
		        Label = 'Completed',
		        CampaignId = cmp.Id,
		        HasResponded = true,
		        SortOrder = 300
		    );
		    listCMSToAdd.add(cms3);
		    
		    CampaignMemberStatus cms4 = new CampaignMemberStatus(
		        Label = 'No-Show',
		        CampaignId = cmp.Id,
		        HasResponded = false,
		        SortOrder = 400
		    );
		    listCMSTOAdd.add(cms4);

		    CampaignMemberStatus cms5 = new CampaignMemberStatus(
		        Label = 'Canceled',
		        CampaignId = cmp.Id,
		        HasResponded = true,
		        SortOrder = 500
		    );
		    listCMSTOAdd.add(cms5);
    	}		        
    }

    // now get the default CampaignMembers from all Volunteer Campaigns, that we will remove.    
    list<CampaignMemberStatus> listCMSToDel = [Select Id From CampaignMemberStatus WHERE CampaignId in :setCmpId]; 
    
    insert listCMSToAdd;
    delete listCMSToDel;
}