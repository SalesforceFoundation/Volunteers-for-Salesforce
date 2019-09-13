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
    private static Map<SObjectType, Map<Id, SObject>> sObjectByIdByType = new Map<SObjectType, Map<Id, SObject>>();
    /**
     * @description: The guest site user when found otherwise creates a default guest user
     */
    public static User guestUser {
        get {
            if (guestUser == null) {
                guestUser = findGuestSiteUser();
            }

            if (guestUser == null) {
                guestUser = createGuestUser();
            }

            return guestUser;
        }
        private set;
    }

    public static void enableElevateGuestUserAccess() {
        VOL_Access.getInstance().elevateGuestUserAccessSetting = true;
    }

    /////// Users ///////

    public static User createGuestUser() {
        String email = 'guest' + '@testorg.com';
        // The OOB guest user profile depends on the type of org
        // packaging org has Standard Guest and Dev orgs have Guest License User
        // scratch orgs have both
        List<Profile> profiles = getProfiles(new Set<String> { 'Standard Guest', 'Guest License User' });
        if (profiles.isEmpty()) {
            return null;
        }

        return createUser(email, profiles[0]);
    }

    public static User createStandardUser() {
        String email = 'guest' + '@testorg.com';

        return createUser(email, getProfileRecord('Standard User'));
    }

    public static User createAdminUser() {
        String email = 'admin' + '@testorg.com';

        return createUser(email, getProfileRecord('System Administrator'));
    }

    private static Profile getProfileRecord(String profileName) {
        List<Profile> profiles = getProfiles(new Set<String>{ profileName });
        return profiles.isEmpty() ? null : profiles[0];
    }

    private static List<Profile> getProfiles(Set<String> profileNames) {
        return [SELECT Id FROM Profile WHERE Name IN :profileNames];
    }

    private static User createUser(String email, Profile profileRecord) {
        return new User(
            Alias = 'jdoe',
            Email = email,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'Doe',
            LocaleSidKey = 'en_US',
            ProfileId = profileRecord.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = email + Datetime.now().getTime()
        );
    }

    @TestVisible
    private static User findGuestSiteUser() {
        List<User> guestUsers = [Select Username, UserType, Name, IsActive, Id From User where IsActive = true and UserType = 'Guest' and
        Name like '%Site Guest User%'];

        if (guestUsers.isEmpty()) {
            return null;
        }

        return guestUsers[0];
    }

    /////// Data ///////

    public static Map<SObjectType, Map<Id, SObject>> generateData() {
        sObjectByIdByType = new Map<SObjectType, Map<Id, SObject>>();
        DateTime now = System.now();

        Campaign campaignRecord = createCampaign('Spring Garden Party ' + now);
        insert campaignRecord;
        sObjectByIdByType.put(Campaign.SObjectType, new Map<Id, SObject>{ campaignRecord.Id => campaignRecord });

        Volunteer_Job__c volunteerJob = createJob('Classroom Helper ' + now, campaignRecord.Id);
        insert volunteerJob;
        sObjectByIdByType.put(Volunteer_Job__c.SObjectType, new Map<Id, SObject>{ volunteerJob.Id => volunteerJob });

        Account accountRecord = createAccount('TestAccount' + now);
        insert accountRecord;
        sObjectByIdByType.put(Account.SObjectType, new Map<Id, SObject>{ accountRecord.Id => accountRecord });

        Contact contactRecord = createContact('Helper ' + now);
        contactRecord.AccountId = accountRecord.Id;
        insert contactRecord;
        sObjectByIdByType.put(Contact.SObjectType, new Map<Id, SObject>{ contactRecord.Id => contactRecord });

        return sObjectByIdByType;
    }

    public static Map<SObjectType, Map<Id, SObject>> generateDataWithRecurrenceSchedules() {
        Contact contactRecord;
        Volunteer_Job__c jobRecord;
        generateData();

        contactRecord = (Contact) sObjectByIdByType.get(Contact.SObjectType).values()[0];
        jobRecord = (Volunteer_Job__c) sObjectByIdByType.get(Volunteer_Job__c.SObjectType).values()[0];

        Job_Recurrence_Schedule__c jrsRecord = createJobRecurrence(jobRecord.Id);
        insert jrsRecord;
        sObjectByIdByType.put(Job_Recurrence_Schedule__c.SObjectType, new Map<Id, SObject>{ jrsRecord.Id => jrsRecord });

        Volunteer_Recurrence_Schedule__c vrsRecord = createVolunteerRecurrence(contactRecord.Id, jobRecord.Id);
        insert vrsRecord;
        sObjectByIdByType.put(Volunteer_Recurrence_Schedule__c.SObjectType, new Map<Id, SObject>{ vrsRecord.Id => vrsRecord });

        return sObjectByIdByType;
    }

    public static Map<SObjectType, Map<Id, SObject>> generateDataWithShift() {
        generateData();
        Volunteer_Shift__c shift = createShift(getId(Volunteer_Job__c.SObjectType));
        insert shift;
        sObjectByIdByType.put(Volunteer_Shift__c.SObjectType, new Map<Id, SObject>{ shift.Id => shift });

        return sObjectByIdByType;
    }

    public static Id getId(SObjectType sObjType) {
        SObject sObj = getSObject(sObjType);

        return sObj == null ? null : (Id) sObj.get('Id');
    }

    public static SObject getSObject(SObjectType sObjType) {
        Map<Id, SObject> sObjectById = sObjectByIdByType.get(sObjType);

        return sObjectById == null ? null : sObjectById.values()[0];
    }

    public static Account createAccount(String name) {
        return new Account(Name = name);
    }

    public static Contact createContact() {
        return createContact('Testerton ' + Datetime.now().getTime());
    }

    public static Contact createContact(String lastName) {
        return new Contact(
            FirstName = 'Andy',
            LastName = lastName,
            Email = 'andy@test.com');
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
            Campaign__c = campaignId,
            Display_on_Website__c = true
        );
    }

    public static Volunteer_Hours__c createHours(Id contactId, Id jobId, Id shiftId) {
        return new Volunteer_Hours__c(
            Contact__c = contactId,
            Volunteer_Job__c = jobId,
            Volunteer_Shift__c = shiftId,
            Status__c = 'Web Sign Up',
            Start_Date__c = System.today(),
            End_Date__c = System.today(),
            Hours_Worked__c = 1,
            Number_of_Volunteers__c = 1
        );
    }

    public static Volunteer_Shift__c createShift(Id jobId) {
        return new Volunteer_Shift__c(
            Volunteer_Job__c = jobId,
            Duration__c = 1,
            Start_Date_Time__c = System.now()
        );
    }

    public static Job_Recurrence_Schedule__c createJobRecurrence(Id jobId){
        return new Job_Recurrence_Schedule__c(
            Volunteer_Job__c = jobId,
            Days_of_Week__c = 'Monday;Friday',
            Duration__c = 1.5,
            Schedule_Start_Date_Time__c = datetime.now(),
            Weekly_Occurrence__c = '1st');
    }

    public static Volunteer_Recurrence_Schedule__c createVolunteerRecurrence(Id contactId, Id jobid){
        return new Volunteer_Recurrence_Schedule__c(
            Contact__c = contactId,
            Volunteer_Job__c = jobId,
            Days_of_Week__c = 'Monday;Friday',
            Duration__c = 1.5,
            Schedule_Start_Date_Time__c = datetime.now(),
            Weekly_Occurrence__c = '1st');
    }

}