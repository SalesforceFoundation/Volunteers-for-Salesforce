// Written by David Habib, copyright (c) 2010-2014 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

@isTest
public with sharing class VOL_CTRL_BatchProgress_TEST {

    //--------------------TEST METHOD------------------------
    public static testMethod void batchStatusBarTest(){
        GW_CTRL_BatchJobsProgress controller = new GW_CTRL_BatchJobsProgress();
        controller.getBatchJobs();
        controller.numberOfJobs = 10;
        system.assertEquals(10, controller.numberOfJobs);
        controller.batchComponentLabel = 'my label';
        system.assertEquals('my label', controller.batchComponentLabel);
        
    }
    
    public static testMethod void testRollup() {
        VOL_CTRL_BatchProgress controller = new VOL_CTRL_BatchProgress();
        system.assertEquals(true, controller.batching);
        system.assertEquals(false, controller.batchRunning);
        system.assertNotEquals(null, controller.cancel());
        system.assertEquals(null, controller.rollup());
   }

}