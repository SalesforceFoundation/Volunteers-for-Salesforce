// Written by David Habib, copyright (c) 2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

public with sharing class VOL_CTRL_BatchProgress {
	
    // properties for page
    public boolean batching { get; set; }
    public boolean batchRunning { get; set; }

    // object id passed in via parameter
    string objectId;
    id oid;

    // constructor
    public VOL_CTRL_BatchProgress() {
        batchRunning = false;

        // get parameter if any
        try {
            objectId = ApexPages.currentPage().getParameters().get('id');
            oid = objectId;
        } catch (exception e) {     
        }  
        
        if (oid != null) {
            batching = false;           
        } else {
            batching = true;
        }
    }

    public PageReference rollup() {
    	
    	VOL_BATCH_Recurrence r = new VOL_BATCH_Recurrence();
    	r.execute(null);
        batchRunning = true;
        return null;                
    }

    public PageReference cancel() {
        PageReference ref = new PageReference('/home/home.jsp');
        ref.setRedirect(true);
        return ref;
    }

}