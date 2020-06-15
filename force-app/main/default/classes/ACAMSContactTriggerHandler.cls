public class ACAMSContactTriggerHandler extends CCAviTriggerHandler {
    private List<Contact> newList;
    private List<Contact> oldList;
    private Map<Id, Contact> newMap;
    private Map<Id, Contact> oldMap;
    
    
    public ACAMSContactTriggerHandler() {
        super();
        this.newList = (List<Contact>) Trigger.new;
        this.oldList = (List<Contact>) Trigger.old;
        this.newMap = (Map<Id, Contact>) Trigger.newMap;
        this.oldMap = (Map<Id, Contact>) Trigger.oldMap;
 
    }
      public override void afterInsert() {
 	  	CreatePortalUserAccount(this.newList);

    }
 
    
     public static void CreatePortalUserAccount(List<contact>con3){
    		List<user> lstuser = new list<user>();
            List<user> lstuser2 = new list<user>();
            Map<String, Contact> ContactMap = new Map<String, Contact>();
            set<string> SetnewEmail = new set<String>();
            set<string> SetOldEmail = new set<String>();
            set<string> ConEmail = new set<String>();
			User objuser;
         	User drupalIntegration = ACAMSUserDAO.getDrupalIntegrationUser();
			if (UserInfo.getUserId() != drupalIntegration.Id) {
        	for(Contact Objcontact:con3){
            	 System.debug('ownerId:'+objcontact.ownerid);  
                 if(Objcontact.email != null ){
					 objuser=new User();
                     objuser.ContactId = Objcontact.id;
                     objuser.Lastname = Objcontact.lastname;
                      if(Objcontact.Firstname != null){
                      	objuser.FirstName=Objcontact.Firstname;
                      	objuser.alias = Objcontact.Firstname.substring(0,2)+ Objcontact.lastname.substring(0,3);
                        objuser.communityNickname = Objcontact.Firstname.substring(0,2)+Objcontact.lastname.substring(0,3)+'_'+Math.random();
                      }
                      else{
                        objuser.alias = Objcontact.lastname.substring(0,5);
                        objuser.communityNickname = Objcontact.lastname.substring(0,5)+'_'+Math.random();
                      }
                     objuser.Email = Objcontact.email;
                     objuser.Username = Objcontact.email;
                     objuser.ProfileId = ACAMSUserDAO.getB2BProfile().Id;
                     objuser.isMigrated__c = true;
                     objuser.IsActive = true;
                     objuser.TimeZoneSidKey = 'America/New_York';
                     objuser.LocaleSidKey='en_US';
                     objuser.EmailEncodingKey='ISO-8859-1';
                     objuser.LanguageLocaleKey='en_US';
                     lstuser.add(objuser);//Adding the users to the list
                     System.debug('==lstuser==>'+lstuser);
                 
                }//End of if   
             }//End of for
             if(lstuser.size()>0 && !test.isRunningTest()){
             	insert lstuser;
                }//End of inserting users  
             if(!test.isRunningTest()){
                    for(User objUs:lstuser){
                    	system.debug('Passworset:  '+objUs.Member_Number__c);
                        if(objUs.Member_Number__c != null)
                        System.setPassword(objUs.id,objUs.Member_Number__c);
                 }
             }
           
            }
    }
    

}