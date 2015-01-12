// Written by David Habib, copyright (c) 2010-2014 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@isTest
public with sharing class VOL_CTRL_VolunteersBulkEnterHours_TEST {
    
    //==================== TEST METHOD(s) ======================================
    public static testmethod void CodeCoverageTests() {
    
        // set up intial test data
        Account acc = new Account(name='Individual Test Account');
        insert acc;
        Contact con = new Contact(Lastname='Testy', AccountId=acc.Id);
        insert con;
        Campaign cmp = new Campaign(recordtypeid=VOL_SharedCode.recordtypeIdVolunteersCampaign, 
        	name='Test Campaign', IsActive=true);
        insert cmp;
        Volunteer_Job__c job = new Volunteer_Job__c(name='Job1', campaign__c=cmp.Id);
        insert job;
        Volunteer_Shift__c shift = new Volunteer_Shift__c(Volunteer_Job__c=job.Id, Duration__c=1, Start_Date_Time__c=System.now());
        insert shift;
        list<Volunteer_Hours__c> listHours = new list<Volunteer_Hours__c>();   
        integer cHours = 5;     
        for (integer i = 0; i < cHours; i++) {
            Volunteer_Hours__c hours = new Volunteer_Hours__c(
                Volunteer_Job__c=job.id, 
                Volunteer_Shift__c=shift.Id,
                Contact__c=con.Id,
                Number_of_Volunteers__c=3,
                Start_Date__c=System.today(), 
                Status__c='Confirmed'
                );
            listHours.add(hours);
        }                       
        insert listHours;
        
        //point to our VF page
        PageReference p = new PageReference('Page.VolunteersBulkEnterHours');
        p.getParameters().put('campaignId', cmp.id);
        p.getParameters().put('volunteerJobId', job.id);
        p.getParameters().put('volunteerShiftId', shift.id);
        Test.setCurrentPageReference(p);
        
        //instantiate the controller for this opp
        VOL_CTRL_VolunteersBulkEnterHours ctrl = new VOL_CTRL_VolunteersBulkEnterHours();
        System.AssertEquals(cmp.Id, ctrl.campaignId);
        System.AssertEquals(job.Id, ctrl.volunteerJobId);
        System.AssertEquals(shift.Id, ctrl.volunteerShiftId);
        System.Assert(ctrl.listSOCampaigns.size() > 1);
        System.AssertEquals(2, ctrl.listSOVolunteerJobs.size());
        System.AssertEquals(2, ctrl.listSOVolunteerShifts.size());
        System.AssertEquals(cHours + ctrl.cEmptyVolunteerHourRecords, ctrl.listVolunteerHours.size());
        
        ctrl.AddMoreEmptyRows();
        System.AssertEquals(cHours + (2 * ctrl.cEmptyVolunteerHourRecords), ctrl.listVolunteerHours.size());
        System.AssertEquals(true, ctrl.fHasListVolunteerHours);
        System.Assert(ctrl.Cancel() != null);
        System.AssertEquals(0, ctrl.numberOfRecordsDirty);
        System.AssertEquals(null, ctrl.strSaveResults); 

        ctrl.campaignId = null;
        ctrl.ChangeCampaign();
        System.AssertEquals(null, ctrl.volunteerJobId);
        System.AssertEquals(null, ctrl.volunteerShiftId);
        System.AssertEquals(null, ctrl.listVolunteerHours);
        
        ctrl.campaignId = cmp.Id;
        ctrl.ChangeCampaign();
        ctrl.volunteerJobId = job.Id;
        ctrl.ChangeVolunteerJob();
        System.AssertEquals(cHours + ctrl.cEmptyVolunteerHourRecords, ctrl.listVolunteerHours.size());
        ctrl.volunteerShiftId = shift.Id;
        ctrl.ChangeVolunteerShift();
        System.AssertEquals(cHours + ctrl.cEmptyVolunteerHourRecords, ctrl.listVolunteerHours.size());
        System.AssertEquals(0, ctrl.numberOfRecordsDirty);
        
        ctrl.listVolunteerHours.get(0).Hours_Worked__c = 2;
        p.getParameters().put('volunteerHoursIdDirtied', ctrl.listVolunteerHours.get(0).id);
        ctrl.VolunteerHoursRecordModified();
        System.AssertEquals(1, ctrl.setVolunteerHoursIdDirty.size());
        
        Volunteer_Hours__c vh = ctrl.listVolunteerHours.get(5);
        vh.Contact__c = con.id;
        vh.Volunteer_Job__c = job.id;
        vh.Volunteer_Shift__c = shift.id;
        vh.Status__c = 'Completed';
        vh.Start_Date__c = system.today();
        vh.Hours_Worked__c = null; // to test failure
        p.getParameters().put('volunteerHoursIdDirtied', null);
        ctrl.VolunteerHoursRecordModified();
        System.AssertEquals(1, ctrl.setVolunteerHoursIdDirty.size());
        System.AssertEquals(1, ctrl.numberOfRecordsDirty);

        // test the save!
        ctrl.SaveVolunteerHours();
        system.debug(ctrl.strSaveResults);
        System.Assert(ctrl.strSaveResults.startsWith('Error'));
        vh.Hours_Worked__c = 2.5;
        ctrl.SaveAndCloseVolunteerHours();      
        System.AssertEquals(0, ctrl.numberOfRecordsDirty);
        
    }

}