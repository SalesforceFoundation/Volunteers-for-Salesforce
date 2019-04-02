/*
    Copyright (c) 2016, Salesforce.org
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
private class VOL_CTRL_VolunteersJobListingFS_TEST {
    private static Contact contactRecord;
    private static Campaign campaignRecord;
    private static Volunteer_Job__c job;
    private static Volunteer_Shift__c shift;
    private static PageReference pageRef = Page.VolunteersJobListingFS;
    private static VOL_CTRL_VolunteersJobListingFS ctrl;

    @TestSetup
    private static void makeData() {
        Account accountRecord = new Account(Name = 'Test Individual Bucket Account');
        insert accountRecord;

        contactRecord = new Contact(LastName = 'Testy', FirstName = 'Test', Email = 'test@testy.com', AccountId = accountRecord.Id);
        insert contactRecord;

        campaignRecord = new Campaign(RecordTypeId = VOL_SharedCode.recordtypeIdVolunteersCampaign, Name = 'Test Job Campaign', IsActive = true);
        insert campaignRecord;

        job = new Volunteer_Job__c(Name = 'Job1', campaign__c = campaignRecord.Id, Display_on_Website__c = true);
        insert job;

        shift = new Volunteer_Shift__c(Volunteer_Job__c = job.Id, Duration__c = 2, Start_Date_Time__c = System.now());
        insert shift;
    }


    /*******************************************************************************************************
    * @description test the visualforce page controller, running as the Sites Guest User, if such as user
    * exists.  if not, will run under the current user.
    * @return void
    ********************************************************************************************************/
    @IsTest
    private static void testPageWithSitesGuestUser() {
        List<User> users = [
            SELECT Username, UserType, Name, IsActive, Id
            FROM User
            WHERE IsActive = true AND UserType = 'Guest' AND Name LIKE '%Site Guest User%'
        ];

        if (users.isEmpty()) {
            unitTest1();
            return;
        }

        System.runAs(users[0]) {
            unitTest1();
        }
    }

    private static void unitTest1() {
        setSetupData();
        shouldLoadDefultPageParameters();
        shouldLoadAllJobsWhenFiltersAreNotPresent();
        shouldSignupExistingContact();
        shouldLoadJobsRelatedToCampaignIdFilter();
        shouldSignupNewContact();
        shouldUpdateExistingHour();
        shouldNotCreateContactWithoutPermissions();
    }

    private static void setSetupData() {
        Volunteers_Settings__c settings = new Volunteers_Settings__c();
        settings.Signup_Bucket_Account_On_Create__c = 'Test Individual Bucket Account';
        VOL_SharedCode.getVolunteersSettingsForTests(settings);

        contactRecord = [SELECT Id, FirstName, LastName, Email FROM Contact ORDER BY Id LIMIT 1];
        campaignRecord = [SELECT Id FROM Campaign ORDER BY Id LIMIT 1];
        job = [SELECT Id FROM Volunteer_Job__c ORDER BY Id LIMIT 1];
        shift = [SELECT Id, Duration__c, Volunteer_Shift__c.Volunteer_Job__c FROM Volunteer_Shift__c ORDER BY Id LIMIT 1];

        Test.setCurrentPage(pageRef);
        ctrl = new VOL_CTRL_VolunteersJobListingFS();
    }

    private static void shouldLoadDefultPageParameters() {
        System.assertEquals(null, ctrl.campaignIdFilter, 'Did not expect the campaignIdFilter param to be populated.');
        System.assertEquals(null, ctrl.jobIdFilter, 'Did not expect the jobIdFilter param to be populated.');
        System.assertEquals(true, ctrl.ShowJobName, 'Expected ShowJobName to be set to the default true value.');
        System.assertEquals(true, ctrl.ShowDescription, 'Expected ShowDescription to be set to the default true value.');
        System.assertEquals(true, ctrl.ShowLocationAddress, 'Expected ShowLocationAddress to be set to the default true value.');
        System.assertEquals(true, ctrl.ShowLocationInfo, 'Expected ShowLocationInfo to be set to the default true value.');
        System.assertEquals(true, ctrl.ShowShifts, 'Expected ShowShifts to be set to the default true value.');
        System.assertEquals(false, ctrl.ShowSkills, 'Expected ShowSkills to be set to the default false value.');
        System.assertEquals(null, ctrl.contact.Id, 'Expected the contact Id to be set to the default null value.');
        System.assertEquals(null, ctrl.jobIdSignUp, 'Expected jobIdSignUp to be set to the default null value.');
        System.assertEquals(null, ctrl.shiftIdSignUp, 'Expected shiftIdSignUp to be set to the default null value.');
        System.assertEquals(1, ctrl.vhours.Number_of_Volunteers__c, 'Expected the volunteer hours to be set to the default value of 1.');
        System.assertEquals(null, ctrl.strJobDisplayName, 'Expected strJobDisplayName to be set to the default null value.');
        System.assertEquals(null, ctrl.strShiftDisplayName, 'Expected strShiftDisplayName to be set to the default null value.');
        System.assertEquals(null, ctrl.contactIdSignUp, 'Expected contactIdSignUp to be set to the default null value.');
        System.assertEquals(null, ctrl.volunteerHoursIdSignUp, 'Expected volunteerHoursIdSignUp to be set to the default null value.');
        System.assert(ctrl.strURLtoCSSFile == ctrl.strURLtoCSSFile, 'Expected the strURLtoCSSFile to be set to the default null value when not on a personal site page.');
    }

    private static void shouldLoadAllJobsWhenFiltersAreNotPresent() {
        System.assertEquals(1, ctrl.listVolunteerJobs.size(), 'Expected all jobs to be found when a filter Id is not provided.');
        Volunteer_Job__c job2 = new Volunteer_Job__c(Name = 'Job2', Campaign__c = campaignRecord.Id, Display_on_Website__c = true);
        insert job2;

        ctrl.listVolunteerJobs = null;
        System.assertEquals(2, ctrl.listVolunteerJobs.size(), 'Expected all jobs to be found when a filter Id is not provided.');
    }

    private static void shouldSignupExistingContact() {
        ctrl.ClearVolunteerHoursIdSignUp();
        // sign someone up
        System.assertEquals(null, ctrl.contact.Id, 'Still expected the Id to be null.');
        System.assertEquals(null, ctrl.volunteerHoursIdSignUp, 'Still expected the volunteer hours Id to be null.');
        ctrl.contact.FirstName = contactRecord.FirstName;
        ctrl.contact.LastName = contactRecord.LastName;
        ctrl.contact.Email = contactRecord.Email;
        ctrl.contact.MailingState = 'WA';
        ctrl.jobIdSignUp = job.Id;
        ctrl.shiftIdSignUp = shift.Id;
        ctrl.VolunteerShiftSignUp();
        System.assertEquals(contactRecord.Id, ctrl.contactIdSignUp, 'Expected the matching contact record to be found and set.');
        System.assert(ctrl.volunteerHoursIdSignUp != null, 'Expected the volunteer hour record to be created.');
        Volunteer_Hours__c volunteerHour = [
            SELECT Volunteer_Job__c, Volunteer_Shift__c, Hours_Worked__c, Contact__c
            FROM Volunteer_Hours__c
            WHERE Volunteer_Job__c = :job.Id];
        System.assertEquals(shift.Duration__c, volunteerHour.Hours_Worked__c, 'Expected the hours worked to default to the duration of the shift.');
    }

    private static void shouldLoadJobsRelatedToCampaignIdFilter() {
        // pass campaignRecord.Id as filter, verify only 2 jobs.
        // pass Show params with 0, verify values.
        pageRef = Page.VolunteersJobListingFS;
        pageRef.getParameters().put('ShowJobName', '0');
        pageRef.getParameters().put('ShowDescription', '0');
        pageRef.getParameters().put('ShowLocationAddress', '0');
        pageRef.getParameters().put('ShowLocationInfo', '0');
        pageRef.getParameters().put('ShowShifts', '0');
        pageRef.getParameters().put('campaignId', campaignRecord.Id);
        pageRef.getParameters().put('ShowSkills', '1');
        Test.setCurrentPage(pageRef);

        //instantiate the controller
        ctrl = new VOL_CTRL_VolunteersJobListingFS();
        System.assertEquals(2, ctrl.listVolunteerJobs.size(), 'Expected both jobs related to the campaign to be returned.');
        System.assertEquals(campaignRecord.Id, ctrl.campaignIdFilter, 'Expected the passed in campaign Id record to be set.');
    }

    private static void shouldSignupNewContact() {
        // create hours for new person, verify contact created
        ctrl.ClearVolunteerHoursIdSignUp();
        ctrl.contact.FirstName = 'New person';
        ctrl.contact.LastName = 'New person for my test';
        ctrl.contact.Email = 'newperson@volunteersjoblisting.com';
        ctrl.contact.MailingState = 'OR';
        ctrl.jobIdSignUp = job.Id;
        ctrl.shiftIdSignUp = shift.Id;
        ctrl.VolunteerShiftSignUp();
        System.assert(ctrl.contactIdSignUp != null, 'Expected a new contact to be created.');
        System.assert(ctrl.volunteerHoursIdSignUp != null, 'Expected the volunteer hour record to be created.');
    }

    private static void shouldUpdateExistingHour() {
        Id hoursId = ctrl.volunteerHoursIdSignUp;
        System.assertEquals(1, ctrl.vhours.Number_Of_Volunteers__c, 'Expected the number of volunteers to be set to the default value of 1.');
        ctrl.vhours.Number_Of_Volunteers__c = 2;
        ctrl.ClearVolunteerHoursIdSignUp();
        ctrl.VolunteerShiftSignUp();
        System.assert(ctrl.contactIdSignUp != null, 'Expected the contact Id value to be set.');
        System.assert(ctrl.volunteerHoursIdSignUp != null, 'Expected the volunteer hour record to be set.');
        System.assertEquals(hoursId, ctrl.volunteerHoursIdSignUp, 'Expected the volunteerHoursIdSignUp to remain unchanged.');
        Volunteer_Hours__c volunteerHour = [SELECT Number_Of_Volunteers__c FROM Volunteer_Hours__c WHERE Id = :hoursId];
        System.assertEquals(2, volunteerHour.Number_Of_Volunteers__c, 'Expected the number of volunteers to have increased by 1 on the existing volunteer hour record.');
    }

    private static void shouldNotCreateContactWithoutPermissions() {
        Integer contactCount = [SELECT COUNT() FROM CONTACT];
        UTIL_Describe.throwException = true;
        ctrl.ClearVolunteerHoursIdSignUp();
        ctrl.contact.FirstName = 'New person2';
        ctrl.contact.LastName = 'New person2 for my test';
        ctrl.contact.Email = 'newperson2@volunteersjoblisting.com';
        ctrl.jobIdSignUp = job.Id;
        ctrl.VolunteerShiftSignUp();
        System.assertEquals(null, ctrl.contactIdSignUp, 'Did not expect a contact to be created without permissions.');
        System.assertEquals(null, ctrl.volunteerHoursIdSignUp, 'Did not expect a volunteer hour to be created without permissions.');
        System.assertEquals(contactCount, [SELECT COUNT() FROM CONTACT], 'Did not expect a new contact to be inserted without permissions.');
    }

    @IsTest
    private static void returnsCombinedJobWithShifts() {
        setSetupData();
        List<Volunteer_Job__c> combinedJobs = ctrl.combine(new List<Volunteer_Job__c>{ job }, new List<Volunteer_Shift__c>{ shift });
        List<Volunteer_Job__c> queriedJobs = new List<Volunteer_Job__c>([SELECT Id, (SELECT Id FROM Volunteer_Job_Slots__r) FROM Volunteer_Job__c]);

        System.assertEquals(queriedJobs[0].Volunteer_Job_Slots__r.size(), combinedJobs[0].Volunteer_Job_Slots__r.size(), 'Expected the number of shifts to be the same.');
        System.assertEquals(queriedJobs[0].Volunteer_Job_Slots__r[0].Id, combinedJobs[0].Volunteer_Job_Slots__r[0].Id, 'Expected the Id for the shifts to be the same.');
    }

    @IsTest
    private static void testCampaignHierarchies() {

        //create our test data
        Map<String, Campaign> campaignByHierarchy = VOL_SharedCode_TEST.mapCampaignTestHierarchy();
        Id grandparentId = campaignByHierarchy.get('Grandparent').Id;
        System.assertNotEquals(null, grandparentId, 'Expected a campaign to be found at the grandparent hierarchy level.');

        // verify w/ no hierarchy
        pageRef.getParameters().put('campaignId', grandparentId);
        Test.setCurrentPage(pageRef);
        ctrl = new VOL_CTRL_VolunteersJobListingFS();
        System.assertEquals(1, ctrl.listVolunteerJobs.size(), 'Expected only the job related to the grandparent campaign to be found.');

        // verify w/ hierarchy
        PageReference pageRef2 = Page.VolunteersJobListingFS;
        pageRef2.getParameters().put('campaignId', grandparentId);
        pageRef2.getParameters().put('ShowCampaignHierarchy', '1');
        Test.setCurrentPage(pageRef2);
        VOL_CTRL_VolunteersJobListingFS ctrl2 = new VOL_CTRL_VolunteersJobListingFS();
        System.assertEquals(campaignByHierarchy.size(), ctrl2.listVolunteerJobs.size(), 'Expected jobs related to all campaigns in the campaign to be found.');
    }

    /*******************************************************************************************************
    * @description test timezone handling for Shifts under LA timezone
    * @return void
    */
    @IsTest
    private static void testTimeZoneHandlingFromLA() {
        testTimeZoneHandling('America/Los_Angeles');
    }

    /*******************************************************************************************************
    * @description test timezone handling for Shifts under Sydney timezone
    * @return void
    */
    @IsTest
    private static void testTimeZoneHandlingFromSydney() {
        testTimeZoneHandling('Australia/Sydney');
    }

    /*******************************************************************************************************
    * @description test timezone handling for Shifts
    * @param timezone what timezone to run under while creating and querying shifts
    * @return void
    */
    private static void testTimeZoneHandling(String timeZone) {

        String uniqueUserName = 'admin' + DateTime.now().getTime() + '@testorg.com';
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User adminUser = new User(
            Alias = 'admin',
            Email='admin@testorg.com',
            EmailEncodingKey='UTF-8',
            LastName='Testing',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = timeZone,
            UserName = uniqueUserName
        );

        System.runAs(adminUser) {
            VOL_SharedCode_TEST.setupTimeZoneTestData();

            PageReference pageRef = Page.VolunteersJobListingFS;
            Test.setCurrentPage(pageRef);

            //instantiate the controller
            VOL_CTRL_VolunteersJobListingFS ctrl = new VOL_CTRL_VolunteersJobListingFS();
            System.assertEquals(2, ctrl.listVolunteerJobs.size(), 'Expected the timezone job and test setup jobs to be returned, timezone first since the first shift is today -1.');
            job = ctrl.listVolunteerJobs[0];
            System.assertEquals(48, job.Volunteer_Job_Slots__r.size(), 'We should always get today and tomorrow shifts.');
        }
    }

}