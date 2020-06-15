public class ACAMSAssetTriggerHandler extends CCAviTriggerHandler {

    private List<Asset> newList;
    private List<Asset> oldList;
    private Map<Id, Asset> newMap;
    private Map<Id, Asset> oldMap;
    private Boolean isInsert;
    private Boolean isUpdate;
    public static Boolean isLMSUserCreated = false;
    private static boolean isRecursiveChapterCheck = false;
    private static boolean isRecursiveBeforeUpdate = false;
   	public static set<Id> assetIds=new set<Id>();

    
    public ACAMSAssetTriggerHandler() {
        super();
        this.newList = (List<Asset>) Trigger.new;
        this.oldList = (List<Asset>) Trigger.old;
        this.newMap = (Map<Id, Asset>) Trigger.newMap;
        this.oldMap = (Map<Id, Asset>) Trigger.oldMap;
        this.isInsert =  Trigger.isInsert;
        this.isUpdate =  Trigger.isUpdate;
    }
      public override void afterInsert() {
          if(!ACAMSBeckerLMSTriggerHandler.isAssetEnrollmentCreated){
              if (!isLMSUserCreated ){
          UpsertLMSUser(this.newList);
              }
           ACAMSBeckerLMSTriggerHandler.UpsertAssetEnrollments(this.newMap.KeySet(), NULL,this.isInsert,this.isUpdate);
          }
    }
    public override void afterUpdate() {
        if((!ACAMSBeckerLMSTriggerHandler.isAssetEnrollmentUpdated || !ACAMSBeckerLMSTriggerHandler.isAssetEnrollmentCreated)){
        if (!isLMSUserCreated){
            UpsertLMSUser(this.newList);
        }
            ACAMSBeckerLMSTriggerHandler.UpsertAssetEnrollments(this.newMap.KeySet(), this.oldMap,this.isInsert ,this.isUpdate);
        }
              AcamsHelperMethod(this.newList,this.oldList);

    }
      public static void UpsertLMSUser(List<Asset> newAssets) {
    if(isRecursiveChapterCheck == false){
    isRecursiveChapterCheck = true;
        system.debug('AssetHelperRestructure, UpsertLMSUser Method started $$$$$');
        system.debug('debug--UpsertLMSUser$$$$$$$$$$$---');
        try{
            

            Set<Id> contactIds = new Set<Id>();
            Map<Id, User> contactUserMap = new Map<Id, User>();
            List<LMSUtility.LMSUserRequest> lmsuserList = new List<LMSUtility.LMSUserRequest>();

            System.debug('*****AssetHelperRestructure.UpsertLMSUser.newAssets: ' + newAssets);

            if (newAssets != NULL && newAssets.size() > 0){
                for(Asset newA : newAssets){
                    if (newA.AccountId != NULL){
                        isLMSUserCreated = true;
                        contactIds.add(newA.AccountId);
                    }
                }
                System.debug('*****AssetHelperRestructure.UpsertLMSUser.contactIds: ' + contactIds);

                if (contactIds.size() > 0){
                    for(Account c : [SELECT Id, FirstName,personemail, LastName FROM Account WHERE Id IN: contactIds]){
                        LMSUtility.LMSUserRequest lmsuser = new LMSUtility.LMSUserRequest();
                        lmsuser.contactId = c.Id;
                        lmsuser.firstName = c.FirstName;
                        lmsuser.lastName = c.LastName;
                        lmsuser.language = '';
                        lmsuser.enabled = true;
                        lmsuserList.add(lmsuser);
                    }
                }
                System.debug('*****AssetHelperRestructure.UpsertLMSUser.contactIds: ' + contactIds);

                if (contactIds.size() > 0){
                    for(User u : [SELECT Id,ContactId,AccountId, Username, LMS_Role__c, TimeZoneSidKey  FROM User WHERE AccountId IN: contactIds]){
                        contactUserMap.put(u.contactId, u);
                    }
                    for(LMSUtility.LMSUserRequest lmsU : lmsuserList){
                        if (contactUserMap.containsKey(lmsU.contactId)){
                            User u = contactUserMap.get(lmsU.contactId);
                            lmsU.username = u.Username;
                            lmsU.role = u.LMS_Role__c;
                            lmsU.timezone = ''; //lmsU.timezone = u.TimeZoneSidKey; -- Waiting for Timezone Integration
                        }
                    }
                    System.debug('*****AssetHelperRestructure.UpsertLMSUser.contactUserMap: ' + contactUserMap);
                }
            }
            System.debug('*****AssetHelperRestructure.UpsertLMSUser.lmsuserList: ' + lmsuserList);

            if (lmsuserList.size() > 0)
                CalloutUtility.SendRequest('UserIntegration', true, LMSUtility.BuildJson(lmsuserList));
        }
        catch(Exception ex){
           
        }
        
        system.debug('AssetHelperRestructure, UpsertLMSUser Method started $$$$$');
    }
    }
     public static void AcamsHelperMethod(list<asset> newids,list<asset> oldids){
         system.debug('debug--Acams_helper_metho_RT$$$$$$$$$$$---');
           if(isRecursiveBeforeUpdate == false){
              isRecursiveBeforeUpdate = true ;
        for(asset astn: newids){
            for(asset asto:oldids){
                system.debug('Old values'+asto.status__c);
                system.debug('New values'+astn.status__c);
                
                if(astn.status__c != asto.status__c){
                    if(astn.status__c == 'Inactive' && (astn.Enterprise_Product_HL__c =='ENTLATAM-S' || astn.Enterprise_Product_HL__c =='ENTLATAM-P')){
                        assetIds.add(astn.id);
                    }
                }
            }
        }
        List<BeckerLMS_Enrollment__c> BlmsList = new List<BeckerLMS_Enrollment__c>();
         List<BeckerLMS_Enrollment__c> UpdateBlmsList = new List<BeckerLMS_Enrollment__c>();
        BlmsList=[select id, name, asset__c from BeckerLMS_Enrollment__c where status__c !='Completed' AND asset__c IN:assetIds ];
        try{ for(BeckerLMS_Enrollment__c b:BlmsList){
            b.status__c = 'Cancelled';
            UpdateBlmsList.add(b);
        }
          if(UpdateBlmsList.size()>0){
        update UpdateBlmsList;
    }
           }
        catch(DmlException e) {
    System.debug('The following exception has occurred: ' + e.getMessage());
   }
           }
    }
    
    
    
}