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

@isTest
private with sharing class VOL_CTRL_PersonalSiteContactInfo_TEST {
    private static VOL_Access_TEST.Stub accessMock = new VOL_Access_TEST.Stub();
    
    //******************************************************************************************************
    // Test Code

    private static void setAccessMock() {
        VOL_CTRL_PersonalSiteContactInfo.access = (VOL_Access) Test.createStub(VOL_Access.class, accessMock);
    }    
    
    @IsTest
    private static void shouldCheckCreateAccessOnSave() {
        VOL_SharedCode_TEST.setAccessMock();
        setAccessMock();
        Util_UnitTest.generateDataWithRecurrenceSchedules();

        Contact contactRecord = [SELECT Id FROM Contact LIMIT 1];
        System.assertNotEquals(null, contactRecord);

        // setup page
        PageReference pageRef = Page.PersonalSiteContactInfo;
        pageRef.getParameters().put('contactId', contactRecord.Id);
        system.assertNotEquals(null, contactRecord.Id);   
        Test.setCurrentPage(pageRef); 

        VOL_CTRL_PersonalSiteContactInfo ctrl = new VOL_CTRL_PersonalSiteContactInfo();
        ctrl.contactEdit.LastName = 'ChangedLastName';
        ctrl.save();

        VOL_SharedCode_TEST.accessMock.assertMethodCalled('checkCreateAccess', Contact.SObjectType);
        accessMock.assertMethodCalled('updateRecords', Contact.SObjectType);
    }
    
    /*******************************************************************************************************
    * @description test the visualforce page controller, running as the Sites Guest User, if such as user
    * exists.  if not, will run under the current user.
    * @return void
    ********************************************************************************************************/
    private static testMethod void testPageFunctionality() {
        Util_UnitTest.generateDataWithRecurrenceSchedules();
        testPSC();
    }
    
    private static void testPSC() {
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        System.AssertNotEquals(null, contact);

        // setup page
        PageReference pageRef = Page.PersonalSiteContactInfo;
        pageRef.getParameters().put('contactId', contact.Id);
        system.assertNotEquals(null, contact.Id);   
        Test.setCurrentPage(pageRef); 

        //instantiate the controller 
        VOL_CTRL_PersonalSiteContactInfo ctrl = new VOL_CTRL_PersonalSiteContactInfo();
        System.AssertNotEquals(null, ctrl.listStrHoursFields);
        System.AssertNotEquals(null, ctrl.contactEdit);
        System.AssertNotEquals(null, ctrl.contactReadOnly);
        System.AssertNotEquals(null, ctrl.contactId);
        System.AssertNotEquals(null, ctrl.listCompletedVolunteerHours);
        System.AssertEquals(0, ctrl.listCompletedVolunteerHours.size());
        System.AssertNotEquals(null, ctrl.listUpcomingVolunteerHours);
        System.AssertNotEquals(0, ctrl.listUpcomingVolunteerHours.size());
        ctrl.showMoreRowsCompleted();
        ctrl.showMoreRowsUpcoming();
        
        // mark some hours completed
        list<Volunteer_Hours__c> listHours = [select Id, Status__c from Volunteer_Hours__c where Contact__c = :contact.Id];
        system.assertNotEquals(null, listHours);
        system.assert(listHours.size() > 2);
        listHours[0].Status__c = 'Completed';
        listHours[1].Status__c = 'Completed';
        update listHours;
        
        system.assertNotEquals(null, ctrl.getChartData());
        system.assertEquals('', ctrl.strRank); // null because we don't have enough other volunteers in test data.
        
        system.assertEquals(null, ctrl.Edit());
        system.assertEquals(null, ctrl.Cancel());
        
        ctrl.contactEdit.LastName = 'TestIsNowTesty';
        ctrl.save();
        Contact con = [select Id, LastName from Contact where Id = :ctrl.contactId];
        system.assertEquals('TestIsNowTesty', con.LastName);
        
        // CancelShift
        ctrl.hoursId = listHours[0].Id;
        ctrl.cancelShift();
        listHours = [select Id, Status__c from Volunteer_Hours__c where Contact__c = :contact.Id and Status__c = 'Canceled'];
        system.assertEquals(1, listHours.size());

        // hit constructors of PersonalSite wrappers on our other pages to ensure code coverage
        VOL_CTRL_PersonalSiteJobCalendar ctrlJC = new VOL_CTRL_PersonalSiteJobCalendar();
        system.assertNotEquals(null, ctrlJC);
        system.assertEquals('en-us', ctrlJC.strLanguage);
        VOL_CTRL_PersonalSiteJobListing ctrlJL = new VOL_CTRL_PersonalSiteJobListing();
        system.assertNotEquals(null, ctrlJL);
        system.assertEquals('en-us', ctrlJL.strLanguage);
        VOL_CTRL_PersonalSiteReportHours ctrlRH = new VOL_CTRL_PersonalSiteReportHours();
        system.assertNotEquals(null, ctrlRH);
        system.assertEquals('en-us', ctrlRH.strLanguage);

        // test permissions
        UTIL_Describe.throwException = true;
        ctrl.contactEdit.LastName = 'PermTest';
        ctrl.save();
        con = [select Id, LastName from Contact where Id = :ctrl.contactId];
        system.assertEquals('TestIsNowTesty', con.LastName);

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
            Id conId = VOL_SharedCode_TEST.setupTimeZoneTestData();

            // setup page
            PageReference pageRef = Page.PersonalSiteContactInfo;
            pageRef.getParameters().put('contactId', conId);
            Test.setCurrentPage(pageRef);

            //instantiate the controller
            VOL_CTRL_PersonalSiteContactInfo ctrl = new VOL_CTRL_PersonalSiteContactInfo();
            System.AssertEquals(conId, ctrl.contactId);
            ctrl.cRowsUpcoming = 100;
            System.AssertEquals(0, ctrl.listCompletedVolunteerHours.size());
            System.AssertEquals(48, ctrl.listUpcomingVolunteerHours.size(), 'we should always get back today and tomorrow shifts');
        }
    }

}