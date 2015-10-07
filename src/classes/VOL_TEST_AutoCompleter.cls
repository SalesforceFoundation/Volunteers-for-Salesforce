@isTest
public class TestAutoCompleter {
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';
 
    @testSetup public static void create_records() {
        Contact c = new Contact(FirstName='David',LastName='Habib');
        insert c;
        
        Campaign v = new Campaign(Name='Volunteering', IsActive=true);
        insert v;

        Volunteer_Job__c job1 = new Volunteer_Job__c(Name='Work', Campaign__c = v.Id);
        insert job1;
        
        Volunteer_Shift__c pastShift = new Volunteer_Shift__c(Start_Date_Time__c = DateTime.now().addDays(-10), Volunteer_Job__c = job1.Id, Duration__c = 2);
        Volunteer_Shift__c futureShift = new Volunteer_Shift__c(Start_Date_Time__c = DateTime.now().addDays(10), Volunteer_Job__c = job1.Id, Duration__c = 2);
        insert new List<Volunteer_Shift__c> {pastShift, futureShift};
        
        Date pastShiftStartDate = Date.newInstance(pastShift.Start_Date_Time__c.year(), pastShift.Start_Date_Time__c.month(), pastShift.Start_Date_Time__c.day());
        Date futureShiftStartDate = Date.newInstance(futureShift.Start_Date_Time__c.year(), futureShift.Start_Date_Time__c.month(), futureShift.Start_Date_Time__c.day());
        
        List<Volunteer_Hours__c> hoursToInsert = new List<Volunteer_Hours__c>();
        // this record sets a baseline of 20 completed hours
        hoursToInsert.add(new Volunteer_Hours__c(Contact__c = c.Id, Start_Date__c = pastShiftStartDate, Volunteer_Job__c = job1.Id, Status__c = 'Completed', Hours_Worked__c  = 20));

        // this record tests updates not overriding the Hours Worked
        hoursToInsert.add(new Volunteer_Hours__c(Contact__c = c.Id, Volunteer_Job__c = job1.Id, Start_Date__c = pastShiftStartDate, Volunteer_Shift__c = pastShift.Id, Status__c = 'Confirmed', Hours_Worked__c  = 3));

        // this record tests the hours sets to duration rule
        hoursToInsert.add(new Volunteer_Hours__c(Contact__c = c.Id, Volunteer_Job__c = job1.Id, Start_Date__c = pastShiftStartDate, Volunteer_Shift__c = pastShift.Id, Status__c = 'Confirmed'));
        hoursToInsert.add(new Volunteer_Hours__c(Contact__c = c.Id, Volunteer_Job__c = job1.Id, Start_Date__c = futureShiftStartDate, Volunteer_Shift__c = futureShift.Id, Status__c = 'Confirmed', Hours_Worked__c  = 2));
        insert hoursToInsert;
    }
    
    @isTest public static void test_batch() {
        Contact c = [Select Id, Volunteer_Hours__c FROM Contact LIMIT 1][0];
        System.assertEquals(20, c.Volunteer_Hours__c );
        Test.startTest();
        AutoCompleter batchable = new AutoCompleter();
        Id processId = Database.executeBatch(batchable); 
        Test.stopTest();
        c = [Select Id, Volunteer_Hours__c FROM Contact LIMIT 1][0];
        System.assertEquals(25, c.Volunteer_Hours__c );
    }
    
    @isTest public static void test_autocompletejob() {
        Test.startTest();
        Id jobId = System.schedule('ScheduleApexClassTest',
                       CRON_EXP, 
                       new AutoCompleter());

        Test.stopTest();
        CronTrigger job = [SELECT Id From CronTrigger WHERE Id =: jobId][0];
        // just asserting that the job exists and we didn't exception.
        System.assert(job.Id == jobId);
        // can't assert that the batch actually ran, because stopTest doesn't actually force it to run
        // see: http://salesforce.stackexchange.com/questions/36806/does-test-stoptest-ensure-a-system-schedule-database-batchable-completes-in-a
    }
}