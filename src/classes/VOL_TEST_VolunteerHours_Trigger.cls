// Written by David Habib, copyright (c) 2010-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@isTest
private class VOL_TEST_VolunteerHours_Trigger {

    static testMethod void myUnitTest() {
        Account acc = new Account(name='Individual Test Account');
        insert acc;
        Contact con = new Contact(Lastname='Testy', AccountId=acc.Id, Volunteer_Status__c='inactive');
        insert con;
        Campaign cmp = new Campaign(recordtypeid=VOL_SharedCode.recordtypeIdVolunteersCampaign, name='Test Campaign', IsActive=true);
        insert cmp;
        Volunteer_Job__c job = new Volunteer_Job__c(name='Job1', campaign__c=cmp.Id);
        insert job;
        Volunteer_Shift__c shift = new Volunteer_Shift__c(Volunteer_Job__c=job.Id, Duration__c=1, Start_Date_Time__c=System.now());
        insert shift;
        
        // test inserting new hours
        list<Volunteer_Hours__c> listHours = new list<Volunteer_Hours__c>();        
        for (integer i = 0; i < 10; i++) {
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
        shift = [select Id, Total_Volunteers__c  from Volunteer_Shift__c where Id = :shift.Id limit 1];
        system.AssertEquals(30, shift.Total_Volunteers__c );
        
        // test updating existing hours
        for (integer i = 0; i < 10; i++) {
            listHours.get(i).Number_of_Volunteers__c = 1;
        }
        update listHours;
        shift = [select Id, Total_Volunteers__c  from Volunteer_Shift__c where Id = :shift.Id limit 1];
        system.AssertEquals(10, shift.Total_Volunteers__c );
            
        // test deleting existing hours
        listHours.remove(1);
        listHours.remove(2);            
        listHours.remove(3);
        delete listHours;
        shift = [select Id, Total_Volunteers__c  from Volunteer_Shift__c where Id = :shift.Id limit 1];
        system.AssertEquals(3, shift.Total_Volunteers__c );
    
        // make sure our contact's volunteer status was made active
        Contact conT = [select Id, Volunteer_Status__c from Contact where Id = :con.Id];
        system.AssertEquals('Active', conT.Volunteer_Status__c);
        
    }
    
}