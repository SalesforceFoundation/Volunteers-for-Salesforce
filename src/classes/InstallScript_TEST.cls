
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

        packageSettings = PackageSettings__c.getOrgDefaults();
        System.assertNotEquals(null, packageSettings.Id, 'Expected the package setting to have an Id.');
        System.assertEquals(1, endingDmlRows - startingDmlRows, 'Expected the dml rows to increase by one.');
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
}
