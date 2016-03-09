public class programmeController {

    public List<Campaign> theCampaigns  {get;set;}
    
    public programmeController(){
    	theCampaigns = [SELECT Id, Name FROM Campaign];
    }
    
}