// Written by David Habib, copyright (c) 2010-2014 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class VOL_SharedCodeAPI25 {

	// global utility to load up an existing object and copy it to the provided object
	// this code moved to VOL_SharedCodeAPI25 to keep it running with api 25
	// behavior, which is that the Sites Guest User Profile can still edit
	// this new contact object we created.  Under api 31, the contact object is readonly.
	// we needed to update the rest of the VOL_SharedCode class to api 31 to handle state & country picklists.	
	public static void LoadAndCopyObject(ID id, SObject sobj) {
		
		// get the fields for the object
		Schema.DescribeSObjectResult des = sobj.getSObjectType().getDescribe();
		Map<String, Schema.SObjectField> mapS = des.fields.getMap().clone();
		// avoid any of the API version 30 compound fields
		// we only worry about Contact ones, since all callers are giving us contacts to copy.
		mapS.remove('mailingaddress');
		mapS.remove('otheraddress');
		list<string> listStrFields = new list<string>();
		listStrFields.addAll(mapS.keySet());  		
		
        string strSoql = 'select ';
        string strComma = '';
        for (string strF : listStrFields) {
        	strSoql += strComma + strF;
        	strComma = ', ';
        }
        strSoql += ' from ' + des.getName() + ' where Id = :id ';
        strSoql += ' limit 1';      
        list<SObject> listSObj = Database.Query(strSoql); 
        
        if (listSObj.size() > 0) {        	
        	SObject sobjT = listSObj[0];
            //  now copy over all the non-null fields from the form's contact to the existing contact.
            for (string strF : listStrFields) {
            	if (sobjT.get(strF) != null) {
            		try {
            			sobj.put(strF, sobjT.get(strF));
            		} catch(exception ex) { 
            			
            		}
            	}
            }
        }
	}

}