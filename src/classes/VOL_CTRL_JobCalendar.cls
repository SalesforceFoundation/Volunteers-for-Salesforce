/*******************************************************************************************************
* @author David Habib
* @date 7/1/2011
* @description Page Controller class for the Job Calendar visualforce page.  Provides Javascript remoting
* method for getting Job Shift data. 
*
* Written by Dave Habib, copyright (c) 2011 Groundwire
* This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/
********************************************************************************************************/
global with sharing class VOL_CTRL_JobCalendar {

    // constructor
    global VOL_CTRL_JobCalendar() {
    	
        // handle optional parameters (must use string, not ID, to handle null)
        
        // if Campaign passed in, set current state
        map<string, string> params = ApexPages.currentPage().getParameters();
        string p = params.get('campaignId');
        if (p != null && p != '') {
        	list<Campaign> listCampaign = [select Id, StartDate from Campaign where Id = :p];
        	if (listCampaign.size() > 0) {
        		initialDate = Date.valueOf(listCampaign[0].StartDate);
        		// because this is a GMT time, we should add some padding, so we'll stick
        		// with the same day, even if the locale time zone is up to 12 hours before GMT.
        		if (initialDate != null) initialDate = initialDate.addHours(12);  
        		campaignId = p;        		
        	}
        }
        
        // if Job passed in, set current state
        p = params.get('volunteerJobId');
        if (p != null && p != '') {
        	list<Volunteer_Job__c> listJob = [select Id, First_Shift__c, Campaign__c
        		from Volunteer_Job__c where Id = :p];
        	if (listJob.size() > 0) {
        		initialDate = Date.valueOf(listJob[0].First_Shift__c);
        		volunteerJobId = p;
        		// let caller control whether to filter by campaign or not.
        		//campaignId = listJob[0].Campaign__c;        		
        	}
        }
        	
		// if shift passed in, set current state
        p = params.get('volunteerShiftId');
        if (p != null && p != '') {
        	list<Volunteer_Shift__c> listShift = [select Id, Start_Date_Time__c, 
        		Volunteer_Job__c, Volunteer_Job__r.Campaign__c 
        		from Volunteer_Shift__c where Id = :p];
        	if (listShift.size() > 0) {
        		initialDate = Date.valueOf(listShift[0].Start_Date_Time__c);
        		// let caller control whether to filter by campaign & job or not.
        		//volunteerJobId = listShift[0].Volunteer_Job__c;
        		//campaignId = listShift[0].Volunteer_Job__r.Campaign__c;
        	}
        }

    	strLanguage = 'en-us'; 
        p = params.get('Language');
        if (p != null && p != '') strLanguage = p;

    	fPrint = false; 
        p = params.get('Print');
        if (p == '1') fPrint = true;

		// we can derive whether we are within Sites or not, so no need for parameter.
    	fWeb = false; 
        fWeb = (Site.getName() != null);

		p = params.get('initialDate');
		if (p != null && p != '') initialDate = DateTime.valueOf(p);
		
		strCalendarView = 'month';
        p = params.get('CalendarView');
        if (p != null && p != '') strCalendarView = p;

		// finally, keep all parameters for passing to VolunteersJobListingFS
		strParams = ApexPages.currentPage().getUrl();
		integer iparams = strParams.indexOf('?');
		if (iparams >= 0){
			strParams = strParams.substring(iparams+1);
		} else {
			strParams = '';
		}		
    }
    
    public string strURLtoCSSFile { 
        get { 
        	// only specify the css file if in the web page scenario.
            if (strURLtoCSSFile == null && fWeb) {
                list<Document> listDocs = [SELECT Name, Id From Document WHERE Name = 'JobCalendarCSS.css' LIMIT 1 ];
                if (listDocs.size() > 0) {
                    Document doc = listDocs[0];
                    string imageid = doc.id;
                    imageid = imageid.substring(0,15);
                    strURLToCSSFile = '/servlet/servlet.FileDownload?file=' + imageid;
                }
            }
            return strURLtoCSSFile;
        }  
        
        set;
    }

    private VOL_SharedCode volSharedCode;
    
    // public properties
    public string strLanguage { get; set; }
    public boolean fPrint { get; set; }
    public boolean fWeb { get; set; }
    public string strCalendarView { get; set; }
    public string strParams { get; set; }
   	 
    // holds the currently selected Campaign in the Campaign dropdown
    public ID campaignId { get; set; }

    // the list of active Volunteer Campaigns 
    public list<SelectOption> listSOCampaigns {
        get {
            list<SelectOption> listSO = new list<SelectOption>();
            listSO.add(new SelectOption('', system.label.labelChoiceAllActiveCampaigns));
            for (Campaign c : [select Name, Id, StartDate from Campaign 
            	where RecordTypeId = :VOL_SharedCode.recordtypeIdVolunteersCampaign 
            	and IsActive = true order by Name asc limit 999]) {
                listSO.add(new SelectOption(c.id, c.name));
            }       
            return listSO;
        }
        set;
    }
    
    // the user has changed the Campaign dropdown
    public virtual PageReference ChangeCampaign() {
        // clear out all state that is specific to the campaign
        listSOVolunteerJobs = null;
        volunteerJobId = null;
        ChangeVolunteerJob();
        return null;
    }

    // holds the currently select Job in the Job dropdown
    public ID volunteerJobId { get; set; }
    
    // hold the initial date for the calendar
    public DateTime initialDate { get; set; }
    
    // the list of Volunteer Jobs for the specified Campaign
    public list<SelectOption> listSOVolunteerJobs {
    	get {
	        list<SelectOption> listSO = new list<SelectOption>();
	        listSO.add(new SelectOption('', system.label.labelChoiceAllJobs));
	        if (campaignId == null) {
		        for (Volunteer_Job__c vj : [select Name, Id from Volunteer_Job__c 
		        	where Campaign__r.IsActive = true order by name limit 999]) {
		            listSO.add(new SelectOption(vj.id, vj.name));
		        }        	
	        } else {
		        for (Volunteer_Job__c vj : [select Name, Id from Volunteer_Job__c 
		        	where Campaign__c = :campaignId order by name limit 999]) {
		            listSO.add(new SelectOption(vj.id, vj.name));
		        }
	        }       
	        return listSO;
	    } 
	    
	    set;
    }    

    // the user has changed the Volunteer Job dropdown
    public virtual PageReference ChangeVolunteerJob() {
        // clear out all state that is specific to the Job

        return null;
    }
    
    
	/*******************************************************************************************************
	* @description Javascript Remoting method to return a list of Shifts, optionally filtered by strFilter.
	* &param strStartDateTime filter for Logs >= startDate
	* &param strEndDateTime filter for Logs <= endDate
	* @return list<Volunteer_Shift__c>, which will be turned into a Javascript collection.
	********************************************************************************************************/
    @RemoteAction global static list<Volunteer_Shift__c> getListShifts(string strCampaignId, string strJobId, 
    	string strStartDateTime, string strEndDateTime) {
    	DateTime dtStart = datetime.valueOf(strStartDateTime);
    	DateTime dtEnd = datetime.valueOf(strEndDateTime);
    	boolean fAllCampaign = (strCampaignId == '*');
    	boolean fAllJob = (strJobId == '*');
    	list<Volunteer_Shift__c> listShifts;
    	
    	if (!fAllJob) {
			listShifts = [select Id, Name, Volunteer_Job__c, Volunteer_Job__r.Name, 
				Volunteer_Job__r.Campaign__c, Start_Date_Time__c, Duration__c, 
				Total_Volunteers__c, Number_of_Volunteers_Still_Needed__c, Description__c
				from Volunteer_Shift__c
				where Start_Date_Time__c >= :dtStart and Start_Date_Time__c <= :dtEnd
					and Volunteer_Job__c = :strJobId
				order by Start_Date_Time__c asc];    		
    	} else if (fAllCampaign && fAllJob) {
			listShifts = [select Id, Name, Volunteer_Job__c, Volunteer_Job__r.Name, 
				Volunteer_Job__r.Campaign__c, Start_Date_Time__c, Duration__c,
				Total_Volunteers__c, Number_of_Volunteers_Still_Needed__c, Description__c
				from Volunteer_Shift__c
				where Start_Date_Time__c >= :dtStart and Start_Date_Time__c <= :dtEnd
					and Volunteer_Job__r.Campaign__r.IsActive = true
				order by Start_Date_Time__c asc];    		
    	} else if (!fAllCampaign && fAllJob) {
			listShifts = [select Id, Name, Volunteer_Job__c, Volunteer_Job__r.Name, 
				Volunteer_Job__r.Campaign__c, Start_Date_Time__c, Duration__c,
				Total_Volunteers__c, Number_of_Volunteers_Still_Needed__c, Description__c
				from Volunteer_Shift__c
				where Start_Date_Time__c >= :dtStart and Start_Date_Time__c <= :dtEnd
					and Volunteer_Job__r.Campaign__c = :strCampaignId
				order by Start_Date_Time__c asc];    		
    	}
    			
		return listShifts;
    } 		
    
    //==================== TEST METHOD(s) ======================================
    public static testmethod void TestJobCalendar() {
    	
		// create test data
        Campaign cmp = new Campaign(recordtypeid=VOL_SharedCode.recordtypeIdVolunteersCampaign, name='Job Calendar Test Campaign');
        insert cmp;
        Volunteer_Job__c job = new Volunteer_Job__c(name='Job1', campaign__c=cmp.Id);
        insert job;
        Volunteer_Shift__c shift = new Volunteer_Shift__c(Volunteer_Job__c=job.Id, Duration__c=1, Start_Date_Time__c=System.now());
        insert shift;
    	
        //point to our VF page
        PageReference p = new PageReference('Page.JobCalendar');
        p.getParameters().put('campaignId', cmp.id);
        p.getParameters().put('volunteerJobId', job.id);
        p.getParameters().put('volunteerShiftId', shift.id);
        Test.setCurrentPageReference(p);
    	
    	// start testing!
		list<Volunteer_Shift__c> listS = getListShifts('*', '*', '2010-01-01 1:1:1', '2012-01-01 1:1:1');
		system.assert(listS.size() > 0); 
		listS = getListShifts(cmp.Id, '*', '2010-01-01 1:1:1', '2012-01-01 1:1:1');
		system.assert(listS.size() == 1); 
		listS = getListShifts(cmp.Id, job.Id, '2010-01-01 1:1:1', '2012-01-01 1:1:1');
		system.assert(listS.size() == 1); 
		
        //instantiate the controller 
        VOL_CTRL_JobCalendar ctrl = new VOL_CTRL_JobCalendar();
		system.assert(ctrl.strURLtoCSSFile == null || ctrl.strURLtoCSSFile != null);
		system.assertEquals('en-us', ctrl.strLanguage);
		system.assertEquals(cmp.Id, ctrl.campaignId);
		system.assertEquals(job.Id, ctrl.volunteerJobId);
		system.assert(ctrl.listSOCampaigns.size() >= 2);
		system.assertEquals(shift.Start_Date_Time__c, ctrl.initialDate);
		system.assert(ctrl.listSOVolunteerJobs.size() >= 2);
		ctrl.campaignId = null;		
		ctrl.ChangeVolunteerJob();
		ctrl.ChangeCampaign();		 
		system.assert(ctrl.listSOVolunteerJobs.size() >= 2);

    }
}