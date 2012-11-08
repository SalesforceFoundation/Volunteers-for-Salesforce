// Written by David Habib, copyright (c) 2010, 2011 Groundwire, 1402 3rd Avenue, Suite 1000, Seattle, WA 98101
// This program is free software; you can redistribute it and/or modify it under the terms of the 
// GNU General Public License version 3 as published by the Free Software Foundation. http://www.gnu.org/licenses/gpl.html

@isTest
private class VOL_TEST_Campaign_Trigger {

    static testMethod void myUnitTest() {

        // test creating a single campaign.
        Campaign cmp = new Campaign(recordtypeid=VOL_SharedCode.recordtypeIdVolunteersCampaign, name='Test Campaign', IsActive=true);
        insert cmp;
        list<CampaignMemberStatus> listCMS = [Select Id From CampaignMemberStatus WHERE CampaignId = :cmp.Id];
        System.Assert(listCMS.Size() == 5);
        
        // test creating multiple campaigns.
        list<Campaign> listCmp = new list<Campaign>();
        for (integer i = 0; i < 10; i++) {
            Campaign cmpI = new Campaign(recordtypeid=VOL_SharedCode.recordtypeIdVolunteersCampaign, name='Test Campaign' + i, IsActive=true);
            listCmp.add(cmpI);
        }
        insert listCmp;
        set<ID> setCmpId = new set<ID>();
        for (Campaign cmpT : listCmp) {
            setCmpId.add(cmpT.Id);
        }
        list<CampaignMemberStatus> listCMS2 = [Select Id From CampaignMemberStatus WHERE CampaignId in :setCmpId];
        System.Assert(listCMS2.Size() == 50);
        
    }
}