// Written by David Habib, copyright (c) 2013 DJH Consulting, djhconsulting.com 
// This program is released under the GNU Affero General Public License, Version 3. http://www.gnu.org/licenses/

global abstract with sharing class PageControllerBase {
	
  	private ComponentControllerBase componentController;
	
  	public virtual ComponentControllerBase getComponentController() {
    	return componentController;
  	}

  	public virtual void setComponentController(ComponentControllerBase compController) {
    	componentController = compController;
  	}
	
  	public PageControllerBase getThis() {
    	return this;
  	}
	
	abstract global string getStrSoql();
	
	public list<string> strFields { get; set; } 
	
	public string strNameField { get; set; }
	
	public string strObjectType { get; set; }

	abstract global PageReference NewItem();
	
	public SoqlListView ctrlSoqlListView {
		get {
			if (ctrlSoqlListView == null) {
				ctrlSoqlListView = (SoqlListView) getComponentController();
			}
			return ctrlSoqlListView;
		}
		set;
	}
	
	public virtual PageReference EditItem(ID idItem) {
		return new PageReference('/' + idItem + '/e?retURL=' + ApexPages.currentPage().getURL());
	}	

}