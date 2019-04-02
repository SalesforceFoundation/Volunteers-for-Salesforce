/*
    Copyright (c) 2016, Salesforce.org
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

global with sharing class VOL_SharedCode {

    // the list of Campaigns that have Volunteer Jobs
    global List<SelectOption> listSOCampaignsWithJobs {
        get {
            List<SelectOption> selectOptions = new List<SelectOption>{ new SelectOption('', '') };
    
            for (Campaign campaignRecord : [
                SELECT Name, Id, StartDate
                FROM Campaign
                WHERE RecordTypeId = :recordtypeIdVolunteersCampaign
                    AND IsActive = true
                ORDER BY StartDate DESC, Name ASC
                LIMIT 999
            ]) {
                selectOptions.add(new SelectOption(campaignRecord.Id, campaignRecord.Name));
            }
            return selectOptions;
        }
    }

    // the list of Volunteer Jobs for the specified Campaign
    global List<SelectOption> listSOVolunteerJobsOfCampaignId(Id campaignId) {
        List<SelectOption> selectOptions = new List<SelectOption>{ new SelectOption('', '') };

        for (Volunteer_Job__c jobRecord : [
            SELECT Name, Id
            FROM Volunteer_Job__c
            WHERE Campaign__c = :campaignId
            ORDER BY Name
            LIMIT 999
        ]) {
            selectOptions.add(new SelectOption(jobRecord.Id, jobRecord.Name));
        }
        return selectOptions;
    }

    // the list of Volunteer Job Shifts for the specified Job
    global List<SelectOption> listSOVolunteerShiftsOfVolunteerJobId(
        Id jobId,
        Date startDate,
        Date endDate,
        Boolean shouldIncludeShiftName,
        Boolean shouldIncludeNumberNeeded
    ) {
        return getShiftOptions(
            jobId,
            startDate,
            endDate,
            shouldIncludeShiftName,
            shouldIncludeNumberNeeded,
            null,
            null
        );
    }

    // list of select options of Shifts for the specified job, using the date & time format strings for the shifts
    public static List<SelectOption> getShiftOptions(
        Id jobId,
        Date startDate,
        Date endDate,
        Boolean shouldIncludeShiftName,
        Boolean shouldIncludeNumberNeeded,
        String dateFormat,
        String timeFormat
    ) {
        List<Volunteer_Job__c> jobs = new List<Volunteer_Job__c>();
        List<SelectOption> selectOptions = new List<SelectOption>{ new SelectOption('', '') };

        startDate = startDate == null ? System.today() : startDate;
        endDate = (endDate == null ? System.today().addMonths(12) : endDate).addDays(1);

        // get our shifts in a Job query, so we can use our common date/time formatting routine.
        jobs = [
            SELECT Id, Campaign__r.IsActive, Campaign__r.Volunteer_Website_Time_Zone__c, Volunteer_Website_Time_Zone__c,
                (SELECT Id, Name, Start_Date_Time__c, Duration__c, Number_of_Volunteers_Still_Needed__c,
                    Description__c, System_Note__c
                FROM Volunteer_Job_Slots__r
                WHERE Start_Date_Time__c >= :startDate and Start_Date_Time__c < :endDate
                ORDER BY Start_Date_Time__c
                LIMIT 999)
            FROM Volunteer_Job__c WHERE Id = :jobId];

        if (jobs.isEmpty()) {
            return selectOptions;
        }

        // whether to use our datetime formatting, or salesforce default for the current user
        Boolean shouldFormatDateTime = dateFormat != null && timeFormat != null;

        // put correct date/time format with appropriate timezone in system note field (in memory only)
        if (shouldFormatDateTime) {
            dateTimeFixup(jobs, dateFormat, timeFormat);
        }

        for (Volunteer_Shift__c shiftRecord : jobs[0].Volunteer_Job_Slots__r) {
            SelectOption selectOpt = new SelectOption(
                shiftRecord.Id,
                (shouldFormatDateTime
                    ? shiftRecord.System_Note__c
                    : shiftRecord.Start_Date_Time__c.format()) +
                        (shouldIncludeShiftName ? '&nbsp;&nbsp;&nbsp;&nbsp;(' + shiftRecord.Name + ')' : '' ) +
                        (shouldIncludeNumberNeeded
                            ? '&nbsp;&nbsp;' +
                            (shiftRecord.Number_of_Volunteers_Still_Needed__c > 0
                                ? System.Label.labelCalendarStillNeeded + shiftRecord.Number_of_Volunteers_Still_Needed__c
                                : System.Label.labelCalendarShiftFull) +
                                ' '
                            : '')
            );
            selectOpt.setEscapeItem(false);
            selectOptions.add(selectOpt);
        }

        return selectOptions;
    }

    // routine to go through all the shifts, and create the display String
    // for the shifts start date & time - end date & time, using the appropriate
    // time zone that might be specified on the Job, Campaign, or Site Guest User.
    // Note that it stores this String in the Shift's System_Note__c field (in memory only).
    public static void dateTimeFixup(List<Volunteer_Job__c> jobs, String dateFormat, String timeFormat) {
        // get default time zone for site guest user
        User currentUser = [SELECT TimeZoneSidKey FROM User WHERE Id = :UserInfo.getUserId()];

        // javascript formatting used 'tt' for am/pm, whereas apex formatting uses 'a'.
        String format = dateFormat + ' ' + timeFormat.replace('tt','a');
        String formatEndTime = timeFormat.replace('tt','a');

        for (Volunteer_Job__c job : jobs) {
            String timeZone = job.Volunteer_Website_Time_Zone__c;
            if (timeZone == null) timeZone = job.Campaign__r.Volunteer_Website_Time_Zone__c;
            if (timeZone == null) timeZone = currentUser.TimeZoneSidKey;

            for (Volunteer_Shift__c shift : job.Volunteer_Job_Slots__r) {

                DateTime endDate = shift.Start_Date_Time__c.addMinutes(Integer.valueOf(shift.Duration__c * 60));
                String startDate = shift.Start_Date_Time__c.format(format, timeZone);

                // see if start and end are on the same day
                if (shift.Start_Date_Time__c.format('d', timeZone) == endDate.format('d', timeZone)) {
                    shift.System_Note__c =  startDate + ' - ' + endDate.format(formatEndTime, timeZone);
                } else {
                    shift.System_Note__c =  startDate + ' - ' + endDate.format(format, timeZone);
                }
            }
        }
    }

    // return the GMT datetime for a datetime in the specified timezone
    public static DateTime dtGmtFromDtTimeZone(DateTime dateToConvert, TimeZone timezone) {
        Integer offset = timezone.getOffset(dateToConvert);
        return dateToConvert.addSeconds(-offset / 1000);
    }

    // Volunteer Custom Settings object.  Loads an existing, and if not found creates one with default values.
    global static Volunteers_Settings__c volunteersSettings {
        get {
            if (volunteersSettings == null) {
                volunteersSettings = Volunteers_Settings__c.getInstance();

                if (volunteersSettings.Id == null) {
                    volunteersSettings = Volunteers_Settings__c.getOrgDefaults();
                }

                if (volunteersSettings.Id == null) {
                    volunteersSettings.SetupOwnerId = UserInfo.getOrganizationId();

                    // create reasonable defaults
                    volunteersSettings.Signup_Matches_Existing_Contacts__c = false;
                    volunteersSettings.Signup_Creates_Contacts_If_No_Match__c = false;
                    volunteersSettings.Signup_Bucket_Account_On_Create__c = null;
                    volunteersSettings.Recurring_Job_Future_Months__c = 4;
                    volunteersSettings.Contact_Match_Email_Fields__c = null;
                    volunteersSettings.Contact_Match_First_Name_Fields__c = null;
                    volunteersSettings.Personal_Site_Org_Wide_Email_Name__c = null;
                    volunteersSettings.Contact_Matching_Rule__c = 'Firstname;Lastname;Email';
                    volunteersSettings.Personal_Site_Report_Hours_Filtered__c = false;
                    if (UTIL_Describe.hasObjectCreateAccess(UTIL_Describe.StrTokenNSPrefix('Volunteers_Settings__c'))) {
                        insert volunteersSettings;
                    }

                } else if (volunteersSettings.Contact_Matching_Rule__c == null) {
                    volunteersSettings.Contact_Matching_Rule__c = 'Firstname;Lastname;Email';
                    if (UTIL_Describe.hasObjectUpdateAccess(UTIL_Describe.StrTokenNSPrefix('Volunteers_Settings__c'))) {
                        update volunteersSettings;
                    }
                }
            }

            return volunteersSettings;
        }

        set;
    }

    // helper to get the AccoutId of the Bucket Account specified in Custom Settings.
    global static Id settingsBucketAccountId {
        get {
            if (settingsBucketAccountId == null) {
                if (volunteersSettings.Signup_Bucket_Account_On_Create__c != null) {
                    List<Account> accounts = [
                        SELECT Id
                        FROM Account
                        WHERE Name = :volunteersSettings.Signup_Bucket_Account_On_Create__c
                        LIMIT 1
                    ];
                    if (accounts.size() > 0) {
                        settingsBucketAccountId = accounts[0].Id;
                    }
                }
            }
            return settingsBucketAccountId;
        }

        set;
    }

    // test helper that allows one to override the users's Custom Settings with the settings we want to test with.
    global static Volunteers_Settings__c getVolunteersSettingsForTests(Volunteers_Settings__c mySettings) {
        //clear out whatever settings exist
        delete [SELECT Id FROM Volunteers_Settings__c];
        SettingsBucketAccountId = null;

        //create our own based on what's passed in from the test
        volunteersSettings = new Volunteers_Settings__c (
            Signup_Matches_Existing_Contacts__c = mySettings.Signup_Matches_Existing_Contacts__c,
            Signup_Creates_Contacts_If_No_Match__c = mySettings.Signup_Creates_Contacts_If_No_Match__c,
            Signup_Bucket_Account_On_Create__c = mySettings.Signup_Bucket_Account_On_Create__c,
            Recurring_Job_Future_Months__c = mySettings.Recurring_Job_Future_Months__c,
            Contact_Match_Email_Fields__c = mySettings.Contact_Match_Email_Fields__c,
            Contact_Match_First_Name_Fields__c = mySettings.Contact_Match_First_Name_Fields__c,
            Contact_Matching_Rule__c = mySettings.Contact_Matching_Rule__c,
            Personal_Site_Org_Wide_Email_Name__c = mySettings.Personal_Site_Org_Wide_Email_Name__c,
            Personal_Site_Report_Hours_Filtered__c = mySettings.Personal_Site_Report_Hours_Filtered__c
        );

        insert volunteersSettings;
        return volunteersSettings;
    }

    // global helper to get the Volunteers Campaign recordtype.
    private class MyException extends Exception {}
    global static Id recordTypeIdVolunteersCampaign {
        get {
            if (recordTypeIdVolunteersCampaign == null) {
                List<RecordType> recordTypes = [SELECT Id FROM RecordType WHERE DeveloperName='Volunteers_Campaign'];

                if (recordTypes.size() == 0) {
                    throw (new MyException('The Volunteers Campaign Record Type is missing and must be restored.'));
                }

                recordTypeIdVolunteersCampaign = recordTypes[0].Id;
            }

            return recordTypeIdVolunteersCampaign;
        }
        set;
    }

    // shared routine to get all Fields names from the specified Field Set on Contact
    // also explicitly adds additional Contact fields that we will always use in our Sites pages.
    global static List<String> listStrFieldsFromContactFieldSet(Schema.FieldSet fieldSet) {
        Set<String> fields = new Set<String>();
        for (Schema.FieldSetMember field : fieldSet.getFields()) {
            fields.add(field.getFieldPath().toLowerCase());
        }
        // also add the fields we explicitly refer to in CreateOrUpdateContactFS()
        // we use a set (with lowercase) to avoid creating duplicates.
        fields.add('firstname');
        fields.add('lastname');
        fields.add('email');
        //fields.add(VOL_SharedCode.StrTokenNSPrefix('volunteer_status__c').tolowerCase());
        //fields.add(VOL_SharedCode.StrTokenNSPrefix('volunteer_notes__c').toLowerCase());

        return new List<String>(fields);
    }

    // shared routine to get all Fields names form the specified Field Set
    global static List<String> listStrFieldsFromFieldSet(Schema.FieldSet fieldSet) {
        List<String> fields = new List<String>();
        for (Schema.FieldSetMember field : fieldSet.getFields()) {
            fields.add(field.getFieldPath());
        }

        return fields;
    }

    // global code to create a new lead or contact for web volunteer signup.
    // this code is used by both the VolunteersSignup page, and the VolunteersJobListing page.
    // it uses the custom setting for the bucket account, but takes parameters for
    // matching existing contacts, and create contacts vs. leads.  this is because the two pages have different use cases.
    // it also assumes that the contact that is passed in is the dummy record from the web page, and thus isn't real, and
    // uses the Department field to track the user's company name.
    global static Id createContactOrLead(Contact webContact, Boolean shouldMatchExistingContact, Boolean shouldCreateContact) {
        // update the date before we start
        webContact.Volunteer_Last_Web_Signup_Date__c = System.today();

        // let's see if we can find any matching Contacts.
        List<Contact> contacts = [
            SELECT Id, Lastname, Firstname, Email, Phone, HomePhone,
                Volunteer_Availability__c, Volunteer_Notes__c, Volunteer_Last_Web_Signup_Date__c,
                Volunteer_Status__c, Volunteer_Skills__c, Volunteer_Organization__c
            FROM Contact
            WHERE LastName = :webContact.LastName AND FirstName= :webContact.FirstName AND Email= :webContact.Email
        ];

        Set<String> fields = new Set<String>{
            'Lastname', 'Firstname', 'Email', 'Phone', 'HomePhone',
            UTIL_Describe.StrTokenNSPrefix('Volunteer_Availability__c'),
            UTIL_Describe.StrTokenNSPrefix('Volunteer_Notes__c'),
            UTIL_Describe.StrTokenNSPrefix('Volunteer_Last_Web_Signup_Date__c'),
            UTIL_Describe.StrTokenNSPrefix('Volunteer_Status__c'),
            UTIL_Describe.StrTokenNSPrefix('Volunteer_Skills__c'),
            UTIL_Describe.StrTokenNSPrefix('Volunteer_Organization__c')
        };

        // if we can match existing contacts, and we found a match, update them.
        if (shouldMatchExistingContact && contacts.size() > 0) {

            for (Contact contactRecord : contacts) {
                contactRecord.Volunteer_Last_Web_Signup_Date__c = webContact.Volunteer_Last_Web_Signup_Date__c;
                contactRecord.Volunteer_Availability__c = webContact.Volunteer_Availability__c;
                contactRecord.Volunteer_Skills__c = webContact.Volunteer_Skills__c;

                String existingNotes = contactRecord.Volunteer_Notes__c;
                if (existingNotes != '') {
                    existingNotes += '  ';
                }
                if (webContact.Volunteer_Notes__c != null) {
                    contactRecord.Volunteer_Notes__c = existingNotes + '[' + String.valueof(System.today()) + ']: ' + webContact.Volunteer_Notes__c;
                }

                if (contactRecord.Volunteer_Status__c == null) {
                    contactRecord.Volunteer_Status__c = 'New Sign Up';
                }

                if (webContact.Phone != null) {
                    contactRecord.Phone = webContact.Phone;
                }

                if (webContact.HomePhone != null) {
                    contactRecord.HomePhone = webContact.HomePhone;
                }

                // NOTE: if we find existing contact(s), we don't worry about doing anything with Company.
                // but we can at least put it in the new Volunteer_Organization__c field.
                if (webContact.Department != null) {
                    contactRecord.Volunteer_Organization__c = webContact.Department;
                }
            }

            checkUpdateAccessSites('Contact', fields);
            Database.update(contacts, dmlDuplicateOptions);

            return contacts[0].Id;

        } else if (shouldCreateContact) {  // No Match found, create a Contact
            webContact.LeadSource = 'Web Volunteer Signup';
            webContact.Volunteer_Status__c = 'New Sign Up';

            Account accountRecord = null;

            // see if we can find their company (which we assume the form used Department to record.)
            if (webContact.Department != null) {
                List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name = :webContact.Department LIMIT 1];

                if (accounts.size() > 0) {
                    accountRecord = accounts.get(0);
                }

                webContact.Volunteer_Organization__c = webContact.Department;
            }

            // if company found, use it
            if (accountRecord != null) {
                webContact.AccountId = accountRecord.Id;

            } else { // otherwise use the bucket account (which may be null and imply the 1:1 model in NPSP)
                webContact.AccountId = VOL_SharedCode.settingsBucketAccountId;
            }

            UTIL_Describe.checkCreateAccess('Contact', fields);
            Database.insert(webContact, dmlDuplicateOptions);

            return webContact.Id;

        } else { // No Match found, create a Lead
            Lead leadRecord = new Lead();
            leadRecord.FirstName = webContact.FirstName;
            leadRecord.LastName = webContact.LastName;
            leadRecord.Company = (webContact.Department == null ? '[not provided]' : webContact.Department);
            leadRecord.Email = webContact.Email;
            leadRecord.Phone = webContact.Phone;
            leadRecord.MobilePhone = webContact.HomePhone; // leads don't have a home phone!
            leadRecord.Volunteer_Availability__c = webContact.Volunteer_Availability__c;
            leadRecord.Volunteer_Notes__c = webContact.Volunteer_Notes__c;
            leadRecord.Volunteer_Skills__c = webContact.Volunteer_Skills__c;
            leadRecord.Volunteer_Status__c = 'New Sign Up';
            leadRecord.LeadSource = 'Web Volunteer Signup';

            UTIL_Describe.checkCreateAccess('Lead',
                new Set<String>{'FirstName','LastName','Company','Email','Phone','MobilePhone','LeadSource',
                    UTIL_Describe.StrTokenNSPrefix('Volunteer_Availability__c'),
                    UTIL_Describe.StrTokenNSPrefix('Volunteer_Notes__c'),
                    UTIL_Describe.StrTokenNSPrefix('Volunteer_Skills__c'),
                    UTIL_Describe.StrTokenNSPrefix('Volunteer_Status__c')});
            Database.insert(leadRecord, dmlDuplicateOptions);

            return leadRecord.Id;
        }
    }

    // global code to verify the passed in ContactId is valid, as well as the email
    // exists on the Contact record.
    global static Boolean isValidContactIdAndEmail(Id contactId, String email) {
        String query = 'SELECT Id FROM Contact WHERE Id = :contactId ';

        if (volunteersSettings.Personal_Site_Requires_URL_Email_Match__c) {
            if (String.isBlank(email)) {
                return false;
            }

            query += 'AND (Email= :email';
            // any additional email fields to check
            if (volunteersSettings.Contact_Match_Email_Fields__c != null) {
                List<String> emailFields = new List<String>();
                emailFields = volunteersSettings.Contact_Match_Email_Fields__c.split(';');

                for (String field : emailFields) {
                    query += ' OR ' + field + ' = :email ';
                }
            }
            // handle NPSP email fields
            if (isNPSPInstalled) {
                query += ' OR npe01__AlternateEmail__c = :email ';
                query += ' OR npe01__HomeEmail__c = :email ';
                query += ' OR npe01__WorkEmail__c = :email ';
            }

            query += ') ';
        }
        List<Contact> contacts = Database.query(query);

        return contacts.size() > 0;
    }

    // global code to lookup an existing contact
    // listStrFields are optional fields to include in the soql call
    global static List<Contact> lookupContact(Contact contactRecord, List<String> fields) {
        // let's see if we can find any matching Contacts.
        // we need to use dynamic soql, since we allow the user to modify the FieldSet of fields to edit.
        String query = 'SELECT ';
        String separator = '';
        if (fields == null) {
            query += 'Id';
        } else {
            for (String field : fields) {
                query += separator + field;
                separator = ', ';
            }
        }
        query += ' FROM Contact ';
        String querySegment = ' WHERE ';

        // make sure their settings haven't been completely cleared
        if (String.isBlank(volunteersSettings.Contact_Matching_Rule__c)) {
            volunteersSettings.Contact_Matching_Rule__c = 'Firstname;Lastname;Email';
        }

        final String rule = volunteersSettings.Contact_Matching_Rule__c;
        if (rule.containsIgnoreCase(String.valueOf(Contact.LastName))) {
            query += querySegment + ' (Lastname=\'' + strEscape(contactRecord.LastName) + '\') ';
            querySegment = ' AND ';
        }
        if (rule.containsIgnoreCase(String.valueOf(Contact.FirstName))) {
            query += querySegment + ' (Firstname=\'' + strEscape(contactRecord.FirstName) + '\'';
            querySegment = ' AND ';

            // any additional firstname fields to check
            if (volunteersSettings.Contact_Match_First_Name_Fields__c != null) {
                List<String> listStrFname = new List<String>();
                listStrFname = volunteersSettings.Contact_Match_First_Name_Fields__c.split(';');
                for (String str : listStrFname) {
                    query += ' OR ' + str + '=\'' + strEscape(contactRecord.FirstName) + '\'';
                }
            }
            query += ') ';
        }
        if (rule.containsIgnoreCase(String.valueOf(Contact.Email))) {
            query += querySegment + ' (Email=\'' + contactRecord.Email + '\'';
            querySegment = ' AND ';
            // any additional email fields to check
            if (volunteersSettings.Contact_Match_Email_Fields__c != null) {
                List<String> listStrEmail = new List<String>();
                listStrEmail = volunteersSettings.Contact_Match_Email_Fields__c.split(';');
                for (String str : listStrEmail) {
                    query += ' OR ' + str + '=\'' + contactRecord.Email + '\'';
                }
            }
            // handle NPSP email fields
            if (isNPSPInstalled) {
                query += ' OR npe01__AlternateEmail__c=\'' + contactRecord.Email + '\'';
                query += ' OR npe01__HomeEmail__c=\'' + contactRecord.Email + '\'';
                query += ' OR npe01__WorkEmail__c=\'' + contactRecord.Email + '\'';
            }
            query += ') ';
        }
        query += ' LIMIT 999 ';
        List<Contact> contacts = Database.query(query);
        return contacts;
    }

    // global code to create a new contact, or update an existing contact, for web volunteer signup.
    // this code is used by both the VolunteersSignupFS page, and the VolunteersJobListingFS page.
    // if creating a new Contact, it uses the custom setting for the bucket account, but takes parameters for
    // the account name to try to lookup and match.
    // It also takes the list of fields on the contact object to copy over.
    global static Id createOrUpdateContactFS(String existingId, Contact webContact, String accountName, List<String> fields) {
        return createOrUpdateContactFS(existingId, webContact, accountName, fields, true);
    }

    global static Id createOrUpdateContactFS(String existingId, Contact webContact, String accountName, List<String> fields, Boolean setLastWebSignup) {
        // fields is the specific list of fields on the form's fieldset, which we should assume we want to save.
        // we also need to special case several fields we will potentially set, but we also need to know,
        // if they are in the fieldset or not.
        Set<String> uniqueFields = new Set<String>();

        // store all fields in lower case
        for (String strField : fields) {
            uniqueFields.add(strField.toLowerCase());
        }

        Boolean isStatusInFS = !uniqueFields.add(VOL_SharedCode.StrTokenNSPrefix('volunteer_status__c').tolowerCase());
        Boolean isNotesInFS = !uniqueFields.add(VOL_SharedCode.StrTokenNSPrefix('volunteer_notes__c').toLowerCase());

        // create a new list with all the fields
        List<String> fieldsAll = new List<String>(uniqueFields);

        // we will check perms on the fields in this set, so remove Id
        uniqueFields.remove('id');

        List<Contact> contacts = lookupContact(webContact, fieldsAll);

        // if we found a match
        if (contacts.size() > 0) {
            Contact existingContact = null;

            // match the one that has the same Id
            if (existingId != null && existingId != '') {
                for (Integer i = 0; i < contacts.size(); i++) {
                    if (contacts[i].Id == existingId) {
                        existingContact = contacts[i];
                    }
                }
            }
            // use first one if no match found.
            if (existingContact == null) {
                existingContact = contacts[0];
            }

            // special case appending Volunteer Notes, rather than overwriting.
            if (isNotesInFS) {
                if (webContact.Volunteer_Notes__c != null && webContact.Volunteer_Notes__c != existingContact.Volunteer_Notes__c) {
                    webContact.Volunteer_Notes__c = (existingContact.Volunteer_Notes__c != null ? (existingContact.Volunteer_Notes__c + '  ') : '') +
                        '[' + String.valueof(System.today()) + ']: ' + webContact.Volunteer_Notes__c;
                } else {
                    webContact.Volunteer_Notes__c = existingContact.Volunteer_Notes__c;
                }
            }

            // special case setting Volunteer Status, only if not currently set.
            if (existingContact.Volunteer_Status__c != null) {
                webContact.Volunteer_Status__c = null;
            } else {
                existingContact.Volunteer_Status__c = 'New Sign Up';
            }

            // now copy over all the non-null fields from the form's contact to the existing contact.
            // avoid overwriting existing first name or existing email, since we might match it from in a different field.
            // special case address fields
            Boolean hasMailingAddress = false;
            Boolean hasOtherAddress = false;
            for (String field : fields) {
                field = field.toLowerCase();
                // we actually still want to copy email if it is currently empty
                if (field == 'email' && existingContact.Email == null) {
                    existingContact.Email = webContact.Email;
                    continue;
                }
                if (field != 'id' && field != 'firstname' && field != 'email' && webContact.get(field) != null) {
                    if (isMailingAddressField(field)) {
                        hasMailingAddress = true;
                        continue;
                    }
                    if (isOtherAddressField(field)) {
                        hasOtherAddress = true;
                        continue;
                    }
                    existingContact.put(field, webContact.get(field));
                }
            }
            if (hasMailingAddress) {
                VOL_StateCountryPicklists.copyAddressStdSObj(webContact, 'Mailing', existingContact, 'Mailing');
            }
            if (hasOtherAddress) {
                VOL_StateCountryPicklists.copyAddressStdSObj(webContact, 'Other', existingContact, 'Other');
            }

            if (setLastWebSignup) {
                existingContact.Volunteer_Last_Web_Signup_Date__c = System.today();
            }

            checkUpdateAccessSites('Contact', uniqueFields);
            Database.update(existingContact, dmlDuplicateOptions);
            // null out notes, so another update won't append them again!
            webContact.Volunteer_Notes__c = null;

            return existingContact.Id;

        } else {  // No Match found, create a Contact

            // don't assume the contact object wasn't already used.
            // since we can't null out Id for the insert, copy all
            // the fields to a new object and use it.
            Contact contactRecord = new Contact();
            //  now copy over all the non-null fields from the form's contact to the existing contact.
            // special case address fields
            Boolean hasMailingAddress = false;
            Boolean hasOtherAddress = false;
            for (String field : fields) {
                field = field.toLowerCase();
                if (field != 'id' && webContact.get(field) != null) {
                    if (isMailingAddressField(field)) {
                        hasMailingAddress = true;
                        continue;
                    }
                    if (isOtherAddressField(field)) {
                        hasOtherAddress = true;
                        continue;
                    }
                    contactRecord.put(field, webContact.get(field));
                }
            }
            if (hasMailingAddress) {
                VOL_StateCountryPicklists.copyAddressStdSObj(webContact, 'Mailing', contactRecord, 'Mailing');
            }
            if (hasOtherAddress) {
                VOL_StateCountryPicklists.copyAddressStdSObj(webContact, 'Other', contactRecord, 'Other');
            }

            // see if we can find their company
            Account accountRecord = null;
            if (accountName != null) {
                List<Account> listAccount = [SELECT Id, Name FROM Account WHERE Name = :accountName LIMIT 1];
                if (listAccount.size() > 0) accountRecord = listAccount.get(0);
            }

            // if company found, use it
            if (accountRecord != null) {
                contactRecord.AccountId = accountRecord.Id;
            } else { // otherwise use the bucket account (which may be null and imply the 1:1 model in NPSP)
                contactRecord.AccountId = VOL_SharedCode.settingsBucketAccountId;
            }

            if (setLastWebSignup) {
                contactRecord.Volunteer_Last_Web_Signup_Date__c = System.today();
            }

            contactRecord.LeadSource = 'Web Volunteer Signup';
            contactRecord.Volunteer_Status__c = 'New Sign Up';

            UTIL_Describe.checkCreateAccess('Contact', uniqueFields);
            Database.insert(contactRecord, dmlDuplicateOptions);

            // null out notes, so another update won't append them again!
            webContact.Volunteer_Notes__c = null;

            return contactRecord.Id;
        }
    }

    /*******************************************************************************************************
    * @description detects standard mailing address fields
    * @param field The field to check against
    * @return Boolean True if it is a standard mailing address field, false if not.
    */
    public static Boolean isMailingAddressField(String field) {
        return field.containsIgnoreCase('mailing') && !field.endsWith('__c');
    }

    /*******************************************************************************************************
    * @description detects standard other address fields
    * @param field The field to check against
    * @return Boolean True if it is a standard other address field, false if not.
    */
    public static Boolean isOtherAddressField(String field) {
        return field.containsIgnoreCase('other') && !field.endsWith('__c') && !field.equalsIgnoreCase('otherphone');
    }

    // global utility to escape a String.
    global static String strEscape(String val) {
        return val == null ? null : String.escapeSingleQuotes(val);
    }

    // global utility to load up an existing object and copy it to the provided object
    global static void loadAndCopyObject(Id recordId, SObject sObj) {

        // this code moved to VOL_SharedCodeAPI25 to keep it running with api 25
        // behavior, which is that the Sites Guest User Profile can still edit
        // this new contact object we created.  Under api 31, the contact object is readonly.
        // we needed to update the rest of this class to api 31 to handle state & country picklists.
        VOL_SharedCodeAPI25.loadAndCopyObject(recordId, sObj, null);
    }

    public static void volunteerHoursTrigger(List<Volunteer_Hours__c> oldHours, List<Volunteer_Hours__c> newHours, Boolean shouldResetTotals) {

        // consider both newMap and oldMap.
        // for each hours object, there are two potential shifts it interacts with.
        // within a batch of hours changes (import scenario), multiple hours can affect the same shift.
        // thus need to keep track of the shifts to update, their original value, and the sum of their changed values.

        // Insert scenario: status=Confirmed or Completed. Shift <> null. Number of Volunteers <> null.
        // Delete scenario: status=Confirmed or Completed.  Shift <> null. Number of Volunteers <> null.
        // Update scenario: just treat as a delete and an insert, since we already have to handle multiple changes to same job!


        // WARNING: deleting, undeleting, or merging a Contact, does NOT call any trigger on the Hours!
        // thus I've manually called this from the before delete & after undelete trigger on Contacts (VOL_Contact_MaintainHours).
        Map<Id, Double> numberOfVolunteersByShiftId = new Map<Id, Double>();

        // first we go through the new hours, and add up the number of volunteers per shift
        if (newHours != null) {
            for (Volunteer_Hours__c hour : newHours) {
                if ((hour.Status__c == 'Confirmed' || hour.Status__c == 'Completed')
                    && (hour.Volunteer_Shift__c <> null && hour.Number_Of_Volunteers__c != null))
                {
                    Double numberOfVolunteers = numberOfVolunteersByShiftId.get(hour.Volunteer_Shift__c);
                    if (numberOfVolunteers == null) {
                        numberOfVolunteers = 0;
                    }
                    numberOfVolunteers += hour.Number_of_Volunteers__c;
                    numberOfVolunteersByShiftId.put(hour.Volunteer_Shift__c, numberOfVolunteers);
                }
            }
        }

        // second we go through the old hours, and subtract the number of volunteers per shift
        if (oldHours != null) {
            for (Volunteer_Hours__c hour : oldHours) {
                if ((hour.Status__c == 'Confirmed' || hour.Status__c == 'Completed')
                && (hour.Volunteer_Shift__c <> null && hour.Number_Of_Volunteers__c != null))
                {
                    Double numberOfVolunteers = numberOfVolunteersByShiftId.get(hour.Volunteer_Shift__c);
                    if (numberOfVolunteers == null) numberOfVolunteers = 0;
                    numberOfVolunteers -= hour.Number_of_Volunteers__c;
                    numberOfVolunteersByShiftId.put(hour.Volunteer_Shift__c, numberOfVolunteers);
                }
            }
        }

        // bail out if nothing found (to avoid runtime error!)
        if (numberOfVolunteersByShiftId.size() == 0) {
            return;
        }

        // now that we have the Id's of the shifts, let's get them from the database, update them by the number of volunteers, and then commit.
        //List<Volunteer_Shift__c> listShifts = new List<Volunteer_Shift__c>();
        for (List<Volunteer_Shift__c> shifts : [
            SELECT Id, Total_Volunteers__c FROM Volunteer_Shift__c WHERE Id IN :numberOfVolunteersByShiftId.keySet()
        ]) {
            // loop through and update them
            for (Volunteer_Shift__c shift : shifts) {
                Double numberOfVolunteers = shift.Total_Volunteers__c;
                if (numberOfVolunteers == null || shouldResetTotals) {
                    numberOfVolunteers = 0;
                }

                shift.Total_Volunteers__c = numberOfVolunteers + numberOfVolunteersByShiftId.get(shift.Id);
            }

            update shifts;
        }
    }


    // global utility used to detect whether the Non Profit Starter Pack is installed in this instance.
    private static Boolean hasCheckedForNPSP = false;
    global static Boolean isNPSPInstalled {
        get {
            if (!hasCheckedForNPSP) {
                Schema.SObjectType token = Schema.getGlobalDescribe().get('npe01__OppPayment__c');
                isNPSPInstalled = (token != null);
                hasCheckedForNPSP = true;
            }
            return isNPSPInstalled;
        }
        set;
    }

    // global utility used to detect whether the Volunteers is running in a managed instance or unmanaged instance
    private static Boolean hasCheckedForV4S = false;
    global static Boolean isManagedCode {
        get {
            if (!hasCheckedForV4S) {
                // in order for this call to work as expected, we must be API Version 28, but we
                // want to stay at version 25, so let's find another way!!
                //Schema.SObjectType token = Schema.getGlobalDescribe().get('GW_Volunteers__Volunteer_Job__c');
                //isManagedCode = (token != null);

                isManagedCode = (getNamespace() != '');

                hasCheckedForV4S = true;
            }
            return isManagedCode;
        }
        set;
    }

    /******************************************************************************************************
    * @description String helper property for getNamespace() method.
    *******************************************************************************************************/
    private static String plainNamespace;

    /*******************************************************************************************************
    * @description Finds the namespace for the current context.
    * @return String The current namespace as a String, or a blank String if we're not in a namespaced context.
    ********************************************************************************************************/
    public static String getNamespace() {
        if (plainNamespace == null) {
            String withDotNotation = VOL_SharedCode.class.getName();

            if (withDotNotation.contains('.')) {
                plainNamespace = withDotNotation.substringBefore('.');
            } else {
                plainNamespace = '';
            }
        }
        return plainNamespace;
    }

    /*******************************************************************************************************
    * @description Static method that takes a String
    * If we are in a managed package, tokens in dynamic SOQL must include the package namespace prefix.
    * If you ever deploy this package as unmanaged, this routine will do nothing!
    * @param val token name
    * @return token name, with namespace prefix, if required.
    ********************************************************************************************************/
    global static String StrTokenNSPrefix(String val) {
        if (getNamespace() == '') {
            return val;
        }

        val = getNamespace() + '__' + val;
        return val;
    }

    // utility to verify all the specified fields are accessible to the current user.
    // fields that are not accessible will have a pageMessage added to the current page
    // so the warning is displayed to the user.
    global static void testObjectFieldVisibility(String sObj, List<String>fields) {
        Map<String, Schema.SObjectType> globalDescribe;
        Schema.DescribeSObjectResult sObjectDescribe;
        Map<String, Schema.SObjectField> sObjectFieldByName;

        // Obtaining the field name/token map for the object
        globalDescribe = Schema.getGlobalDescribe();
        if (globalDescribe != null)
            sObjectDescribe = globalDescribe.get(sObj).getDescribe();
        if (sObjectDescribe != null)
            sObjectFieldByName = sObjectDescribe.fields.getMap();
        if (sObjectFieldByName !=  null)
            for (String field : fields) {
                // Check if the user has access on the each field
                // note that fields in our own package must not have their prefix for the Describe Field Map
                Schema.SObjectField sObjectField = sObjectFieldByName.get(field.replace(StrTokenNSPrefix(''), ''));
                if (sObjectField != null && !sObjectField.getDescribe().isAccessible()) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Field ' + sObj + '.' + field +
                        ' You need to enable field level security for this field on the Site\'s Guest User profile.'));
                }
            }
    }

    /*******************************************************************************************************
    * @description Static method checks if running user has field update access for a set of fields
    * @param objectName the name of the object the field belongs to
    * @param fieldNames the set of field names to check update access
    * @return void
    ********************************************************************************************************/
    public static void checkUpdateAccessSites(String objectName, Set<String> fieldNames) {
        // for backward compatibility with 1000's of nonprofit customers, we can
        // only enforce create permissions on the Sites user for Contacts.
        if (objectName == 'Contact') {
            UTIL_Describe.checkCreateAccess(objectName, fieldNames);

        } else {
            UTIL_Describe.checkUpdateAccess(objectName, fieldNames);
        }
    }

    /** Description: DML options to allow overriding duplicate rules to create contacts, while throwing
    * exceptions for validation rules, required fields, etc.
    */
    private static Database.DMLOptions dmlDuplicateOptions {
        get {
            if (dmlDuplicateOptions == null) {
                dmlDuplicateOptions = new Database.DMLOptions();
                dmlDuplicateOptions.optAllOrNone = true;
                dmlDuplicateOptions.DuplicateRuleHeader.allowSave = true;
            }

            return dmlDuplicateOptions;
        }
    }

    // This massively nested SOQL where statement looks hard coded and dumb, but as it turns out
    // there's a limit on number of campaign hierarchy levels anyway, so this isn't as dumb as it
    // seems. This method will get all campaigns in hierarchy, and keeps the logic in a single query

    /*******************************************************************************************************
    * @description Static method that takes an Id
    * Return a list of Campaign Ids that are children/grand-children &c of the given Campaign.
    * @param Id for any campaign
    * @return List<Id> of child campaigns
    ********************************************************************************************************/
    global static List<Id> listIdsCampaignsInHierarchy(Id campaignId) {
        Map<Id, Campaign> campaignsInHierarchy = new Map<Id, Campaign>([
            SELECT Id, Name
            FROM Campaign
            WHERE IsActive = :true
                AND RecordTypeId = :recordtypeIdVolunteersCampaign
                AND (Id = :campaignId
                    OR ParentId = :campaignId
                    OR Parent.ParentId = :campaignId
                    OR Parent.Parent.ParentId = :campaignId
                    OR Parent.Parent.Parent.ParentId = :campaignId
                    OR Parent.Parent.Parent.Parent.ParentId = :campaignId)
        ]);

        return new List<Id>(campaignsInHierarchy.keySet());
    }


    /*******************************************************************************************************
    * @description keeps references to old labels that have been packaged, that we no longer use.
    * @return void
    ********************************************************************************************************/
    private static void keepUnusedLabelsInPackage() {
        String unusedLabel;
        unusedLabel = System.Label.labelCalendarConfirmed;
        unusedLabel = System.Label.labelContactInfoRankText;
        unusedLabel = System.Label.labelHide;
        unusedLabel = System.Label.labelMassEmailHelp1;
        unusedLabel = System.Label.labelMassEmailHelp2;
        unusedLabel = System.Label.labelMassEmailHelp3;
        unusedLabel = System.Label.labelMassEmailHelp4;
        unusedLabel = System.Label.labelMassEmailHelp5;
        unusedLabel = System.Label.labelMassEmailHelp6;
        unusedLabel = System.Label.labelMassEmailHelp7;
        unusedLabel = System.Label.labelShowHelp;
        unusedLabel = System.Label.labelFindVolunteersCriteria;
        unusedLabel = System.Label.labelFindVolunteersHelpAssign;
        unusedLabel = System.Label.labelVolunteersWizardNewCampaignTitle;
    }

}
