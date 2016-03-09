/*
    Copyright (c) 2010, 2016, David Habib, DJH Consulting, djhconsulting.com
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    1. Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
    2. Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
    3. Neither the name of the copyright holder nor the names of
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

@isTest
public with sharing class VOL_CTRL_VolunteersCampaignWizard_TEST {

    /*******************************************************************************************************
    * TEST METHODS
    ********************************************************************************************************/
    static testmethod void CodeCoverageTests() {
        PageReference pageRef=Page.VolunteersCampaignWizard; 
        Test.setCurrentPage(pageRef); 
        
        // scenario 1: create a CustomCampaign__c with no cloning or samples.
        VOL_CTRL_VolunteersCampaignWizard ctrl = new VOL_CTRL_VolunteersCampaignWizard();
        ctrl.cmpVols.Name = 'My Test Volunteer CustomCampaign__c';
        ctrl.cmpVols.Start_Date__c = System.today();
        ctrl.cmpVols.IsActive__c = true;
        ctrl.CampaignIdClone = null;
        ctrl.cSampleJobs = 0;
        ctrl.cSampleShifts = 0;
        Integer cVolCampaigns = ctrl.listSOVolunteersCampaigns.size();
        System.Assert(ctrl.Save() != null);
        VOL_SharedCode volSharedCode = new VOL_SharedCode();        
        //System.AssertEquals(cVolCustomCampaign__cs + 1, volSharedCode.listSOCustomCampaign__csWithJobs.size());

        // scenario 2: create a CustomCampaign__c with sample jobs and shifts.
        ctrl = new VOL_CTRL_VolunteersCampaignWizard();
        ctrl.cmpVols.Name = 'My Test Volunteer CustomCampaign__c 2';
        ctrl.cmpVols.Start_Date__c = System.today().addYears(-1);
        ctrl.cmpVols.IsActive__c = true;
        ctrl.CampaignIdClone = null;
        ctrl.cSampleJobs = 2;
        ctrl.cSampleShifts = 3;
        System.Assert(ctrl.Save() != null);
        //System.AssertEquals(cVolCustomCampaign__cs + 2, volSharedCode.listSOCustomCampaign__csWithJobs.size());
        //CustomCampaign__c cmp2 = [select Id, Volunteer_Jobs__c, Volunteer_Shifts__c, Start_Date__c from CustomCampaign__c where Name = 'My Test Volunteer CustomCampaign__c 2'];
        CustomCampaign__c cmp2 = [select Id, Start_Date__c from CustomCampaign__c where Name = 'My Test Volunteer CustomCampaign__c 2'];
        system.assertEquals(System.today().addYears(-1), cmp2.Start_Date__c);
        //System.AssertEquals(ctrl.cSampleJobs, cmp2.Volunteer_Jobs__c);
        //System.AssertEquals(ctrl.cSampleShifts * ctrl.cSampleJobs, cmp2.Volunteer_Shifts__c);        
        list<Volunteer_Shift__c> listShift = [select Id, Name, Volunteer_Job__r.CustomCampaign__c, Start_Date_Time__c 
            from Volunteer_Shift__c where Volunteer_Job__r.CustomCampaign__c = :cmp2.Id];
        system.assertEquals(2 * 3, listShift.size()); 
        //system.assertEquals(cmp2.StartDate, listShift[0].Start_Date_Time__c.date());
        
        // now add some Hours to this CustomCampaign__c for our next test.
        Contact c1 = new Contact(Lastname='My Volunteer Contact');
        insert c1;
        Volunteer_Hours__c hours = new Volunteer_Hours__c(
            Contact__c = c1.Id,
            Volunteer_Job__c = listShift[0].Volunteer_Job__c,
            Volunteer_Shift__c = listShift[0].Id,
            Start_Date__c = listShift[0].Start_Date_Time__c.Date(),
            Planned_Start_Date_Time__c = listShift[0].Start_Date_Time__c,
            Status__c = 'Confirmed'         
            );
        insert hours;
        
        // scenario 3: create a CustomCampaign__c with a cloned set of Shifts and Jobs and Volunteer Hours
        ctrl = new VOL_CTRL_VolunteersCampaignWizard();
        ctrl.cmpVols.Name = 'My Test Volunteer CustomCampaign__c 3';
        ctrl.cmpVols.Start_Date__c = system.today();
        ctrl.cmpVols.IsActive__c = true;
        ctrl.CampaignIdClone = cmp2.Id;
        ctrl.ChangeCampaign();
        ctrl.cmpShiftDates.End_Date__c = system.today().addmonths(1);
        ctrl.fCopyVolunteers = true;
        ctrl.hoursStatus.status__c = 'Prospect';
        System.Assert(ctrl.Save() != null);
        //System.AssertEquals(cVolCustomCampaign__cs + 3, volSharedCode.listSOCustomCampaign__csWithJobs.size());
        CustomCampaign__c cmp3 = [select Id from CustomCampaign__c where Name = 'My Test Volunteer CustomCampaign__c 3'];
        //System.AssertEquals(cmp2.Volunteer_Jobs__c, cmp3.Volunteer_Jobs__c);
        //System.AssertEquals(cmp2.Volunteer_Shifts__c, cmp3.Volunteer_Shifts__c);
        Volunteer_Hours__c hours3 = [select Id, Start_Date__c, Volunteer_Job__c, Volunteer_Shift__c, Planned_Start_Date_Time__c,
            Status__c, Contact__c from Volunteer_Hours__c where Contact__c = :c1.id and Volunteer_Job__r.CustomCampaign__c = :cmp3.id];
        system.assertEquals('Prospect', hours3.Status__c);
        system.assertEquals(system.today().addmonths(1), hours3.Start_Date__c);
        system.assertEquals(system.today().addmonths(1), hours3.Planned_Start_Date_Time__c.Date());
        
        
        // scenario 4: test validation
        ctrl = new VOL_CTRL_VolunteersCampaignWizard();
        ctrl.cmpVols.Name = 'My Test Volunteer CustomCampaign__c 4';
        ctrl.cmpVols.Start_Date__c = null;
        ctrl.CampaignIdClone = cmp2.Id;
        ctrl.ChangeCampaign();
        ctrl.cSampleJobs = 2;
        ctrl.cSampleShifts = 3;
        System.Assert(ctrl.Save() == null);
        ctrl.CampaignIdClone = null;
        ctrl.cSampleJobs = 0;
        System.Assert(ctrl.Save() == null);
        
    }   
}