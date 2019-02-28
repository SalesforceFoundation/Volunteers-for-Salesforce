public with sharing class FeatureManagementService {
    List<FeatureParam> recordCounts = new List<FeatureParam>{
        new FeatureParam('JobsAllTime').withRecordCount(Volunteer_Job__c.SObjectType, ''),
        new FeatureParam('JobsLastYear').withRecordCount(Volunteer_Job__c.SObjectType, 'CreatedDate = LAST_YEAR'),
        new FeatureParam('JobsThisYear').withRecordCount(Volunteer_Job__c.SObjectType, 'CreatedDate < THIS_YEAR')
    };

    List<FeatureParam> fieldCounts = new List<FeatureParam>{
        new FeatureParam('JobsCustomFields').withCustomFieldCount(Volunteer_Job__c.SObjectType),
        new FeatureParam('ShiftsCustomFields').withCustomFieldCount(Volunteer_Shift__c.SObjectType),
        new FeatureParam('HoursCustomFields').withCustomFieldCount(Volunteer_Hours__c.SObjectType)
    };

    public FeatureManagementService() {}

    public void updateRecordCounts() {
        for (FeatureParam recordCount : recordCounts) {
            recordCount.send();
        }

    }

    public void updateCustomFieldCounts() {
        for (FeatureParam fieldCount : fieldCounts) {
            fieldCount.send();
        }

    }
}
