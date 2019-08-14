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
public without sharing class UTIL_UnitTest {
    /**
     * @description: The guest site user when found otherwise creates a default guest user
     */
    public static User guestUser {
        get {
            if (guestUser == null) {
                guestUser = findGuestSiteUser();
            }

            if (guestUser == null) {
                guestUser = createStandardGuestUser();
            }

            return guestUser;
        }
        private set;
    }

    public static User findGuestSiteUser() {
        List<User> guestUsers = [Select Username, UserType, Name, IsActive, Id From User where IsActive = true and UserType = 'Guest' and
        Name like '%Site Guest User%'];

        if (guestUsers.isEmpty()) {
            return null;
        }

        return guestUsers[0];
    }

    public static void elevateGuestUserAccess() {
        VOL_Access.getInstance().elevateGuestUserAccessSetting = true;
    }

    public static User createStandardGuestUser() {
        String email = 'guest' + '@testorg.com';

        return createUser(email, 'Standard Guest');
    }

    public static User createStandardUser() {
        String email = 'guest' + '@testorg.com';

        return createUser(email, 'Standard User');
    }

    public static User createAdminUser() {
        String email = 'admin' + '@testorg.com';

        return createUser(email, 'System Administrator');
    }

    public static User createUser(String email, String profileName) {
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name = :profileName];
        
        User userRecord =  new User(
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

        return userRecord;
    }
    
    public static Map<Id, SObject> generateDataForGuestUser(){
        Contact guestContact;
        Volunteer_Job__c guestJob;               	
        User guestUser = Util_UnitTest.guestUser;        
        
        Map<Id, SObject> sObjectById = generateData();
        
        for(SObject sObj : sObjectById.values()){
            if(sObj.getSObjectType() == Schema.Contact.getSObjectType()){
                guestContact = (Contact)sObj;
            }
            if(sObj.getSObjectType() == Schema.Volunteer_Job__c.getSObjectType()){
                guestJob = (Volunteer_Job__c)sObj;
            }
        }

        Job_Recurrence_Schedule__c jrsRecord = createJobRecurrence(guestJob.Id);
        insert jrsRecord;
        sObjectById.put(jrsRecord.Id, jrsRecord);
        
        Volunteer_Recurrence_Schedule__c vrsRecord = createVolunteerRecurrence(guestContact.Id, guestJob.Id);
        insert vrsRecord;
        sObjectById.put(vrsRecord.Id, vrsRecord);        

        return sObjectById;
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

        Account accountRecord = createAccount('TestAccount' + now);
        insert accountRecord;
        sObjectById.put(accountRecord.Id, accountRecord);
        
        Contact contactRecord = createContact('Helper ' + now);
        contactRecord.AccountId = accountRecord.Id;
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
            LastName = lastName,
            Email = 'andy@test.com');
    }

    public static Contact createContact() {
        return createContact('Testerton ' + Datetime.now().getTime());
    }
    
    public static Account createAccount(String name) {
        return new Account(Name=name);
    }

    public static Volunteer_Hours__c createHour(Id contactId, Id jobId, Id shiftId) {
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