/*
    Copyright (c) 2019, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
@IsTest
public class UTIL_UnitTest {
    public static User guestSiteUser {
        get {
            if (guestSiteUser == null) {
                guestSiteUser = findGuestSiteUser();
            }
            return guestSiteUser;
        }
        private set;
    }

    private static User findGuestSiteUser() {
        List<User> guestSiteUsers = [Select Username, UserType, Name, IsActive, Id From User where IsActive = true and UserType = 'Guest' and
        Name like '%Site Guest User%'];

        if (guestSiteUsers.isEmpty()) {
            return null;
        }

        return guestSiteUsers[0];
    }

    public static User createDefaultGuestUser() {
        List<Profile> guestProfiles = [SELECT Id, Name FROM Profile WHERE Name = 'Guest License User'];
        if (guestProfiles.isEmpty()) {
            return null;
        }

        String email = 'guest' + DateTime.now().getTime() + '@testorg.com';

        return new User(
            Alias = 'guest',
            Email = email,
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = guestProfiles[0].Id,
            TimeZoneSidKey = 'America/Chicago',
            UserName = email
        );
    }

    public static Map<Id, SObject> generateData() {
        Map<Id, SObject> sObjectById = new Map<Id, SObject>();
        DateTime now = System.now();

        Campaign campaignRecord = createCampaign('Spring Garden Party ' + now);
        insert campaignRecord;
        sObjectById.put(campaignRecord.Id, campaignRecord);

        Volunteer_Job__c volunteerJob = createJob('Classroom Helper ' + now, campaignRecord.Id);
        insert volunteerJob;
        sObjectById.put(volunteerJob.Id, volunteerJob);

        Contact contactRecord = createContact('Helper ' + now);
        insert contactRecord;
        sObjectById.put(contactRecord.Id, contactRecord);

        return sObjectById;
    }

    public static Campaign createCampaign(String name) {
        return new Campaign(
            RecordTypeId = VOL_SharedCode.recordtypeIdVolunteersCampaign,
            Name = name,
            IsActive = true
        );
    }

    public static Volunteer_Job__c createJob(String name, Id campaignId) {
        return new Volunteer_Job__c(
            Name = name,
            Campaign__c = campaignId
        );
    }

    public static Contact createContact(String lastName) {
        return new Contact(
            FirstName = 'Andy',
            LastName = lastName);
    }
}