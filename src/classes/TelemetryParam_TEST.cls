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
@IsTest // (IsParallel=true) - Setting Feature Management Parameters results in an exception when ran in parallel
public with sharing class TelemetryParam_TEST {
    private static final String DEV_NAME = 'CampaignsWithJobs';

    @IsTest
    private static void exceptionNotThrownWhenValueIsAnInteger() {
        Integer countExceptions = 0;

        Test.startTest();
        try {
            new TelemetryParam(DEV_NAME, 1).send();
        } catch (Exception ex) {
            countExceptions++;
        }
        Test.stopTest();

        System.assertEquals(0, countExceptions, 'Did not expect an exception to be thrown.');
    }

    @IsTest
    private static void exceptionThrownWhenDeveloperNameIsInvalid() {
        Integer countExceptions = 0;
        List<String> developerNames = new List<String>{ null, '', 'Fake' };

        Test.startTest();
        for (String developerName : developerNames) {
            try {
                new TelemetryParam('FAKE', 1).send();
            } catch (Exception ex) {
                countExceptions++;
            }
        }
        Test.stopTest();

        System.assertEquals(developerNames.size(), countExceptions, 'Expected an exception to be thrown for each name.');
    }

    @IsTest
    private static void throwsExceptionWhenValueTypeIsNotSupported() {
        List<TelemetryParam> params = new List<TelemetryParam>{
            new TelemetryParam(DEV_NAME, true),
            new TelemetryParam(DEV_NAME, 'This is not the paramater you are looking for!'),
            new TelemetryParam(DEV_NAME, System.today()),
            new TelemetryParam(DEV_NAME, null)
        };
        Integer countExceptions = 0;

        Test.startTest();
        for (TelemetryParam param : params) {
            try {
                param.send();
            } catch (TelemetryParam.TelemetryParamException ex) {
                countExceptions++;
            }
        }
        Test.stopTest();

        System.assertEquals(params.size(), countExceptions, 'Expected all params to throw an error.');
    }

}
