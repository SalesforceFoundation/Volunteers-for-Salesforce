/*******************************************************************************************************
* @author David Habib
* @date 11/1/2012
* @description Main class for managing Volunteer Recurrence Schedules (VRS). 
*
* Written by David Habib, copyright (c) 2013 DJH Consulting, djhconsulting.com 
* This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/
********************************************************************************************************/
public with sharing class VOL_VRS {


    //******************************************************************************************************
	// for the specified VRS's, delete all hours that are not completed hours.
	// called from the After Delete VRS trigger.
	public static void DeleteListVRS(list<Volunteer_Recurrence_Schedule__c> listVRS) {
		DeleteListVRS(listVRS, false);
	}
		
    //******************************************************************************************************
	// for the specified VRS's, delete all hours that are not completed hours.
	// called from the After Delete VRS trigger and when we are processing a modified VRS.
	private static void DeleteListVRS(list<Volunteer_Recurrence_Schedule__c> listVRS, boolean fPreserveCanceled) {

		// get a set of the VRS ID's for querying
		set<ID> setVRSId = new set<ID>();
		for (Volunteer_Recurrence_Schedule__c vrs : listVRS) {
			setVRSId.add(vrs.Id);
		}
		
		// get all hours associated with these VRS's that we should delete
		list<Volunteer_Hours__c> listHours = new list<Volunteer_Hours__c>();
		if (fPreserveCanceled) {
			listHours = [select Id from Volunteer_Hours__c  
				where (Status__c <> 'Completed' and Status__c <> 'Canceled' and
					Volunteer_Recurrence_Schedule__c in : setVRSId)];
		} else {
			listHours = [select Id from Volunteer_Hours__c  
				where (Status__c <> 'Completed' and
					Volunteer_Recurrence_Schedule__c in : setVRSId)];			
		}
				
		delete listHours;
	}

   	//******************************************************************************************************
	// given a list of Volunteer recurring schedules, does all the work to delete any hours that
	// no longer match, and creates new hours into the future.
	// called from both the VRS trigger (when the user modifies a specific VRS),
	// as well as from the JRS processing, so new shifts get their hours assigned.
	public static void ProcessListVRS(list<Volunteer_Recurrence_Schedule__c> listVRS) {
		
		// get a set of the VRS ID's for querying
		// also the Job ID's they are associated with
		// also the contact ID's they are associated with
		set<ID> setVRSId = new set<ID>();
		set<ID> setJobId = new set<ID>();
		set<ID> setContactId = new set<ID>();
		for (Volunteer_Recurrence_Schedule__c vrs : listVRS) {
			setVRSId.add(vrs.Id);
			setJobId.add(vrs.Volunteer_Job__c);
			setContactId.add(vrs.Contact__c);
		}
							
		// get all shifts of the jobs these vrs's are associated with
		list<Volunteer_Shift__c> listShift = new list<Volunteer_Shift__c>();
		listShift = [select Id, Duration__c, Start_Date_Time__c, Desired_Number_of_Volunteers__c, 
			Volunteer_Job__c from Volunteer_Shift__c
			where Volunteer_Job__c in :setJobId];
			
		// delete all Hours that aren't completed or canceled.
		DeleteListVRS(listVRS, true);
		
		// construct a map of Job to its associated list of VRS's
		map<ID, list<Volunteer_Recurrence_Schedule__c>> mapJobIdListVRS = new map<ID, list<Volunteer_Recurrence_Schedule__c>>();
		
		// put the VRS's on each job's list
		for (Volunteer_Recurrence_Schedule__c vrs : listVRS) {			
			list<Volunteer_Recurrence_Schedule__c> listVRSforJob = mapJobIdListVRS.get(vrs.Volunteer_Job__c);
			if (listVRSforJob == null) listVRSforJob = new list<Volunteer_Recurrence_Schedule__c>();
			listVRSforJob.add(vrs);
			mapJobIdListVRS.put(vrs.Volunteer_Job__c, listVRSforJob);				
		}
	
		// in order to avoid creating hours that already exist (completed or canceled),
		// create a set of shiftId|contactId tuples, which allows us to quickly see if we
		// already have an hours record for the given shift and contact.
		list<Volunteer_Hours__c> listHoursExisting = [select Id, Volunteer_Job__c, Volunteer_Recurrence_Schedule__c,
			Volunteer_Shift__c, Contact__c from
			Volunteer_Hours__c where Volunteer_Job__c in :setJobId and Contact__c in :setContactId];
		set<string> setShiftIdContactId = new set<string>();
		for (Volunteer_Hours__c hr : listHoursExisting) {
			setShiftIdContactId.add(hr.Volunteer_Shift__c + '|' + hr.Contact__c);
		}

		// create hours for these vrs's for each shift 				
		list<Volunteer_Hours__c> listHoursNew = new list<Volunteer_Hours__c>();
		for (Volunteer_Shift__c shift : listShift) {
			list<Volunteer_Recurrence_Schedule__c> listVRSforJob = mapJobIdListVRS.get(shift.Volunteer_Job__c);
			AssignVRSHours(shift, listVRSforJob, setShiftIdContactId, listHoursNew);
		}
		if (listHoursNew.size() > 0)
			insert listHoursNew;								
		
	}
	
    //******************************************************************************************************
	// for the specified shift, create VolunteerHours records for all volunteers
	// who have a recurring schedule which should include this shift.
	// note that it puts the hours on the provided list, and doesn't actually
	// save them to the database.
	public static void AssignVRSHours(
		Volunteer_Shift__c shift, 
		list<Volunteer_Recurrence_Schedule__c> listVRS, 
		set<string> setShiftIdContactId,
		list<Volunteer_Hours__c> listHoursNew
		) {
			
		if (listVRS == null) return; 

		// Strategy:
		// for the given shift, go through the list of VRS's
		// and create hours for the ones that match.
		
		// we decided not to limit the number of volunteers assigned
		//integer cDesiredVols = 1000;
		//if (shift.Desired_Number_of_Volunteers__c != null) 
		//	cDesiredVols = integer.valueOf(shift.Desired_Number_of_Volunteers__c);
		Date dtShift = shift.Start_Date_Time__c.Date();
		DateTime dtShiftEnd = shift.Start_Date_Time__c.addMinutes(integer.valueOf(shift.Duration__c * 60));
		integer nday = VOL_JRS.nDayOfWeek(dtShift);
		
		for (Volunteer_Recurrence_Schedule__c vrs : listVRS) {
		
			// exit if we've filled all the slots.
			//if (cDesiredVols <= 0) 
				//break;
	
			// for this jrs, what week should we treat this shift as
			integer nweek = VOL_JRS.nWeekOfDate(dtFirstOccurrenceInWeek(vrs, dtShift));
		
			list<boolean> listWhichDays = WhichDaysVRS(vrs);
			list<boolean> listWhichWeeks = WhichWeeksVRS(vrs);
			
			if (vrs.Weekly_Occurrence__c == null)
				continue;
			
			if ((listWhichWeeks[nweek] || 
					vrs.Weekly_Occurrence__c.contains('Every') ||
					(vrs.Weekly_Occurrence__c.contains('Alternate') && alternateWeekVRS(vrs, dtShift))) && 
				listWhichDays[nday] &&
				vrs.Schedule_Start_Date_Time__c != null &&
				dtShift >= vrs.Schedule_Start_Date_Time__c.Date() &&
				(vrs.Schedule_End_Date__c == null || vrs.Schedule_End_Date__c > dtShift)) {
					
				// we need to deal with the person already having hours on this shift
				// that might be completed, or canceled, or web signup.  
				// avoid creating another confirmed record.
				if (setShiftIdContactId.contains(shift.Id + '|' + vrs.Contact__c)) {
					continue;
				}
									
				// only take volunteers whose time fits in the shift time (to handle multiple shifts per day)
				Time tmVRS = vrs.Schedule_Start_Date_Time__c.Time();				
				DateTime dtVRSStart =  datetime.newInstance(dtShift, tmVRS);
				if (dtVRSStart < shift.Start_Date_Time__c  || dtVRSStart >= dtShiftEnd) {
					continue;					
				}	
					
				Volunteer_Hours__c hr = new Volunteer_Hours__c();
				hr.System_Note__c = label.labelVRSHoursCreatedSystemNote + ' ' + vrs.Name + '.';
				hr.Contact__c = vrs.Contact__c;
				hr.Hours_Worked__c = vrs.Duration__c;
				hr.Number_of_Volunteers__c = 1;
				if (vrs.Number_of_Volunteers__c != null && vrs.Number_of_Volunteers__c > 1)
					hr.Number_of_Volunteers__c = vrs.Number_of_Volunteers__c; 
				hr.Start_Date__c = dtShift;
				hr.End_Date__c = dtShift;
				hr.Status__c = (vrs.Volunteer_Hours_Status__c == null ? 'Confirmed' : vrs.Volunteer_Hours_Status__c);
				hr.Volunteer_Job__c = shift.Volunteer_Job__c;
				hr.Volunteer_Shift__c = shift.Id;	
				hr.Volunteer_Recurrence_Schedule__c = vrs.Id;	
				hr.Planned_Start_Date_Time__c = datetime.newInstance(shift.Start_Date_Time__c.date(), vrs.Schedule_Start_Date_Time__c.time());
				hr.Comments__c = vrs.Comments__c;
				listHoursNew.add(hr);
				//cDesiredVols--;
			}			 		
		}
		
		// we let the caller commit the new hours to the db.		
	}

    //******************************************************************************************************
	// returns whether the nweek of the specified date is an alternate week for this schedule
	public static boolean alternateWeekVRS(Volunteer_Recurrence_Schedule__c vrs, Date dt) {
		if (vrs.Schedule_Start_Date_Time__c == null) return false;
		Date dtStart = vrs.Schedule_Start_Date_Time__c.Date().toStartOfWeek();
		Date dtEnd = dt.toStartOfWeek();
		integer cdays = dtStart.daysBetween(dtEnd);
		integer nweeks = (cdays + 1) / 7;
		return math.mod(nweeks, 2) == 0 ? true : false;		
	}		
		
    //******************************************************************************************************
	// returns an array of booleans for which days are on the schedule.
	// note that you should index by nDay (ie, Mon = index 2).
	private static list<boolean> WhichDaysVRS (Volunteer_Recurrence_Schedule__c vrs) {
		list<boolean> listWhichDays = new boolean[] { false, false, false, false, false, false, false, false };
		boolean isSun = VOL_JRS.isSundayFirstOfWeek();
		
		if (vrs.Days_of_Week__c != null) {
			listWhichDays[isSun ? 1 : 7] = vrs.Days_of_Week__c.contains('Sunday');
			listWhichDays[isSun ? 2 : 1] = vrs.Days_of_Week__c.contains('Monday');
			listWhichDays[isSun ? 3 : 2] = vrs.Days_of_Week__c.contains('Tuesday');
			listWhichDays[isSun ? 4 : 3] = vrs.Days_of_Week__c.contains('Wednesday');
			listWhichDays[isSun ? 5 : 4] = vrs.Days_of_Week__c.contains('Thursday');
			listWhichDays[isSun ? 6 : 5] = vrs.Days_of_Week__c.contains('Friday');
			listWhichDays[isSun ? 7 : 6] = vrs.Days_of_Week__c.contains('Saturday');
		}
		return listWhichDays; 
	}

    //******************************************************************************************************
	// returns an array of booleans for which weeks are on the schedule.
	// note that you should index by nWeek (ie, first = index 1).
	private static list<boolean> WhichWeeksVRS(Volunteer_Recurrence_Schedule__c vrs) {
		list<boolean> listWhichWeeks = new boolean[] { false, false, false, false, false, false };
		if (vrs.Weekly_Occurrence__c != null) {
			listWhichWeeks[1] = vrs.Weekly_Occurrence__c.contains('1st');
			listWhichWeeks[2] = vrs.Weekly_Occurrence__c.contains('2nd');
			listWhichWeeks[3] = vrs.Weekly_Occurrence__c.contains('3rd');
			listWhichWeeks[4] = vrs.Weekly_Occurrence__c.contains('4th');
			listWhichWeeks[5] = vrs.Weekly_Occurrence__c.contains('5th');
		}
		return listWhichWeeks;
	}

    //******************************************************************************************************
	// given the current date, return the first date in that week that should be scheduled		
	private static Date dtFirstOccurrenceInWeek(Volunteer_Recurrence_Schedule__c vrs, Date dt) {
		list<boolean> listWhichDays = WhichDaysVRS(vrs);
		integer nday = VOL_JRS.nDayOfWeek(dt);
		integer n;
		for (n = 1; n < nday && n <= 7; n++) { 
			if (listWhichDays[n])
				break;
		}		
		return dt.addDays(n - nday);
	} 	
		
	
}