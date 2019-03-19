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
public without sharing class TelemetryService {
    @TestVisible
    private Config config {
        get {
            if (config == null) {
                config = new Config();
            }

            return config;
        }
        set;
    }

    @TestVisible
    private List<List<Telemetry>> groupedTelemetries {
        get {
            if (groupedTelemetries == null) {
                groupedTelemetries = config.getGroupedTelemetries();
            }

            return groupedTelemetries;
        }
        set;
    }

    @TestVisible
    private TelemetryQueueable telemetryQueueable {
        get {
            if (telemetryQueueable == null) {
                telemetryQueueable = new TelemetryQueueable();
            }

            return telemetryQueueable;
        }
        set;
    }

    public void sendUsageMetrics() {
        for (List<Telemetry> telemetries : groupedTelemetries) {
            telemetryQueueable.enqueue(telemetries);
        }
    }

    public with sharing class Config {
        public List<List<Telemetry>> getGroupedTelemetries() {
            List<List<Telemetry>> groupedTelemetries = new List<List<Telemetry>>();
            List<Telemetry> volunteerTelemetries = new List<Telemetry>();

            volunteerTelemetries.addAll(createVolunteerJobTelemetries());
            volunteerTelemetries.addAll(createVolunteerShiftTelemetries());
            volunteerTelemetries.addAll(createJobRecurrenceScheduleTelemetries());

            groupedTelemetries.add(volunteerTelemetries);
            groupedTelemetries.add(createCampaignTelemetries());
            groupedTelemetries.add(createContactTelemetries());

            return groupedTelemetries;
        }

        private List<Telemetry> createCampaignTelemetries() {
            return new List<Telemetry>{
                new Telemetry(Campaign.SObjectType, Telemetry.DeveloperName.CAMPAIGNS_WITH_JOBS)
                    .withCriteria('Id IN (SELECT Campaign__c FROM Volunteer_Jobs)')
            };
        }

        private List<Telemetry> createContactTelemetries() {
            return new List<Telemetry>{
                new Telemetry(Contact.SObjectType, Telemetry.DeveloperName.CONTACTS_WITH_LAST_WEB_SIGNUP)
                    .withCriteria('Volunteer_Last_Web_Signup_Date__c != null'),
                new Telemetry(Contact.SObjectType, Telemetry.DeveloperName.CONTACTS_WITH_LAST_WEB_SIGN_UP_LAST_YEAR)
                    .withCriteria('Volunteer_Last_Web_Signup_Date__c = LAST_YEAR')
            };
        }

        private List<Telemetry> createVolunteerJobTelemetries() {
            return new List<Telemetry>{
                new Telemetry(Volunteer_Job__c.SObjectType, Telemetry.DeveloperName.VOLUNTEER_JOBS),
                new Telemetry(Volunteer_Job__c.SObjectType, Telemetry.DeveloperName.VOLUNTEER_JOBS_LAST_YEAR)
                    .withCriteria('CreatedDate = LAST_YEAR'),
                new Telemetry(Volunteer_Job__c.SObjectType, Telemetry.DeveloperName.VOLUNTEER_JOBS_DISPLAY_ON_WEBSITE)
                    .withCriteria('Display_on_Website__c = true')
            };
        }

        private List<Telemetry> createVolunteerShiftTelemetries() {
            return new List<Telemetry>{
                new Telemetry(Volunteer_Shift__c.SObjectType, Telemetry.DeveloperName.VOLUNTEER_SHIFTS),
                new Telemetry(Volunteer_Shift__c.SObjectType, Telemetry.DeveloperName.VOLUNTEER_SHIFTS_CREATED_LAST_YEAR)
                    .withCriteria('CreatedDate = LAST_YEAR')
            };
        }

        private List<Telemetry> createJobRecurrenceScheduleTelemetries() {
            return new List<Telemetry>{
                new Telemetry(Job_Recurrence_Schedule__c.SObjectType, Telemetry.DeveloperName.JOB_RECURRENCE_SCHEDULES)
            };
        }
    }


    //////////////////// -------------------- ////////////////////

    public class Stub implements System.StubProvider {
        public Integer sendCount = 0;

        public Object handleMethodCall(
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs
        ){
            switch on stubbedMethodName {
                when 'sendUsageMetrics' {
                    sendCount++;
                    return null;

                } when else {
                    return null;
                }
            }
        }
    }

}
