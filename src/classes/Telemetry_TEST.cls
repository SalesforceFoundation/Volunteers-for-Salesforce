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
@IsTest(IsParallel=true)
public with sharing class Telemetry_TEST {
    private static TelemetryParam.Stub mockParam = new TelemetryParam.Stub();
    private static QueryBuilder.Stub mockQB = new QueryBuilder.Stub();
    private static Telemetry telemetry;
    private static final String DEV_NAME = 'DeveloperName';

    @IsTest
    private static void paramSentWhenDeveloperNameAndSObjTypeProvided() {
        sendTelemetry(Account.SObjectType, DEV_NAME, '');
        System.assertEquals(1, mockParam.sendCount, 'Expected the send method to be called.');
    }

    @IsTest
    private static void paramNotSentWhenDeveloperNameIsNotProvided() {
        sendTelemetry(Account.SObjectType, '', '');
        System.assertEquals(0, mockParam.sendCount, 'Did not expect the send method to be called without a developer name.');
    }

    @IsTest
    private static void criteriaPassedToQueryBuilder() {
        String criteria = 'CreatedDate = NEXT_YEAR';
        telemetry = new Telemetry(Account.SObjectType, DEV_NAME, criteria);
        mockQB = mockQB.returnCountQuery('SELECT COUNT() FROM Account WHERE CreatedDate = NEXT_YEAR');
        telemetry.queryBuilder = (QueryBuilder) Test.createStub(QueryBuilder.class, mockQB);
        Integer actualCount = telemetry.getRecordCount();

        System.assertEquals(criteria, mockQB.criteria, 'Expected the criteria to be sent to the query builder.');
        System.assertEquals(0, actualCount, 'Did not expect any records to have been created in the future!');
    }

    @IsTest
    private static void paramCreatedWithDeveloperNameAndRecordCount() {
        telemetry = new Telemetry(Account.SObjectType, DEV_NAME);
        String actualParam = JSON.serialize(telemetry.param);
        String expectedParam = JSON.serialize(new TelemetryParam(DEV_NAME, 0));

        System.assertEquals(expectedParam, actualParam, 'Expected the telemetry to create the same param.');
    }


    /// Helpers ///

    private static void sendTelemetry(SObjectType sObjType, String developerName, String criteria) {
        telemetry = new Telemetry(sObjType, developerName, criteria);
        telemetry.param = (TelemetryParam) Test.createStub(TelemetryParam.class, mockParam);
        telemetry.send();
    }

}
