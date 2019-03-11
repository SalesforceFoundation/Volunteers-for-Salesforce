
@IsTest
public with sharing class InstallScript_TEST {
    @IsTest
    private static void shouldInsertPackageSettingsWhenNull() {
        InstallScript installScript = new InstallScript();
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
        InstallScript installScript = new InstallScript();
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
    private static void shouldInsertPackageSettingsOnInstall() {
        InstallScript installScript = new InstallScript();

        Integer startingDmlRows = System.Limits.getDmlRows();
        Test.testInstall(installScript, null);
        Integer endingDmlRows = System.Limits.getDmlRows();

        assertInsertOfPackageSettings(endingDmlRows - startingDmlRows);
    }

    @IsTest
    private static void shouldInsertPackageSettingsOnUpdate() {
        InstallScript installScript = new InstallScript();

        Integer startingDmlRows = System.Limits.getDmlRows();
        Test.testInstall(installScript, new Version(1,0));
        Integer endingDmlRows = System.Limits.getDmlRows();

        assertInsertOfPackageSettings(endingDmlRows - startingDmlRows);
    }

    @IsTest
    private static void shouldInsertPackageSettingsOnPush() {
        InstallScript installScript = new InstallScript();

        Integer startingDmlRows = System.Limits.getDmlRows();
        Test.testInstall(installScript, new Version(1,0), true);
        Integer endingDmlRows = System.Limits.getDmlRows();

        assertInsertOfPackageSettings(endingDmlRows - startingDmlRows);
    }


    /// Helpers

    private static void assertInsertOfPackageSettings(Integer actualRows) {
        PackageSettings__c packageSettings = PackageSettings__c.getOrgDefaults();
        String expectedNamespace = VOL_SharedCode.getNamespace() == ''
            ? null :
            VOL_SharedCode.getNamespace();

        System.assertNotEquals(null, packageSettings.Id, 'Expected the package setting to have an Id.');
        System.assertEquals(expectedNamespace, packageSettings.NamespacePrefix__c, 'Expected the package namespace to be set.');
        System.assertEquals(1, actualRows, 'Expected the dml rows to increase by one.');
    }
}
