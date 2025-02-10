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
public without sharing class Telemetry {
    public enum DeveloperName {
        CAMPAIGNS_WITH_JOBS,
        CONTACTS_WITH_LAST_WEB_SIGNUP,
        CONTACTS_WITH_LAST_WEB_SIGN_UP_LAST_YEAR,
        VOLUNTEER_JOBS,
        VOLUNTEER_JOBS_LAST_YEAR,
        VOLUNTEER_JOBS_DISPLAY_ON_WEBSITE,
        VOLUNTEER_SHIFTS,
        VOLUNTEER_SHIFTS_CREATED_LAST_YEAR,
        JOB_RECURRENCE_SCHEDULES,
        GRANT_GUEST_USERS_UPDATE_ACCESS
    }
    private static final String TELEMETRY_PARAM_ERROR =
        'The telemetry param type {0} is already in use, only one type can be sent at a time.';
    @TestVisible
    private SObjectType sObjType;
    @TestVisible
    private DeveloperName developerName;
    private String criteria;
    private Boolean booleanValue;

    @TestVisible
    private QueryBuilder queryBuilder {
        get {
            if (queryBuilder == null) {
                queryBuilder = new QueryBuilder(sObjType);
            }

            return queryBuilder;
        }
        set;
    }

    public Telemetry(SObjectType sObjType, DeveloperName developerName) {
        this.sObjType = sObjType;
        this.developerName = developerName;
    }

    public Telemetry(DeveloperName developerName) {
        this.developerName = developerName;
    }

    public Telemetry withCriteria(String criteria) {
        if (booleanValue != null) {
            throw new TelemetryException(String.format(TELEMETRY_PARAM_ERROR, new List<String>{ 'boolean' }));
        }

        this.criteria = criteria;
        return this;
    }

    public Telemetry withBooleanValue(Boolean booleanValue) {
        if (criteria != null) {
            throw new TelemetryException(String.format(TELEMETRY_PARAM_ERROR, new List<String>{ 'criteria' }));
        }

        this.booleanValue = booleanValue;
        return this;
    }

    public void send() {
        if (criteria != null) {
            send(getDeveloperName(), getCountQuery());
        } else if (booleanValue != null) {
            send(getDeveloperName(), booleanValue);
        }
    }

    @Future
    private static void send(String developerName, Boolean booleanValue) {
        try {
            FeatureManagement.setPackageBooleanValue(developerName, booleanValue);

        } catch (Exception ex) {
            throw new TelemetryException(System.Label.TelemetryException);
        }
    }

    @Future
    private static void send(String developerName, String query) {
        try {
            FeatureManagement.setPackageIntegerValue(developerName, Database.countQuery(query));

        } catch (Exception ex) {
            throw new TelemetryException(System.Label.TelemetryException);
        }
    }

    @TestVisible
    private String getCountQuery() {
        if (String.isNotBlank(criteria)) {
            queryBuilder.withCondition(criteria);
        }

        return queryBuilder.buildCount();
    }

    @TestVisible
    private String getDeveloperName() {
        if (developerName == null) {
            return '';
        }
        return developerName.name().remove('_');
    }

    public class TelemetryException extends Exception {}


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
        ) {
            switch on stubbedMethodName {
                when 'send' {
                    sendCount++;
                    return null;

                } when else {
                    return null;
                }
            }
        }
    }

}