// Written by David Habib, copyright (c) 2010-2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

global with sharing class VOL_CTRL_PersonalSiteContactInfo {
	
	global VOL_CTRL_PersonalSiteContactInfo() {

		// set default property values
		cRowsCompleted = 10;
		cRowsUpcoming = 10;
    	strDateFormat = 'E M/d/yy';
    	strTimeFormat = 'h:mm tt';
    	strLanguage = 'en-us'; 
    	isEditing = false;

        map<string, string> params = ApexPages.currentPage().getParameters();
        string p;
        p = params.get('Language');
        if (p != null && p != '') strLanguage = p;
        p = params.get('DateFormat');
        if (p != null && p != '') strDateFormat = p;
        p = params.get('TimeFormat');
        if (p != null && p != '') strTimeFormat = p;
        
        p = params.get('contactId');
        if (p != null && p != '') {
        	contactId = p;
        	// cache the contactId for all pages to use.
			Cookie cId = new cookie('contactIdPersonalSite', contactId, null, -1, false);
        	ApexPages.currentPage().setCookies(new Cookie[] {cId});
        } else {
	        // check for cached Id
	        Cookie cId = ApexPages.currentPage().getCookies().get('contactIdPersonalSite');
	        if (cId != null) contactId = cId.getValue();        
        }
        
		// if we still don't know who we are editing, need to bail out.
        if (contactId == null) {    	
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Please pass in a contactId with the URL.')); 	
        	return;
        }

        // let's see if we can find any matching Contacts.
        // we need to use dynamic soql, since we allow the user to modify the FieldSet of fields to edit.
        string strSoql = 'select ';
        string strComma = '';
        for (string strF : listStrContactFields) {
        	strSoql += strComma + strF;
        	strComma = ', ';
        }
        strSoql += ' from Contact where Id=:contactId';
        strSoql += ' limit 1';      
        listCon = Database.Query(strSoql); 
        
        if (listCon.size() > 0) {        	
        	Contact con = listCon[0];
        	contactId = con.Id;
            //  now copy over all the non-null fields from the form's contact to the existing contact.
            for (string strF : listStrContactFields) {
            	if (con.get(strF) != null) {
            		try {
            			contactEdit.put(strF, con.get(strF));
            		} catch(exception ex) {
            			
            		}
            	}
            }
            // also maintain a readonly version of the contact to display rollup summary fields.
            contactReadOnly = con;
        }
        
	}

    global Contact contactEdit { 
        get {
            if (contactEdit == null) contactEdit = new Contact();
            return contactEdit;
        }       
        set; 
    }
    
    global Contact contactReadOnly { 
        get {
            if (contactReadOnly == null) contactReadOnly = new Contact();
            return contactReadOnly;
        }       
        set; 
    }

    global ID contactId { get; set; }
    global boolean isEditing { get; set; }
    global ID hoursId { get; set; }	// to hold the ID of the hours record an action is being performed on.
    private list<Contact> listCon { get; set; }	// to hold the loaded contact record
    global integer cRowsCompleted { get; set; }
    global integer cRowsUpcoming { get; set; }
    global string strDateFormat { get; set; }
 	global string strTimeFormat { get; set; }
 	global string strLanguage { get; set; }
 	
    private list<string> listStrContactFields { 
    	get {
    		if (listStrContactFields == null) {
				Map<String, Schema.SObjectField> mapS = Schema.SObjectType.Contact.fields.getMap();
				listStrContactFields = new list<string>();
				listStrContactFields.addAll(mapS.keySet());    		    			
    		}
    		return listStrContactFields;
    	}
    	set;
    }
        
    private list<string> listStrHoursFields { 
    	get {
    		if (listStrHoursFields == null) {
				Map<String, Schema.SObjectField> mapS = Schema.SObjectType.Volunteer_Hours__c.fields.getMap();
				listStrHoursFields = new list<string>();
				listStrHoursFields.addAll(mapS.keySet());    		    			
    		}
    		return listStrHoursFields;
    	}
    	set;
    }
       
    // The list of Completed Volunteer Hours.
    global list<Volunteer_Hours__c> listCompletedVolunteerHours {
        get {
            if (listCompletedVolunteerHours == null) {
		        string strSoql = 'select Volunteer_Job__r.Name, Volunteer_Job__r.Volunteer_Website_Time_Zone__c, ' +
		        	' Volunteer_Job__r.Campaign__r.Volunteer_Website_Time_Zone__c, Volunteer_Shift__r.Duration__c, ';
		        string strComma = '';
		        for (string strF : listStrHoursFields) {
		        	strSoql += strComma + strF;
		        	strComma = ', ';
		        }
		        strSoql += ' from Volunteer_Hours__c where Contact__c = :contactId ';
		        strSoql += ' and Status__c = \'Completed\' ';
		        strSoql += ' order by Start_Date__c DESC ';
		        strSoql += ' limit ' + cRowsCompleted;
		        listCompletedVolunteerHours = Database.Query(strSoql); 
		        // store friendly datetime string in system field for display only
		        dateTimeFixup(listCompletedVolunteerHours);
            }
            return listCompletedVolunteerHours;
        }        
        set;
    }
    
    // The list of Upcoming Volunteer Hours.
    global list<Volunteer_Hours__c> listUpcomingVolunteerHours {
        get {
            if (listUpcomingVolunteerHours == null) {
		        string strSoql = 'select Volunteer_Job__r.Name, Volunteer_Job__r.Volunteer_Website_Time_Zone__c, ' +
		        	' Volunteer_Job__r.Campaign__r.Volunteer_Website_Time_Zone__c, Volunteer_Shift__r.Duration__c, ';
		        string strComma = '';
		        for (string strF : listStrHoursFields) {
		        	strSoql += strComma + strF;
		        	strComma = ', ';
		        }
		        strSoql += ' from Volunteer_Hours__c where Contact__c = :contactId ';
		        strSoql += ' and Status__c <> \'Canceled\' ';
		        Date dtToday = system.today();
		        strSoql += ' and Shift_Start_Date_Time__c >= :dtToday ';
		        strSoql += ' order by Shift_Start_Date_Time__c ASC ';        
		        strSoql += ' limit ' + cRowsUpcoming;
		        listUpcomingVolunteerHours = Database.Query(strSoql); 		        
		        // store friendly datetime string in system field for display only
		        dateTimeFixup(listUpcomingVolunteerHours);
            }
            return listUpcomingVolunteerHours;
        }        
        set;
    }  
    
    // routine to go through all the hours, and create the display string
    // for the shifts start time - end date & time, using the appropriate
    // time zone that might be specified on the Job, Campaign, or Site Guest User.
    // Note that it stores this string in the Hours' System_Note__c field (in memory only).
    private void dateTimeFixup(list<Volunteer_Hours__c> listHours) {
    	
    	// get default time zone for site guest user
    	User u = [Select TimeZoneSidKey From User where id =: Userinfo.getUserId()];
    	
    	// javascript formatting used 'tt' for am/pm, whereas apex formatting uses 'a'.
    	string strFormat = strDateFormat + ' ' + strTimeFormat.replace('tt','a');
    	string strFormatEndTime = strTimeFormat.replace('tt','a');
    	
    	for (Volunteer_Hours__c hr : listHours) {
			string strTimeZone = hr.Volunteer_Job__r.Volunteer_Website_Time_Zone__c;
			if (strTimeZone == null) strTimeZone = hr.Volunteer_Job__r.Campaign__r.Volunteer_Website_Time_Zone__c;
			if (strTimeZone == null) strTimeZone = u.TimeZoneSidKey;

			DateTime dtStart = hr.Planned_Start_Date_Time__c == null ? hr.Shift_Start_Date_Time__c : hr.Planned_Start_Date_Time__c;
			if (dtStart == null) dtStart = hr.Start_Date__c;
			double duration = hr.Hours_Worked__c == null ? hr.Volunteer_Shift__r.Duration__c : hr.Hours_Worked__c;
			DateTime dtEnd = dtStart.addMinutes(integer.valueOf(duration * 60));
			string strStart = dtStart.format(strFormat, strTimeZone);
			
			// see if start and end are on the same day
			if (dtStart.format('d', strTimeZone) == dtEnd.format('d', strTimeZone)) {
				hr.System_Note__c =  dtStart.format(strFormatEndTime, strTimeZone) + ' - ' + dtEnd.format(strFormatEndTime, strTimeZone);	
			} else {
				hr.System_Note__c =  dtStart.format(strFormatEndTime, strTimeZone) + ' - ' + dtEnd.format(strFormat, strTimeZone);	    				
			}    			
    	}
    }
        
	global PageReference edit() {
		isEditing = true;    
		return null;
	}

	global PageReference save() {  
        if (listCon.size() > 0) {        	
        	Contact con = listCon[0];       	
            //  now copy over all the non-null fields from the form's contact to the existing contact.
            for (string strF : listStrContactFields) {
            	if (contactEdit.get(strF) != null) {
            		try {
            			con.put(strF, contactEdit.get(strF));
            		} catch(exception ex) {
            			
            		}
            	}
            }            
            // save the changes
            update con;
        }
		isEditing = false;
		return null;
	}
	
	global PageReference cancel() {
		isEditing = false;
		return null;
	}
	   
	global PageReference cancelShift() {
		if (hoursId != null) {           
			Volunteer_Hours__c hr = [select Id, Status__c, Hours_Worked__c from Volunteer_Hours__c where Id = :hoursId];
			hr.Status__c = 'Canceled';
			hr.Hours_Worked__c = 0;
			update hr;
			hoursId = null; 
			listUpcomingVolunteerHours = null; // to force it to be refreshed.
		}
		return null;
	}
	
	global PageReference showMoreRowsCompleted() {
		cRowsCompleted += 10;
		listCompletedVolunteerHours = null;
		return null;
	}

	global PageReference showMoreRowsUpcoming() {
		cRowsUpcoming += 10;
		listUpcomingVolunteerHours = null;
		return null;
	}
	
	// global method to get the list of ChartData items to run the visualforce chart off of.
	global list<ChartData> getChartData() {
		integer cMonths = 12;
		Date dtStart = date.today().addMonths(-cMonths + 1).toStartOfMonth();
		
		list<AggregateResult> listAG = [select CALENDAR_YEAR(Start_Date__c) theYear, CALENDAR_MONTH(Start_Date__c) theMonth, SUM(Hours_Worked__c) sumHours 
		    from Volunteer_Hours__c 
		    where Contact__c = :contactId and Status__c = 'Completed' and Start_Date__c >= :dtStart
      		group by CALENDAR_YEAR(Start_Date__c), CALENDAR_MONTH(Start_Date__c) 
      		order by CALENDAR_YEAR(Start_Date__c), CALENDAR_MONTH(Start_Date__c) ];
      	
      	list<ChartData> listCD = new list<ChartData>();
      	
      	Date dtNext = dtStart;
      	Time timeT = Time.newInstance(1, 0, 0, 0);
      	for (AggregateResult ag : listAG) {
      		Date dt = date.newInstance(integer.valueOf(ag.get('theYear')), integer.valueOf(ag.get('theMonth')), 1);
      		
      		// handle months with no data
      		while (dtNext < dt) {
	      		listCD.add(new ChartData(datetime.newInstance(dtNext,timeT).format('MMM yyyy'), 0));  	
	      		dtNext = dtNext.addMonths(1);  		
      		}
      		
      		listCD.add(new ChartData(datetime.newInstance(dt,timeT).format('MMM yyyy'), integer.valueOf(ag.get('sumHours'))));
      		dtNext = dt.addMonths(1);
      	}
      	return listCD;
	}
	
	// our wrapper class to hold chart data for each of the last N months
	global class ChartData {		
		public string strDateLabel { get; set; }
		public integer sumHours { get; set; }		
		public ChartData (string strDateLabel, integer sumHours) {
			this.strDateLabel = strDateLabel;
			this.sumHours = sumHours;			
		}
	}
	
	global string strRank {
		get {
			if (strRank == null) {
				integer cMonths = 12;
				Date dtStart = date.today().addMonths(-cMonths + 1).toStartOfMonth();
				
		      	integer iVol = 0;
		      	integer iCurrent = 0;

				for (list<AggregateResult> listAG : [select Contact__c cId, SUM(Hours_Worked__c) sumHours 
				    from Volunteer_Hours__c 
				    where Status__c = 'Completed' and Start_Date__c >= :dtStart
		      		group by Contact__c 
		      		having SUM(Hours_Worked__c) > 0 
		      		order by SUM(Hours_Worked__c) desc ]) {
		      	
			      	for (AggregateResult ag : listAG) {
			      		if (ag.get('cId') == contactId) {
			      			iCurrent = iVol;
			      		}
			      		iVol++;
			      	}
		      	}
		      	if (iVol > 2) {
		      		integer irank = integer.valueOf(100 * (decimal.valueOf(iCurrent)/decimal.valueOf(iVol - 1)));
		      		if (irank == 0) irank = 1;
		      		strRank = irank +  + '%';
		      	}			
			}
			return strRank;
		}
		private set;
	}
	
    //******************************************************************************************************
    // Test Code
    public static testmethod void TestPage() {
		// create test data
        Campaign cmp = new Campaign(recordtypeid=VOL_SharedCode.recordtypeIdVolunteersCampaign, 
        	name='Volunteer Personal Site Test Campaign', IsActive=true);
        insert cmp;
        Volunteer_Job__c job = new Volunteer_Job__c(name='Job1', campaign__c=cmp.Id);
        insert job;
		Contact contact = new Contact(firstname='test', lastname='test');
		insert contact;
		
		Job_Recurrence_Schedule__c jrs = new Job_Recurrence_Schedule__c(
			Volunteer_Job__c = job.Id,
			Days_of_Week__c = 'Monday;Friday',
			Duration__c = 1.5,
			Schedule_Start_Date_Time__c = datetime.now(),
			Weekly_Occurrence__c = '1st');
		insert jrs;
		system.assertNotEquals(null, jrs.Id);
    	
		Volunteer_Recurrence_Schedule__c vrs = new Volunteer_Recurrence_Schedule__c(
			Contact__c = contact.Id, 
			Volunteer_Job__c = job.Id,
			Days_of_Week__c = 'Monday;Friday',
			Duration__c = 1.5,
			Schedule_Start_Date_Time__c = datetime.now(),
			Weekly_Occurrence__c = '1st');
		insert vrs;
		system.assertNotEquals(null, vrs.Id);
    	
    	// setup page
        PageReference pageRef = Page.PersonalSiteContactInfo;
        pageRef.getParameters().put('contactId', contact.Id);        
        Test.setCurrentPage(pageRef); 

        //instantiate the controller 
        VOL_CTRL_PersonalSiteContactInfo ctrl = new VOL_CTRL_PersonalSiteContactInfo();
        System.AssertNotEquals(null, ctrl.listStrHoursFields);
        System.AssertNotEquals(null, ctrl.contactEdit);
        System.AssertNotEquals(null, ctrl.contactReadOnly);
        System.AssertNotEquals(null, ctrl.contactId);
        System.AssertNotEquals(null, ctrl.listCompletedVolunteerHours);
        System.AssertEquals(0, ctrl.listCompletedVolunteerHours.size());
        System.AssertNotEquals(null, ctrl.listUpcomingVolunteerHours);
        System.AssertNotEquals(0, ctrl.listUpcomingVolunteerHours.size());
        ctrl.showMoreRowsCompleted();
        ctrl.showMoreRowsUpcoming();
        
        // mark some hours completed
        list<Volunteer_Hours__c> listHours = [select Id, Status__c from Volunteer_Hours__c where Contact__c = :contact.Id];
        system.assertNotEquals(null, listHours);
        system.assert(listHours.size() > 2);
        listHours[0].Status__c = 'Completed';
        listHours[1].Status__c = 'Completed';
        update listHours;
        
        system.assertNotEquals(null, ctrl.getChartData());
        system.assertEquals(null, ctrl.strRank); // null because we don't have enough other volunteers in test data.
        
        system.assertEquals(null, ctrl.Edit());
        system.assertEquals(null, ctrl.Cancel());
        
        ctrl.contactEdit.LastName = 'TestIsNowTesty';
        ctrl.save();
        Contact con = [select Id, LastName from Contact where Id = :ctrl.contactId];
        system.assertEquals('TestIsNowTesty', con.LastName);
        
        // CancelShift
        ctrl.hoursId = listHours[0].Id;
        ctrl.cancelShift();
        listHours = [select Id, Status__c from Volunteer_Hours__c where Contact__c = :contact.Id and Status__c = 'Canceled'];
        system.assertEquals(1, listHours.size());
        
    }
	
}