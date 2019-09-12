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
private with sharing class VOL_CTRL_VolunteersJobListingFS_TEST {
    private static VOL_CTRL_VolunteersJobListingFS jobListingCtrl;
    private static VOL_Access_TEST.Stub accessMock = new VOL_Access_TEST.Stub();
    private static final Integer QUERY_LIMIT = VOL_CTRL_VolunteersJobListingFS.SUBQUERY_LIMIT;
    private static final Integer SUBQUERY_ERROR_THRESHOLD = 251; // causes query exception with test data at this number

    //==================== TEST METHOD(s) ======================================
    @IsTest
    private static void shouldCheckCreateAccessAndInsertHours() {
        setupPage(new Map<String, String>());
        setAccessMock();
        jobListingCtrl.contact = UTIL_UnitTest.createContact('Signup Insert ' + DateTime.now().getTime());

        jobListingCtrl.VolunteerShiftSignUp();
        // The contact creation is completed by a separate class, VOL_SharedCode
        accessMock.assertMethodCalled('checkCreateAccess', Volunteer_Hours__c.SObjectType);
        accessMock.assertMethodCalled('insertRecords', Volunteer_Hours__c.SObjectType);
    }

    @IsTest
    private static void shouldCheckCreateAccessAndInsertAttachment() {
        Contact existingContact = UTIL_UnitTest.createContact('Signup Update ' + DateTime.now().getTime());
        insert existingContact;

        setupPage(new Map<String, String>());
        setAccessMock();
        jobListingCtrl.contact = existingContact;
        jobListingCtrl.attachment = new Attachment(Body = Blob.valueOf('Signup attachment insert...'));

        jobListingCtrl.VolunteerShiftSignUp();
        accessMock.assertMethodCalled('checkCreateAccess', Attachment.SObjectType);
        accessMock.assertMethodCalled('checkCreateAccess', Volunteer_Hours__c.SObjectType);
        accessMock.assertMethodCalled('insertRecords', Attachment.SObjectType);
        accessMock.assertMethodCalled('insertRecords', Volunteer_Hours__c.SObjectType);
    }

    @IsTest
    private static void shouldCheckUpdateAccessAndUpdateHours() {
        generateData(1);
        

        Contact existingContact = UTIL_UnitTest.createContact('Signup Update ' + DateTime.now().getTime());
        insert existingContact;

        Id jobId = [SELECT Id FROM Volunteer_Job__c LIMIT 1].Id;
        Id shiftId = [SELECT Id FROM Volunteer_Shift__c Where Volunteer_Job__c = :jobId LIMIT 1].Id;
        Volunteer_Hours__c hours = new Volunteer_Hours__c(
            Contact__c = existingContact.Id,
            Volunteer_Job__c = jobId,
            Volunteer_Shift__c = shiftId,
            Status__c = 'Web Sign Up',
            Start_Date__c = System.today(),
            Hours_Worked__c = 1,
            Number_of_Volunteers__c = 1
        );
        insert hours;

        setupPage(new Map<String, String>());
        setAccessMock();
        jobListingCtrl.shiftIdSignUp = shiftId;
        jobListingCtrl.jobIdSignUp = jobId;
        jobListingCtrl.contact = existingContact;
        jobListingCtrl.vhours.Number_of_Volunteers__c = 2;

        jobListingCtrl.VolunteerShiftSignUp();
        accessMock.assertMethodCalled('checkUpdateAccess', Volunteer_Hours__c.SObjectType);
        accessMock.assertMethodCalled('updateRecords', Volunteer_Hours__c.SObjectType);
    }

    @IsTest
    private static void shouldReturnOneShiftWhenJobIdAndShiftIdAreProvidedWithZeroMonths() {
        generateData(10);
        Id jobId = [SELECT Id FROM Volunteer_Job__c LIMIT 1].Id;
        Id shiftId = [SELECT Id FROM Volunteer_Shift__c Where Volunteer_Job__c = :jobId LIMIT 1].Id;
        setupPage(new Map<String, String>{'jobId' => jobId, 'volunteerShiftId' => shiftId, 'nMonthsToShow' => '0'});

        System.assertEquals(jobId, jobListingCtrl.jobIdFilter, 'Expecting the job Id filter on the controller to match the parameter passed in.');
        System.assertEquals(shiftId, jobListingCtrl.shiftIdFilter, 'Expecting the shift Id filter on the controller to match the parameter passed in.');
        System.assertEquals(0, jobListingCtrl.nMonthsToShow, 'Expecting the nMonthsToShow on the controller to match the parameter passed in.');
        System.assertEquals(1, jobListingCtrl.listVolunteerJobs[0].Volunteer_Job_Slots__r.size(), 'The number of shifts returned was not as expected.');
    }

    @IsTest
    private static void shouldReturnAllShiftsWhenJobIdIsProvidedAndLessThanLimit() {
        generateData(10);
        Id jobId = [SELECT Id FROM Volunteer_Job__c LIMIT 1].Id;
        setupPage(new Map<String, String>{'jobId' => jobId});

        System.assertEquals(jobId, jobListingCtrl.jobIdFilter, 'Expecting the job Id filter on the controller to match the parameter passed in.');
        System.assertEquals(10, jobListingCtrl.listVolunteerJobs[0].Volunteer_Job_Slots__r.size(), 'The number of shifts returned was not as expected.');
    }

    @IsTest
    private static void shouldReturnAllShiftsWhenCampaignIdIsProvidedAndLessThanLimit() {
        generateData(10);
        Id campaignId = [SELECT Id FROM Campaign LIMIT 1].Id;
        setupPage(new Map<String, String>{'campaignId' => campaignId});

        System.assertEquals(campaignId, jobListingCtrl.campaignIdFilter, 'Expecting the campaign Id filter on the controller to match the parameter passed in.');
        System.assertEquals(10, jobListingCtrl.listVolunteerJobs[0].Volunteer_Job_Slots__r.size(), 'The number of shifts returned was not as expected.');
    }

    @IsTest
    private static void shouldReturnLimitedShiftsWhenIdFiltersAreNotProvided() {
        generateData(101);
        setupPage(new Map<String, String>());

        System.assertEquals(100, jobListingCtrl.listVolunteerJobs[0].Volunteer_Job_Slots__r.size(), 'The number of shifts returned was not as expected.');
    }

    @IsTest
    private static void shouldReturnLimitedShiftsWhenJobIdIsProvided() {
        generateData(SUBQUERY_ERROR_THRESHOLD);
        Id jobId = [SELECT Id FROM Volunteer_Job__c LIMIT 1].Id;
        setupPage(new Map<String, String>{'jobId' => jobId});

        System.assertEquals(jobId, jobListingCtrl.jobIdFilter, 'Expecting the job Id filter on the controller to match the parameter passed in.');
        System.assertEquals(QUERY_LIMIT, jobListingCtrl.listVolunteerJobs[0].Volunteer_Job_Slots__r.size(), 'The number of shifts returned was not as expected.');
    }

    @IsTest
    private static void shouldReturnLimitedShiftsWhenCampaignIdIsProvided() {
        generateData(SUBQUERY_ERROR_THRESHOLD);
        Id campaignId = [SELECT Id FROM Campaign LIMIT 1].Id;
        setupPage(new Map<String, String>{'campaignId' => campaignId});

        System.assertEquals(campaignId, jobListingCtrl.campaignIdFilter, 'Expecting the campaign Id filter on the controller to match the parameter passed in.');
        System.assertEquals(QUERY_LIMIT, jobListingCtrl.listVolunteerJobs[0].Volunteer_Job_Slots__r.size(), 'The number of shifts returned was not as expected.');
    }

    private static void setupPage(Map<String, String> params) {
        PageReference pageRef = Page.VolunteersJobListingFS;

        for (String param : params.keySet()) {
            pageRef.getParameters().put(param, params.get(param));
        }

        Test.setCurrentPage(pageRef);
        jobListingCtrl = new VOL_CTRL_VolunteersJobListingFS();
    }

    private static void generateData(Integer numberOfShifts) {
        Volunteers_Settings__c settings = new Volunteers_Settings__c();
        VOL_SharedCode.getVolunteersSettingsForTests(settings);

        String uniqueName = String.valueOf(System.now());
        String campaignName = 'Pet Adoption Event';

        Campaign campaignRecord = new Campaign(
        Name = campaignName + ' ' + uniqueName,
        IsActive = true);
        insert campaignRecord;

        Volunteer_Job__c job = new Volunteer_Job__c(
            Name =  campaignName + ' Job ' + uniqueName,
            Campaign__c = campaignRecord.Id,
            Display_on_Website__c = true
        );
        insert job;

        List<Volunteer_Shift__c> shifts = new List<Volunteer_Shift__c>();
        for (Integer counter = 0; counter < numberOfShifts; counter++) {
            shifts.add(new Volunteer_Shift__c(
                Volunteer_Job__c = job.Id,
                Desired_Number_of_Volunteers__c = 10,
                Duration__c = 2,
                Start_Date_Time__c = System.today().addDays(1)
            ));
        }
        insert shifts;
    }


    /*******************************************************************************************************
    * @description test the visualforce page controller, running as the Sites Guest User, if such as user
    * exists.  if not, will run under the current user.
    * @return void
    ********************************************************************************************************/
    @IsTest
    private static void testPageWithSitesGuestUser() {
        /** Without the ability to create sharing records in apex when owd sharing is public read/write or controlled by parent, we can no longer
         * run this test as the guest user and will only run it as the admin. Commenting out so that we can reinstate
         * if / when the ability to do so becomes available
         * list<User> listU = [Select Username, UserType, Name, IsActive, Id From User where IsActive = true and UserType = 'Guest' and
        Name like '%Site Guest User%'];
        if (listU.size() > 0) {
            UTIL_UnitTest.enableElevateGuestUserAccess();
            system.debug('Running test as Sites Guest User: ' + listU[0]);
            system.runAs(listU[0]) {
                UnitTest1();
            }
        } else {
        */
            system.debug('Running test as system.');
            UnitTest1();
        //}
    }

    private static void UnitTest1() {

        // set up intial test data
        Account acc = new Account(name='Test Individual Bucket Account');
        insert acc;
        Contact con = new Contact(Lastname='Testy', Firstname='Test', Email='test@testy.com', AccountId=acc.Id);
        insert con;
        Campaign cmp = new Campaign(recordtypeid=VOL_SharedCode.recordtypeIdVolunteersCampaign, name='Test Job Campaign', IsActive=true);
        insert cmp;
        Volunteer_Job__c job = new Volunteer_Job__c(name='Job1', campaign__c=cmp.Id, Display_on_Website__c=true);
        insert job;
        Volunteer_Shift__c shift = new Volunteer_Shift__c(Volunteer_Job__c=job.Id, Duration__c=2, Start_Date_Time__c=System.now());
        insert shift;        
        
        // specify our settings        
        System.Assert(VOL_SharedCode.VolunteersSettings != null);
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
        System.AssertEquals(null, ctrl.campaignIdFilter);
        System.AssertEquals(null, ctrl.jobIdFilter);
        System.AssertEquals(true, ctrl.ShowJobName);
        System.AssertEquals(true, ctrl.ShowDescription);
        System.AssertEquals(true, ctrl.ShowLocationAddress);
        System.AssertEquals(true, ctrl.ShowLocationInfo);
        System.AssertEquals(true, ctrl.ShowShifts);
        System.AssertEquals(true, ctrl.ShowSkills);
        System.AssertEquals(null, ctrl.contact.Id);
        System.AssertEquals(null, ctrl.jobIdSignUp);
        System.AssertEquals(null, ctrl.shiftIdSignUp);
        System.AssertEquals(1, ctrl.vhours.Number_of_Volunteers__c);
        System.AssertEquals(null, ctrl.strJobDisplayName);
        System.AssertEquals(null, ctrl.strShiftDisplayName);
        System.AssertEquals(null, ctrl.contactIdSignUp);
        System.AssertEquals(null, ctrl.volunteerHoursIdSignUp);
        System.Assert(ctrl.strURLtoCSSFile == ctrl.strURLtoCSSFile);
        System.Assert(ctrl.listVolunteerJobs.size() > 0);
        
        integer cJobs = ctrl.listVolunteerJobs.size();
        Volunteer_Job__c job2 = new Volunteer_Job__c(name='Job2', campaign__c=cmp.Id, Display_on_Website__c=true);
        insert job2;
        ctrl.listVolunteerJobs = null;
        System.AssertEquals(cJobs + 1, ctrl.listVolunteerJobs.size());

        ctrl.ClearVolunteerHoursIdSignUp();
        
        // sign someone up
        System.AssertEquals(null, ctrl.contact.Id);
        System.AssertEquals(null, ctrl.volunteerHoursIdSignUp);
        ctrl.contact.FirstName = 'Test';
        ctrl.contact.LastName = 'Testy';
        ctrl.contact.Email = 'test@testy.com';
		ctrl.contact.MailingState='wa';        
        ctrl.jobIdSignUp = job.id;
        ctrl.shiftIdSignUp = shift.id;     
        ctrl.VolunteerShiftSignUp();
        System.AssertEquals(con.Id, ctrl.contactIdSignUp);
        System.Assert(ctrl.volunteerHoursIdSignUp != null);
        Volunteer_Hours__c vh = [select Volunteer_Job__c, Volunteer_Shift__c, Hours_Worked__c, Contact__c from Volunteer_Hours__c 
        	where Volunteer_Job__c = :job.Id];
        system.assertEquals(shift.Duration__c, vh.Hours_Worked__c);
        
        // pass cmp.Id as filter, verify only 2 jobs.
        // pass Show params with 0, verify values.
        pageRef = Page.VolunteersJobListingFS;
        pageRef.getParameters().put('ShowJobName', '0');
        pageRef.getParameters().put('ShowDescription', '0');
        pageRef.getParameters().put('ShowLocationAddress', '0');
        pageRef.getParameters().put('ShowLocationInfo', '0');
        pageRef.getParameters().put('ShowShifts', '0');
        pageRef.getParameters().put('ShowSkills', '0');
        pageRef.getParameters().put('campaignId', cmp.Id);
        Test.setCurrentPage(pageRef); 

        //instantiate the controller 
        ctrl = new VOL_CTRL_VolunteersJobListingFS();
        System.AssertEquals(2, ctrl.listVolunteerJobs.size());
        System.AssertEquals(cmp.Id, ctrl.campaignIdFilter);
        
        // create hours for new person, verify contact created
        ctrl.ClearVolunteerHoursIdSignUp();
        ctrl.contact.FirstName = 'New person';
        ctrl.contact.LastName = 'New person for my test';
        ctrl.contact.Email = 'newperson@volunteersjoblisting.com';
        ctrl.contact.MailingState = 'or';
        ctrl.jobIdSignUp = job.id;
        ctrl.shiftIdSignUp = shift.id;
        ctrl.VolunteerShiftSignUp();
        System.Assert(ctrl.contactIdSignUp != null);
        System.Assert(ctrl.volunteerHoursIdSignUp != null);
        
        // test shift reuse
        ID hoursId = ctrl.volunteerHoursIdSignUp;
        System.AssertEquals(1, ctrl.vhours.Number_Of_Volunteers__c);
        ctrl.vhours.Number_Of_Volunteers__c = 2;        
        ctrl.ClearVolunteerHoursIdSignUp();
        ctrl.VolunteerShiftSignUp();
        System.Assert(ctrl.contactIdSignUp != null);
        System.Assert(ctrl.volunteerHoursIdSignUp != null);
        System.AssertEquals(hoursId, ctrl.volunteerHoursIdSignUp);
        vh = [select Number_Of_Volunteers__c from Volunteer_Hours__c where Id = :hoursId];
        System.AssertEquals(2, vh.Number_Of_Volunteers__c);

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

    public static testmethod void testCampaignHierarchies() {

		//create our test data
		map<string, Campaign> mapCmp = VOL_SharedCode_TEST.mapCampaignTestHierarchy();
		ID cmpIdGrandparent = mapCmp.get('Grandparent').Id;
		system.assertNotEquals(null, cmpIdGrandparent);
    
		// verify w/ no hierarchy
        PageReference pageRef = Page.VolunteersJobListingFS;
        pageRef.getParameters().put('campaignId', cmpIdGrandparent);
        Test.setCurrentPage(pageRef); 
        VOL_CTRL_VolunteersJobListingFS ctrl = new VOL_CTRL_VolunteersJobListingFS();
		system.assertEquals(1, ctrl.listVolunteerJobs.size()); 

		// verify w/ hierarchy
        PageReference pageRef2 = Page.VolunteersJobListingFS;
        pageRef2.getParameters().put('campaignId', cmpIdGrandparent);
        pageRef2.getParameters().put('ShowCampaignHierarchy', '1');
        Test.setCurrentPage(pageRef2); 
        VOL_CTRL_VolunteersJobListingFS ctrl2 = new VOL_CTRL_VolunteersJobListingFS();
		system.assertEquals(mapCmp.size(), ctrl2.listVolunteerJobs.size()); 
    }

    /*******************************************************************************************************
    * @description test timezone handling for Shifts under LA timezone
    * @return void
    */
    private static testMethod void testTimeZoneHandlingFromLA() {
        testTimeZoneHandling('America/Los_Angeles');
    }

    /*******************************************************************************************************
    * @description test timezone handling for Shifts under Sydney timezone
    * @return void
    */
    private static testMethod void testTimeZoneHandlingFromSydney() {
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
            System.AssertEquals(1, ctrl.listVolunteerJobs.size());
            Volunteer_Job__c job = ctrl.listVolunteerJobs[0];
            System.assertEquals(48, job.Volunteer_Job_Slots__r.size(), 'we should always get today and tomorrow shifts');
        }
    }

    private static void setAccessMock() {
        VOL_CTRL_VolunteersJobListingFS.access = (VOL_Access) Test.createStub(VOL_Access.class, accessMock);
    }

}