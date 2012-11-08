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

    // TEST METHOD
    public static testMethod void testRollup() {
        VOL_CTRL_BatchProgress controller = new VOL_CTRL_BatchProgress();
        system.assertEquals(true, controller.batching);
        system.assertEquals(false, controller.batchRunning);
        system.assertNotEquals(null, controller.cancel());
        // specifically not calling rollup, since we'll test the batch class seperately,
        // and we don't need to see its potential errors here!
   }
}