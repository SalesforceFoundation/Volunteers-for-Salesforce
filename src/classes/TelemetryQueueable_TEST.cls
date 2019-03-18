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
private class TelemetryQueueable_TEST {
    private static TelemetryQueueable telemetryQueueable = new TelemetryQueueable();

    @IsTest
    private static void enqueueEnqueuesSelf() {
        Test.startTest();
        telemetryQueueable.enqueue(new List<Telemetry>());
        Test.stopTest();

        List<AsyncApexJob> asyncJobs = [SELECT Id FROM AsyncApexJob WHERE ApexClass.Name = 'TelemetryQueueable'];
        System.assertEquals(1, asyncJobs.size(), 'One job should be enqueued.');
    }

    @IsTest
    private static void executeSendsTelemetries() {
        Telemetry.Stub mockTelemetry = new Telemetry.Stub();
        telemetryQueueable.telemetries = new List<Telemetry>{
            (Telemetry) Test.createStub(Telemetry.class, mockTelemetry),
            (Telemetry) Test.createStub(Telemetry.class, mockTelemetry)
        };

        Test.startTest();
        telemetryQueueable.execute(null);
        Test.stopTest();

        System.assertEquals(telemetryQueueable.telemetries.size(), mockTelemetry.sendCount, 'Expected the send method to be called from telemetry.');
    }

}
