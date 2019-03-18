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
private class InstallScript_TEST {
    private static TelemetryService.Stub mockTelemetryService = new TelemetryService.Stub();
    private static InstallScript installScript = new InstallScript();
    @IsTest
    private static void insertsPackageSettingsWhenNull() {
        PackageSettings__c packageSettings = PackageSettings__c.getOrgDefaults();
        System.assertEquals(null, packageSettings.Id, 'Expected the Id of the package setting to be null: ' + packageSettings.Id);

        Test.startTest();
        Integer startingDmlRows = System.Limits.getDmlRows();
        installScript.insertPackageSettings();
        Integer endingDmlRows = System.Limits.getDmlRows();
        Test.stopTest();

        assertInsertOfPackageSettings(endingDmlRows - startingDmlRows);
    }

    @IsTest
    private static void shouldNotInsertPackageSettingsWhenSettingsExists() {
        PackageSettings__c packageSettings = PackageSettings__c.getOrgDefaults();
        packageSettings.NamespacePrefix__c = VOL_SharedCode.getNamespace();
        insert packageSettings;

        Test.startTest();
        Integer startingDmlRows = System.Limits.getDmlRows();
        installScript.insertPackageSettings();
        Integer endingDmlRows = System.Limits.getDmlRows();
        Test.stopTest();

        System.assertEquals(0, endingDmlRows - startingDmlRows, 'Dml should not occur when the package already exists.');
    }

    @IsTest
    private static void insertsPackageSettingsOnInstall() {
        Integer startingDmlRows = System.Limits.getDmlRows();
        Test.testInstall(installScript, null);
        Integer endingDmlRows = System.Limits.getDmlRows();

        assertInsertOfPackageSettings(endingDmlRows - startingDmlRows);
    }

    @IsTest
    private static void insertsPackageSettingsOnUpdate() {
        setTelemetryServiceStub();

        Integer startingDmlRows = System.Limits.getDmlRows();
        Test.testInstall(installScript, new Version(1,0));
        Integer endingDmlRows = System.Limits.getDmlRows();

        assertInsertOfPackageSettings(endingDmlRows - startingDmlRows);
    }

    @IsTest
    private static void insertsPackageSettingsOnPush() {
        setTelemetryServiceStub();

        Integer startingDmlRows = System.Limits.getDmlRows();
        Test.testInstall(installScript, new Version(1,0), true);
        Integer endingDmlRows = System.Limits.getDmlRows();

        assertInsertOfPackageSettings(endingDmlRows - startingDmlRows);
    }

     @IsTest
    private static void shouldNotCallTelemetryServiceOnInstall() {
        Test.testInstall(installScript, null);

        System.assertEquals(0, mockTelemetryService.sendCount, 'Did not expect the sendMetricUsage method to be called from the Telemetry Service.');
    }

    @IsTest
    private static void callsTelemetryServiceOnUpdate() {
        setTelemetryServiceStub();
        Test.testInstall(installScript, new Version(1,0));

        System.assertEquals(1, mockTelemetryService.sendCount, 'Expected the sendMetricUsage method to be called from the Telemetry Service.');
    }

    @IsTest
    private static void callsTelemetryServiceOnPush() {
        setTelemetryServiceStub();
        Test.testInstall(installScript, new Version(1,0), true);

        System.assertEquals(1, mockTelemetryService.sendCount, 'Expected the sendMetricUsage method to be called from the Telemetry Service.');
    }


    /// Helpers

    private static void assertInsertOfPackageSettings(Integer actualRows) {
        PackageSettings__c packageSettings = PackageSettings__c.getOrgDefaults();
        String expectedNamespace = VOL_SharedCode.getNamespace() == ''
            ? null :
            VOL_SharedCode.StrTokenNSPrefix('');

        System.assertNotEquals(null, packageSettings.Id, 'Expected the package setting to have an Id.');
        System.assertEquals(expectedNamespace, packageSettings.NamespacePrefix__c, 'Expected the package namespace to be set.');
        System.assertEquals(1, actualRows, 'Expected the dml rows to increase by one.');
    }

    private static void setTelemetryServiceStub() {
        installScript.TelemetryService =
            (TelemetryService) Test.createStub(TelemetryService.class, mockTelemetryService);
    }
}
