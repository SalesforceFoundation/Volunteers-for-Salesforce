// Written by David Habib, copyright (c) 2010-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

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