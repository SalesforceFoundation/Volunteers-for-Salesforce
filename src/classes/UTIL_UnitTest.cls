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