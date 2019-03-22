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

    //==================== TEST METHOD(s) ======================================


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

        if (!users.isEmpty()) {
            System.debug('Running test as Sites Guest User: ' + users[0]);
            System.runAs(users[0]) {
                unitTest1();
            }
        } else {
            System.debug('Running test as system.');
            unitTest1();
        }
    }

    private static void unitTest1() {

        // set up intial test data
        Account accountRecord = new Account(Name='Test Individual Bucket Account');
        insert accountRecord;
        Contact contactRecord = new Contact(LastName='Testy', FirstName='Test', Email='test@testy.com', AccountId = accountRecord.Id);
        insert contactRecord;
        Campaign campaignRecordId = new Campaign(RecordTypeId = VOL_SharedCode.recordtypeIdVolunteersCampaign, Name='Test Job Campaign', IsActive = true);
        insert campaignRecordId;
        Volunteer_Job__c job = new Volunteer_Job__c(Name='Job1', campaign__c = campaignRecordId.Id, Display_on_Website__c = true);
        insert job;
        Volunteer_Shift__c shift = new Volunteer_Shift__c(Volunteer_Job__c = job.Id, Duration__c = 2, Start_Date_Time__c = System.now());
        insert shift;

        // specify our settings
        System.assert(VOL_SharedCode.VolunteersSettings != null);
        Volunteers_Settings__c settings = new Volunteers_Settings__c();
        settings.Signup_Bucket_Account_On_Create__c = 'Test Individual Bucket Account';
        VOL_SharedCode.getVolunteersSettingsForTests(settings);

        PageReference pageRef = Page.VolunteersJobListingFS;
        pageRef.getParameters().put('ShowJobName', '1');
        pageRef.getParameters().put('ShowDescription', '1');
        pageRef.getParameters().put('ShowLocationAddress', '1');
        pageRef.getParameters().put('ShowLocationInfo', '1');
        pageRef.getParameters().put('ShowShifts', '1');
        pageRef.getParameters().put('ShowSkills', '1');
        Test.setCurrentPage(pageRef);

        //instantiate the controller
        VOL_CTRL_VolunteersJobListingFS ctrl = new VOL_CTRL_VolunteersJobListingFS();
        System.assertEquals(null, ctrl.campaignIdFilter);
        System.assertEquals(null, ctrl.jobIdFilter);
        System.assertEquals(true, ctrl.ShowJobName);
        System.assertEquals(true, ctrl.ShowDescription);
        System.assertEquals(true, ctrl.ShowLocationAddress);
        System.assertEquals(true, ctrl.ShowLocationInfo);
        System.assertEquals(true, ctrl.ShowShifts);
        System.assertEquals(true, ctrl.ShowSkills);
        System.assertEquals(null, ctrl.contact.Id);
        System.assertEquals(null, ctrl.jobIdSignUp);
        System.assertEquals(null, ctrl.shiftIdSignUp);
        System.assertEquals(1, ctrl.vhours.Number_of_Volunteers__c);
        System.assertEquals(null, ctrl.strJobDisplayName);
        System.assertEquals(null, ctrl.strShiftDisplayName);
        System.assertEquals(null, ctrl.contactIdSignUp);
        System.assertEquals(null, ctrl.volunteerHoursIdSignUp);
        System.assert(ctrl.strURLtoCSSFile == ctrl.strURLtoCSSFile);
        System.assert(ctrl.listVolunteerJobs.size() > 0);

        integer cJobs = ctrl.listVolunteerJobs.size();
        Volunteer_Job__c job2 = new Volunteer_Job__c(name='Job2', campaign__c=campaignRecordId.Id, Display_on_Website__c=true);
        insert job2;
        ctrl.listVolunteerJobs = null;
        System.assertEquals(cJobs + 1, ctrl.listVolunteerJobs.size());

        ctrl.ClearVolunteerHoursIdSignUp();

        // sign someone up
        System.assertEquals(null, ctrl.contact.Id);
        System.assertEquals(null, ctrl.volunteerHoursIdSignUp);
        ctrl.contact.FirstName = 'Test';
        ctrl.contact.LastName = 'Testy';
        ctrl.contact.Email = 'test@testy.com';
        ctrl.contact.MailingState='wa';
        ctrl.jobIdSignUp = job.id;
        ctrl.shiftIdSignUp = shift.id;
        ctrl.VolunteerShiftSignUp();
        System.assertEquals(contactRecord.Id, ctrl.contactIdSignUp);
        System.assert(ctrl.volunteerHoursIdSignUp != null);
        Volunteer_Hours__c vh = [select Volunteer_Job__c, Volunteer_Shift__c, Hours_Worked__c, Contact__c from Volunteer_Hours__c
            where Volunteer_Job__c = :job.Id];
        System.assertEquals(shift.Duration__c, vh.Hours_Worked__c);

        // pass campaignRecordId.Id as filter, verify only 2 jobs.
        // pass Show params with 0, verify values.
        pageRef = Page.VolunteersJobListingFS;
        pageRef.getParameters().put('ShowJobName', '0');
        pageRef.getParameters().put('ShowDescription', '0');
        pageRef.getParameters().put('ShowLocationAddress', '0');
        pageRef.getParameters().put('ShowLocationInfo', '0');
        pageRef.getParameters().put('ShowShifts', '0');
        pageRef.getParameters().put('ShowSkills', '0');
        pageRef.getParameters().put('campaignId', campaignRecordId.Id);
        Test.setCurrentPage(pageRef);

        //instantiate the controller
        ctrl = new VOL_CTRL_VolunteersJobListingFS();
        System.assertEquals(2, ctrl.listVolunteerJobs.size());
        System.assertEquals(campaignRecordId.Id, ctrl.campaignIdFilter);

        // create hours for new person, verify contact created
        ctrl.ClearVolunteerHoursIdSignUp();
        ctrl.contact.FirstName = 'New person';
        ctrl.contact.LastName = 'New person for my test';
        ctrl.contact.Email = 'newperson@volunteersjoblisting.com';
        ctrl.contact.MailingState = 'or';
        ctrl.jobIdSignUp = job.id;
        ctrl.shiftIdSignUp = shift.id;
        ctrl.VolunteerShiftSignUp();
        System.assert(ctrl.contactIdSignUp != null);
        System.assert(ctrl.volunteerHoursIdSignUp != null);

        // test shift reuse
        ID hoursId = ctrl.volunteerHoursIdSignUp;
        System.assertEquals(1, ctrl.vhours.Number_Of_Volunteers__c);
        ctrl.vhours.Number_Of_Volunteers__c = 2;
        ctrl.ClearVolunteerHoursIdSignUp();
        ctrl.VolunteerShiftSignUp();
        System.assert(ctrl.contactIdSignUp != null);
        System.assert(ctrl.volunteerHoursIdSignUp != null);
        System.assertEquals(hoursId, ctrl.volunteerHoursIdSignUp);
        vh = [select Number_Of_Volunteers__c from Volunteer_Hours__c where Id = :hoursId];
        System.assertEquals(2, vh.Number_Of_Volunteers__c);

        // test permissions checks
        Integer cContact = [SELECT COUNT() FROM CONTACT];
        UTIL_Describe.throwException = true;
        ctrl.ClearVolunteerHoursIdSignUp();
        ctrl.contact.FirstName = 'New person2';
        ctrl.contact.LastName = 'New person2 for my test';
        ctrl.contact.Email = 'newperson2@volunteersjoblisting.com';
        ctrl.jobIdSignUp = job.id;
        ctrl.VolunteerShiftSignUp();
        System.assertEquals(null, ctrl.contactIdSignUp);
        System.assertEquals(null, ctrl.volunteerHoursIdSignUp);
        System.assertEquals(cContact, [SELECT COUNT() FROM CONTACT]);

    }

    @IsTest
    private static void testCampaignHierarchies() {

        //create our test data
        map<string, Campaign> mapCmp = VOL_SharedCode_TEST.mapCampaignTestHierarchy();
        ID cmpIdGrandparent = mapCmp.get('Grandparent').Id;
        System.assertNotEquals(null, cmpIdGrandparent);

        // verify w/ no hierarchy
        PageReference pageRef = Page.VolunteersJobListingFS;
        pageRef.getParameters().put('campaignId', cmpIdGrandparent);
        Test.setCurrentPage(pageRef);
        VOL_CTRL_VolunteersJobListingFS ctrl = new VOL_CTRL_VolunteersJobListingFS();
        System.assertEquals(1, ctrl.listVolunteerJobs.size());

        // verify w/ hierarchy
        PageReference pageRef2 = Page.VolunteersJobListingFS;
        pageRef2.getParameters().put('campaignId', cmpIdGrandparent);
        pageRef2.getParameters().put('ShowCampaignHierarchy', '1');
        Test.setCurrentPage(pageRef2);
        VOL_CTRL_VolunteersJobListingFS ctrl2 = new VOL_CTRL_VolunteersJobListingFS();
        System.assertEquals(mapCmp.size(), ctrl2.listVolunteerJobs.size());
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
    private static void testTimeZoneHandling(String timezone) {

        String uniqueUserName = 'admin' + DateTime.now().getTime() + '@testorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(Alias = 'admin', Email='admin@testorg.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey=timezone,
            UserName=uniqueUserName);

        system.runAs(u) {
            VOL_SharedCode_TEST.setupTimeZoneTestData();

            PageReference pageRef = Page.VolunteersJobListingFS;
            Test.setCurrentPage(pageRef);

            //instantiate the controller
            VOL_CTRL_VolunteersJobListingFS ctrl = new VOL_CTRL_VolunteersJobListingFS();
            System.assertEquals(1, ctrl.listVolunteerJobs.size());
            Volunteer_Job__c job = ctrl.listVolunteerJobs[0];
            System.assertEquals(48, job.Volunteer_Job_Slots__r.size(), 'we should always get today and tomorrow shifts');
        }
    }

}