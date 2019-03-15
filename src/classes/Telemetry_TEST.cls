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
    private static QueryBuilder.Stub mockQB = new QueryBuilder.Stub();
    private static Telemetry telemetry;
    private static final String DEV_NAME = 'DeveloperName';

    @IsTest
    private static void returnsDeveloperNameProvided() {
        telemetry = new Telemetry(Account.SObjectType, DEV_NAME);
        System.assertEquals(DEV_NAME, telemetry.getDeveloperName(), 'Expected the developer names to match.');
    }

    @IsTest
    private static void returnsEmptyStringWhenDeveloperNameNotProvided() {
        telemetry = new Telemetry(Account.SObjectType, null);
        System.assertEquals('', telemetry.getDeveloperName(), 'Expected the developer names to be an empty string.');
    }

    @IsTest
    private static void returnsIntegerValueOfRecordCount() {
        telemetry = new Telemetry(Account.SObjectType, DEV_NAME);
        System.assertEquals(0, (Integer) telemetry.getValue(), 'Did not expect any records to be found.');
        insert new Account(Name = 'Count me!');
        System.assertEquals(1, (Integer) telemetry.getValue(), 'Expected one record to be found.');
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


}
