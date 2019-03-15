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
@IsTest (IsParallel=true)
public with sharing class TelemetryService_TEST {
    private static TelemetryService telemetryService = new TelemetryService();
    private static List<Telemetry.Stub> mockTelemetries = new List<Telemetry.Stub>();
    private static TelemetryParam.Stub mockParam = new TelemetryParam.Stub();
    private static final Integer TOTAL_TELEMETRIES = 9;

    @IsTest
    private static void enqueuesNumberOfJobsCorrespondingToTelemetryGroups() {
        final Integer groupSize = 3;
        telemetryService.groupedTelemetries = new List<List<Telemetry>>();

        for (Integer count = 0; count < groupSize; count++) {
            Telemetry.Stub mockTelemetry = createMockTelemetry();
            mockTelemetries.add(mockTelemetry);
            telemetryService.groupedTelemetries.add(
                new List<Telemetry>{ (Telemetry) Test.createStub(Telemetry.class, mockTelemetry) }
            );
        }

        Test.startTest();
        telemetryService.sendUsageMetrics();
        List<AsyncApexJob> asyncJobs = [SELECT Id FROM AsyncApexJob WHERE ApexClass.Name = 'TelemetryService'];
        Test.stopTest();

        System.assertEquals(groupSize, asyncJobs.size(), 'Expected a job to be enqueued for each group of telemetry lists.');
        for (Integer index; index < groupSize; index++) {
            System.assertEquals(1, mockTelemetries[index].sendCount, 'Expected each telemetry to be sent.');
        }
    }

    @IsTest
    private static void configReturnsTelemetryPerDeveloperName() {
        Integer actualTelemetries = 0;

        for (List<Telemetry> telemetries : telemetryService.groupedTelemetries) {
            actualTelemetries += telemetries.size();
        }
        System.assertEquals(TOTAL_TELEMETRIES, actualTelemetries, 'Expected the config to return the total number of telemetries.');
    }


    /// Helpers ///

    private static Telemetry.Stub createMockTelemetry() {
        return new Telemetry.Stub()
            .returnParam((TelemetryParam) Test.createStub(TelemetryParam.class, mockParam));
    }

}
