/*
    Copyright (c) 2019, Salesforce.org
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
public with sharing class FeatureManagementService {

    private Config config {
        get {
            if (config == null) {
                config = new Config();
            }

            return config;
        }
        set;
    }

    public void sendUsageMetrics() {
        for (List<FeatureTelemetry> telemetries : config.getGroupedTelemetries()) {
            System.enqueueJob(new Queueable(telemetries));
        }
    }

    public with sharing class Queueable implements System.Queueable {
        private List<FeatureTelemetry> telemetries;

        public Queueable(List<FeatureTelemetry> telemetries) {
            this.telemetries = telemetries;
        }

        public void execute(QueueableContext qc) {
            try {
                for (FeatureTelemetry telemetry : telemetries) {
                    telemetry.send();
                }

            } catch (Exception ex) {
                throw new FeatureManagementException(System.Label.TelemetryException);
            }
        }

    }

    public with sharing class Config {
        private final String campaignsWithJobs = 'CampaignsWithJobs';
        private final String contactsWithWebSignups = 'ContactsWithLastWebSignup';
        private final String contactsWithWebSignupsLastYear = 'ContactsWithLastWebSignUpLastYear';
        private final String volunteerJobs = 'VolunteerJobs';
        private final String volunteerJobsLastYear = 'VolunteerJobsLastYear';
        private final String volunteerJobsOnWebsite = 'VolunteerJobsDisplayOnWebsite';
        private final String volunteerShifts = 'VolunteerShifts';
        private final String volunteerShiftsLastYear = 'VolunteerShiftsCreatedLastYear';

        public List<List<FeatureTelemetry>> getGroupedTelemetries() {
            List<List<FeatureTelemetry>> groupedTelemetries = new List<List<FeatureTelemetry>>();
            List<FeatureTelemetry> volunteerTelemetries = new List<FeatureTelemetry>();

            volunteerTelemetries.addAll(createVolunteerJobTelemetries());
            volunteerTelemetries.addAll(createVolunteerShiftTelemetries());
            volunteerTelemetries.addAll(createJobRecurrenceScheduleTelemetries());

            groupedTelemetries.add(volunteerTelemetries);
            groupedTelemetries.add(createCampaignTelemetries());
            groupedTelemetries.add(createContactTelemetries());

            return groupedTelemetries;
        }

        private List<FeatureTelemetry> createCampaignTelemetries() {
            return new List<FeatureTelemetry>{
                new FeatureTelemetry(Campaign.SObjectType, campaignsWithJobs, 'Id IN (SELECT Campaign__c FROM Volunteer_Jobs)')
            };
        }

        private List<FeatureTelemetry> createContactTelemetries() {
            return new List<FeatureTelemetry>{
                new FeatureTelemetry(Contact.SObjectType, contactsWithWebSignups, 'Volunteer_Last_Web_Signup_Date__c != null'),
                new FeatureTelemetry(Contact.SObjectType, contactsWithWebSignupsLastYear, 'Volunteer_Last_Web_Signup_Date__c = LAST_YEAR')
            };
        }

        private List<FeatureTelemetry> createVolunteerJobTelemetries() {
            return new List<FeatureTelemetry>{
                new FeatureTelemetry(Volunteer_Job__c.SObjectType, volunteerJobs, ''),
                new FeatureTelemetry(Volunteer_Job__c.SObjectType, volunteerJobsLastYear, 'CreatedDate = LAST_YEAR'),
                new FeatureTelemetry(Volunteer_Job__c.SObjectType, volunteerJobsOnWebsite, 'Display_on_Website__c = true')
            };
        }

        private List<FeatureTelemetry> createVolunteerShiftTelemetries() {
            return new List<FeatureTelemetry>{
                new FeatureTelemetry(Volunteer_Shift__c.SObjectType, volunteerShifts, ''),
                new FeatureTelemetry(Volunteer_Shift__c.SObjectType, volunteerShiftsLastYear, 'CreatedDate = LAST_YEAR')
            };
        }

        private List<FeatureTelemetry> createJobRecurrenceScheduleTelemetries() {
            return new List<FeatureTelemetry>{
                new FeatureTelemetry(Job_Recurrence_Schedule__c.SObjectType, 'JobRecurrenceSchedules', '')
            };
        }
    }

    public class FeatureManagementException extends Exception {}

}
