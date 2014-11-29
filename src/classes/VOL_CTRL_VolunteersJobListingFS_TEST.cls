// Written by David Habib, copyright (c) 2010-2014 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@isTest
public with sharing class VOL_CTRL_VolunteersJobListingFS_TEST {

    //==================== TEST METHOD(s) ======================================
    public static testmethod void UnitTest1() {

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
    }

}