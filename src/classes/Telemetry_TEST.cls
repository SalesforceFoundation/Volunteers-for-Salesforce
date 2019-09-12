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
private class Telemetry_TEST {
    private static QueryBuilder.Stub mockQB = new QueryBuilder.Stub();
    private static Telemetry accountTelemetry;
    private static final Telemetry.DeveloperName DEV_NAME = Telemetry.DeveloperName.CAMPAIGNS_WITH_JOBS;
    private static final SObjectType SOBJECT_TYPE = Account.SObjectType;

    @IsTest
    private static void constructorSetsPropertiesWithSObjectTypeAndDevName() {
        accountTelemetry = new Telemetry(SOBJECT_TYPE, DEV_NAME);
        System.assertEquals(SOBJECT_TYPE, accountTelemetry.sObjType, 'Expected the sObject Type to be set.');
        System.assertEquals(DEV_NAME.name(), accountTelemetry.developerName.name(), 'Expected the developer name to be set.');
    }

    @IsTest
    private static void constructorSetsPropertiesWithDevName() {
        accountTelemetry = new Telemetry(DEV_NAME);
        System.assertEquals(DEV_NAME.name(), accountTelemetry.developerName.name(), 'Expected the developer name to be set.');
    }

    @IsTest
    private static void getDeveloperNameRemovesUnderscores() {
        accountTelemetry = new Telemetry(SOBJECT_TYPE, DEV_NAME);
        System.assert(!accountTelemetry.getDeveloperName().contains('_'), 'Did not expect the string to have any underscores.');
    }

    @IsTest
    private static void getDeveloperNameReturnsAnEmptyStringWhenNull() {
        accountTelemetry = new Telemetry(SOBJECT_TYPE, null);
        System.assertEquals('', accountTelemetry.getDeveloperName(), 'Expected an empty string to be returned when a null value is provided.');
    }

    @IsTest
    private static void getCountQueryReturnsValidQuery() {
        accountTelemetry = new Telemetry(SOBJECT_TYPE, DEV_NAME);
        System.assertEquals(0, Database.countQuery(accountTelemetry.getCountQuery()), 'Expected the query not to find any records.');

        insert new Account(Name = 'Count me!');
        System.assertEquals(1, Database.countQuery(accountTelemetry.getCountQuery()), 'Expected the query to find one record.');
    }

    @IsTest
    private static void getCountQueryReturnsValidQueryWithCriteria() {
        accountTelemetry = new Telemetry(SOBJECT_TYPE, DEV_NAME).withCriteria('Type = \'Prospect\'');
        System.assertEquals(0, Database.countQuery(accountTelemetry.getCountQuery()), 'Expected the query not to find any records.');

        insert new Account(Name = 'Count me!', Type = 'Prospect');
        insert new Account(Name = 'Do NOT Count me!', Type = 'Customer');
        System.assertEquals(1, Database.countQuery(accountTelemetry.getCountQuery()), 'Expected the query to find one record.');
    }

    @IsTest
    private static void recordCountPassesCriteriaToQueryBuilder() {
        String criteria = 'CreatedDate = NEXT_YEAR';
        accountTelemetry = new Telemetry(SOBJECT_TYPE, DEV_NAME).withCriteria(criteria);
        mockQB = mockQB.returnCountQuery('SELECT COUNT() FROM Account WHERE CreatedDate = NEXT_YEAR');
        accountTelemetry.queryBuilder = (QueryBuilder) Test.createStub(QueryBuilder.class, mockQB);
        Integer actualCount = Database.countQuery(accountTelemetry.getCountQuery());

        System.assertEquals(criteria, mockQB.condition, 'Expected the criteria to be sent to the query builder.');
        System.assertEquals(0, actualCount, 'Did not expect any records to have been created in the future!');
    }


}
