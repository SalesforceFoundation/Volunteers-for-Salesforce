// Create a Job with Shifts
String uniqueName = String.valueOf(System.now());
String defaultCampaignName = 'Pet Adoption Event';
Integer defaultNumberOfShifts = 250;

public static void generateData(String campaignName, Integer numberOfShifts) {
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
    for (Integer counter = 0; counter < (numberOfShifts / 10); counter++) {
        for (Integer additionalMonths = 0; additionalMonths < 10; additionalMonths++) {
            shifts.add(new Volunteer_Shift__c(
                Volunteer_Job__c = job.Id,
                Desired_Number_of_Volunteers__c = 10,
                Duration__c = 2,
                Start_Date_Time__c = System.now().addMonths(additionalMonths)
            ));
        }
    }
    insert shifts;
}

