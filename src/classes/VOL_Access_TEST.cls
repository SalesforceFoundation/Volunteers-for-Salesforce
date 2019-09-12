@IsTest
public with sharing class VOL_Access_TEST {
    private static DatabaseDml_TEST.Stub dmlMock = new DatabaseDml_TEST.Stub();
    private static Contact contactRecord = UTIL_UnitTest.createContact('Name ' + DateTime.now().getTime());
    private static List<Contact> contacts = new List<Contact>{ contactRecord };

    @IsTest
    private static void isGuestUserReturnsTrueForExistingGuestSiteUser() {
        User guestSiteUser = UTIL_UnitTest.findGuestSiteUser();
        if (guestSiteUser == null) {
            return; // bail if no guest site users are found
        }

        System.runAs(guestSiteUser) {
            System.assert(VOL_Access.getInstance().isGuestUser, 'Expected isGuestUser to be true for a guest site users.');
        }
    }

    @IsTest
    private static void isGuestUserReturnsTrueForStandardGuestUsers() {
        User standardGuest = UTIL_UnitTest.createGuestUser();

        System.runAs(standardGuest) {
            System.assert(VOL_Access.getInstance().isGuestUser, 'Expected isGuestUser to be true for a standard guest user.');
        }
    }

    @IsTest
    private static void isGuestUserReturnsFalseForStandardUser() {
        User standardUser = UTIL_UnitTest.createStandardUser();

        System.runAs(standardUser) {
            System.assert(!VOL_Access.getInstance().isGuestUser, 'Expected isGuestUser to be false for a standard users.');
        }
    }

    @IsTest
    private static void createAccessThrowsExceptionOnUpdateForGuestUserWithElevateSettingChecked() {
        VOL_Access.getInstance().elevateGuestUserAccessSetting = true;
        String actualException;

        System.runAs(UTIL_UnitTest.createGuestUser()) {
            try {
                VOL_Access.getInstance().checkUpdateAccess('Contact', new Set<String>{ 'LastName' });
            } catch (Exception ex) {
                actualException = ex.getMessage();
            }
        }
        System.assertEquals(String.format(Label.PermissionCreateException, new List<String>{ 'Contact.LastName' }), actualException, 'Expected the create permission exception to be thrown.');
    }

    @IsTest
    private static void updateAccessThrowsExceptionOnUpdateForGuestUserWithElevateSettingUnchecked() {
        VOL_Access.getInstance().elevateGuestUserAccessSetting = false;
        String actualException;

        System.runAs(UTIL_UnitTest.createGuestUser()) {
            try {
                VOL_Access.getInstance().checkUpdateAccess('Contact', new Set<String>{ 'LastName' });
            } catch (Exception ex) {
                actualException = ex.getMessage();
            }
        }

        System.assertEquals(String.format(Label.PermissionUpdateException, new List<String>{ 'Contact.LastName' }), actualException, 'Expected the update permission exception to be thrown.');
    }

    @IsTest
    private static void createAccessThrowsExceptionOnCreateForGuestUser() {
        List<String> actualExceptions = new List<String>();

        System.runAs(UTIL_UnitTest.createGuestUser()) {
            try {
                VOL_Access.getInstance().checkCreateAccess('Contact', new Set<String>{ 'LastName' });
            } catch (Exception ex) {
                actualExceptions.add(ex.getMessage());
            }

            VOL_Access.getInstance().elevateGuestUserAccessSetting = !VOL_Access.getInstance().elevateGuestUserAccessSetting;
            try {
                VOL_Access.getInstance().checkCreateAccess('Contact', new Set<String>{ 'LastName' });
            } catch (Exception ex) {
                actualExceptions.add(ex.getMessage());
            }
        }

        for (String actualException : actualExceptions) {
            System.assertEquals(String.format(Label.PermissionCreateException, new List<String>{ 'Contact.LastName' }), actualException, 'Expected the create permission exception to be thrown.');
        }
    }

    @IsTest
    private static void updateAccessThrowsExceptionOnUpdateForStandardUser() {
        List<String> actualExceptions = new List<String>();

        System.runAs(UTIL_UnitTest.createStandardUser()) {
            try {
                VOL_Access.getInstance().checkUpdateAccess('Contact', new Set<String>{ 'LastName' });
            } catch (Exception ex) {
                actualExceptions.add(ex.getMessage());
            }

            VOL_Access.getInstance().elevateGuestUserAccessSetting = !VOL_Access.getInstance().elevateGuestUserAccessSetting;
            try {
                VOL_Access.getInstance().checkUpdateAccess('Contact', new Set<String>{ 'LastName' });
            } catch (Exception ex) {
                actualExceptions.add(ex.getMessage());
            }
        }

        for (String actualException : actualExceptions) {
            System.assertEquals(String.format(Label.PermissionUpdateException, new List<String>{ 'Contact.LastName' }), actualException, 'Expected the update permission exception to be thrown.');
        }
    }

    @IsTest
    private static void createAccessThrowsExceptionOnCreateForStandardUser() {
        List<String> actualExceptions = new List<String>();

        System.runAs(UTIL_UnitTest.createStandardUser()) {
            try {
                VOL_Access.getInstance().checkCreateAccess('Contact', new Set<String>{ 'LastName' });
            } catch (Exception ex) {
                actualExceptions.add(ex.getMessage());
            }

            VOL_Access.getInstance().elevateGuestUserAccessSetting = !VOL_Access.getInstance().elevateGuestUserAccessSetting;
            try {
                VOL_Access.getInstance().checkCreateAccess('Contact', new Set<String>{ 'LastName' });
            } catch (Exception ex) {
                actualExceptions.add(ex.getMessage());
            }
        }

        for (String actualException : actualExceptions) {
            System.assertEquals(String.format(Label.PermissionCreateException, new List<String>{ 'Contact.LastName' }), actualException, 'Expected the create permission exception to be thrown.');
        }
    }

    @IsTest
    private static void indirectUpdateForGuestUserWithElevateSettingChecked() {
        setDatabaseDmlMock();
        VOL_Access.getInstance().elevateGuestUserAccessSetting = true;

        System.runAs(UTIL_UnitTest.createGuestUser()) {
            VOL_Access.getInstance().updateRecords(contacts);
        }

        System.assertEquals(1, dmlMock.countByMethodName.get('updateRecords'), 'Expected update records in database dml to have been called.');
    }

    @IsTest
    private static void indirectUpdateWithOptionsForGuestUserWithElevateSettingChecked() {
        setDatabaseDmlMock();
        VOL_Access.getInstance().elevateGuestUserAccessSetting = true;

        System.runAs(UTIL_UnitTest.createGuestUser()) {
            VOL_Access.getInstance().updateRecords(contacts, new Database.DMLOptions());
        }

        System.assertEquals(1, dmlMock.countByMethodName.get('updateRecords'), 'Expected update records in database dml to have been called.');
    }

    @IsTest
    private static void indirectInsertForGuestUserWithElevateSettingChecked() {
        setDatabaseDmlMock();
        VOL_Access.getInstance().elevateGuestUserAccessSetting = true;

        System.runAs(UTIL_UnitTest.createGuestUser()) {
            VOL_Access.getInstance().insertRecords(contacts);
        }

        System.assertEquals(1, dmlMock.countByMethodName.get('insertRecords'), 'Expected insert records in database dml to have been called.');
    }

    @IsTest
    private static void indirectInsertWithOptionsForGuestUserWithElevateSettingChecked() {
        setDatabaseDmlMock();
        VOL_Access.getInstance().elevateGuestUserAccessSetting = true;

        System.runAs(UTIL_UnitTest.createGuestUser()) {
            VOL_Access.getInstance().insertRecords(contacts, new Database.DMLOptions());
        }

        System.assertEquals(1, dmlMock.countByMethodName.get('insertRecords'), 'Expected insert records in database dml to have been called.');
    }

    @IsTest
    private static void directUpdateForAdminUsers() {
        contactRecord.LastName = 'Before Update';
        insert contactRecord;
        setDatabaseDmlMock();
        VOL_Access.getInstance().elevateGuestUserAccessSetting = true;

        System.runAs(UTIL_UnitTest.createAdminUser()) {
            contactRecord.LastName = 'After Update';
            VOL_Access.getInstance().updateRecords(contacts);
        }

        System.assertEquals(0, dmlMock.countByMethodName.get('updateRecords'), 'Did not expect update records in database dml to have been called.');
        System.assertEquals(1, [SELECT Id FROM Contact WHERE LastName = 'After Update'].size(), 'Expected the last name to have been updated on the contact record.');
    }

    @IsTest
    private static void directUpdateWithOptionsForAdminUsers() {
        contactRecord.LastName = 'Before Update With Options';
        insert contactRecord;
        setDatabaseDmlMock();
        VOL_Access.getInstance().elevateGuestUserAccessSetting = true;

        System.runAs(UTIL_UnitTest.createAdminUser()) {
            contactRecord.LastName = 'After Update With Options';
            VOL_Access.getInstance().updateRecords(contacts);
        }

        System.assertEquals(0, dmlMock.countByMethodName.get('updateRecords'), 'Did not expect update records in database dml to have been called.');
        System.assertEquals(1, [SELECT Id FROM Contact WHERE LastName = 'After Update With Options'].size(), 'Expected the last name to have been updated on the contact record.');
    }

    @IsTest
    private static void directInsertForAdminUsers() {
        setDatabaseDmlMock();
        VOL_Access.getInstance().elevateGuestUserAccessSetting = true;

        System.runAs(UTIL_UnitTest.createAdminUser()) {
            contactRecord.LastName = 'After Insert';
            VOL_Access.getInstance().insertRecords(contacts);
        }

        System.assertEquals(0, dmlMock.countByMethodName.get('insertRecords'), 'Did not expect insert records in database dml to have been called.');
        System.assertNotEquals(null, contactRecord.Id, 'Expected the insert to be performed directly.');
    }

    @IsTest
    private static void directInsertWithOptionsForAdminUsers() {
        setDatabaseDmlMock();
        VOL_Access.getInstance().elevateGuestUserAccessSetting = true;

        System.runAs(UTIL_UnitTest.createAdminUser()) {
            contactRecord.LastName = 'After Insert With Options';
            VOL_Access.getInstance().insertRecords(contacts);
        }

        System.assertEquals(0, dmlMock.countByMethodName.get('insertRecords'), 'Did not expect insert records in database dml to have been called.');
        System.assertNotEquals(null, contactRecord.Id, 'Expected the insert with options to be performed directly.');
    }


    @IsTest
    private static void updateThrowsExceptionForGuestUserWithElevateSettingUnchecked() {
        contactRecord.LastName = 'Before Update';
        insert contactRecord;
        setDatabaseDmlMock();
        VOL_Access.getInstance().elevateGuestUserAccessSetting = false;
        String actualException;

        System.runAs(UTIL_UnitTest.createGuestUser()) {
            contactRecord.LastName = 'After Update';
            try {
                VOL_Access.getInstance().updateRecords(contacts);
            } catch (Exception ex) {
                actualException = ex.getMessage();
            }
        }

        System.assertEquals(0, dmlMock.countByMethodName.get('updateRecords'), 'Did not expect update records in database dml to have been called.');
        System.assert(actualException.contains('INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY'), 'Expected a cross reference exception to be thrown. ' + actualException);
    }

    @IsTest
    private static void updateWithOptionsThrowsExceptionForGuestUserWithElevateSettingUnchecked() {
        contactRecord.LastName = 'Before Update With Options';
        insert contactRecord;
        setDatabaseDmlMock();
        VOL_Access.getInstance().elevateGuestUserAccessSetting = false;
        String actualException;

        System.runAs(UTIL_UnitTest.createGuestUser()) {
            contactRecord.LastName = 'After Update With Options';
            try {
                VOL_Access.getInstance().updateRecords(contacts);
            } catch (Exception ex) {
                actualException = ex.getMessage();
            }
        }

        System.assertEquals(0, dmlMock.countByMethodName.get('updateRecords'), 'Did not expect update records in database dml to have been called.');
        System.assert(actualException.contains('INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY'), 'Expected a cross reference exception to be thrown. ' + actualException);
    }

    @IsTest
    private static void directInsertForGuestUserWithElevateSettingUnchecked() {
        setDatabaseDmlMock();
        VOL_Access.getInstance().elevateGuestUserAccessSetting = false;
        String actualException;

        System.runAs(UTIL_UnitTest.createGuestUser()) {
            contactRecord.LastName = 'After Insert';
            VOL_Access.getInstance().insertRecords(contacts);
        }

        System.assertEquals(0, dmlMock.countByMethodName.get('insertRecords'), 'Did not expect insert records in database dml to have been called.');
        System.assertNotEquals(null, contactRecord.Id, 'Expected the insert to be performed directly.');
    }

    @IsTest
    private static void directInsertWithOptionsForGuestUserWithElevateSettingUnchecked() {
        setDatabaseDmlMock();
        VOL_Access.getInstance().elevateGuestUserAccessSetting = false;
        String actualException;

        System.runAs(UTIL_UnitTest.createGuestUser()) {
            contactRecord.LastName = 'After Insert With Options';
            VOL_Access.getInstance().insertRecords(contacts);
        }

        System.assertEquals(0, dmlMock.countByMethodName.get('insertRecords'), 'Did not expect insert records in database dml to have been called.');
        System.assertNotEquals(null, contactRecord.Id, 'Expected the insert to be performed directly.');
    }

    /////////////////
    /// Helpers
    /////////////////

    private static void setDatabaseDmlMock() {
        DatabaseDml.instance = (DatabaseDml) Test.createStub(DatabaseDml.class, dmlMock);
    }

    /*******************************************************************************************************************
     * @description Stub for DatabaseDml instance
     */
    public class Stub implements System.StubProvider {
        public Map<String, Set<SObjectType>> sObjectTypesByMethodName = new Map<String, Set<SObjectType>>();

        public Object handleMethodCall(
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs
        ) {
            addSObjectType(stubbedMethodName, listOfArgs);

            return null;
        }

        public void assertMethodCalled(String stubbedMethodName, SObjectType sObjType) {
            if (String.isEmpty(stubbedMethodName) || sObjType == null) {
                return;
            }

            System.assert(sObjectTypesByMethodName.containsKey(stubbedMethodName), 'Expected the method, ' + stubbedMethodName + ', to have been called with ' + sObjType + ' records.');
            System.assert(sObjectTypesByMethodName.get(stubbedMethodName).contains(sObjType), 'Expected ' + sObjType + ' records to have been passed in. ' + sObjectTypesByMethodName.get(stubbedMethodName));
        }

        private void addSObjectType(String stubbedMethodName, List<Object> listOfArgs) {
            if (listOfArgs == null || listOfArgs.isEmpty()) {
                return;
            }

            Set<SObjectType> sObjectTypes = sObjectTypesByMethodName.get(stubbedMethodName);
            if (sObjectTypes == null) {
                sObjectTypes = new Set<SObjectType>();
            }

            for (Object arg : listOfArgs) {
                addSObjectType(stubbedMethodName, arg, sObjectTypes);
            }
        }

        private void addSObjectType(String stubbedMethodName, Object arg, Set<SObjectType> sObjectTypes) {
            if (arg instanceof List<SObject>) {
                List<SObject> records = (List<SObject>) arg;
                if (records.isEmpty()) {
                    return; // getSObjectType returns null for the list, need to request it form the first record.
                }

                SObjectType sObjType = records[0].getSObjectType();
                sObjectTypes.add(sObjType);

                sObjectTypesByMethodName.put(stubbedMethodName, sObjectTypes);

            } else if (arg instanceof String) {
                SObjectType sObjType = ((SObject)(Type.forName('Schema.' + arg).newInstance())).getSObjectType();
                sObjectTypes.add(sObjType);

                sObjectTypesByMethodName.put(stubbedMethodName, sObjectTypes);
            }
        }
    }

}
