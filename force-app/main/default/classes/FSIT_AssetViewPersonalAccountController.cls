/**
 * @Decription create Asset view page based on "Asset Grouping" values
 * @Source: https://app.smartsheet.com/sheets/7jJVh96vC5pQQRRm9VvGWW7rf4454f9jcC7V2fp1?view=grid row 30
 * @Date: July 8, 2020 Rui
 */

public class FSIT_AssetViewPersonalAccountController {
    public List<Asset> pageAssetList {get ;set;}
    public List<Asset> displayAssetList {get; set;}
    public List<Account> acctList {get; set;}
    public String assetGroupingValue {get; set{assetGroupingValue = value;}}
    public String searchText {get; set;}
    public String name { get; set{name = value;} }

    //setup assetGrouprecords,listofasset map
    public Map<String, List<Asset>> assetMap {get; set;}
    public List<ACAMSAssetSetting__mdt> assetSetting {get; set;}
    public Set<String> keyValues {get; set;}
    public Map<String, Integer> groupNameSizeMap {get; set;}
    public Id sobjectId {get;set;}


    public FSIT_AssetViewPersonalAccountController(ApexPages.StandardController stdController) {
        assetMap = new Map<String, List<Asset>>();
        groupNameSizeMap = new Map<String, Integer> ();
        displayAssetList = new List<Asset>();
        sobjectId = stdController.getId();
        System.debug('sssssssssobjectId---->'+sobjectId);
    }

    public void dataInit(){
        //init
        if(sobjectId != null){
            pageAssetList=[SELECT Id, Name,Assignee__c,InstallDate,Assignee__r.AccountId,Assignee__r.Name,Status__c,CC_Product__r.Name,Product_Level_1__c,Product_Level_2__c,Product_Level_3__c,CurrentExpirationDate__c,CancelDate__c FROM Asset
            WHERE Assignee__r.AccountId =:sobjectId AND CancelDate__c = null AND Product_Level_2__c != NULL AND Status__c = 'Active' ORDER BY CurrentExpirationDate__c];
        }
        else{
            pageAssetList=[SELECT Id, Name,Assignee__c,InstallDate,Assignee__r.Name,Status__c,CC_Product__r.Name,Product_Level_1__c,Product_Level_2__c,Product_Level_3__c,CurrentExpirationDate__c,CancelDate__c FROM Asset
            WHERE CancelDate__c = null AND Product_Level_2__c != NULL AND Status__c = 'Active' ORDER BY CurrentExpirationDate__c];
        }
        assetSetting = [SELECT Id, Asset_Grouping__c FROM ACAMSAssetSetting__mdt LIMIT 1];
        List<String> assetGroupingValues = String.valueOf(assetSetting[0].Asset_Grouping__c).split(';');

        
        // put asset id, number to the map
        if(pageAssetList != null && assetSetting != null){
            for(String s : assetGroupingValues){
                assetMap.put(s,  new List<Asset>());
            }

            for(Asset a : pageAssetList){
                if(assetGroupingValues.contains(a.Product_Level_2__c)){
                    if(assetMap.keySet().contains(a.Product_Level_2__c)){
                        assetMap.get(a.Product_Level_2__c).add(a);
                    }
                }
            }

            for(String s : assetMap.keySet()){
                groupNameSizeMap.put(s, assetMap.get(s).size());
            }
            keyValues = groupNameSizeMap.keySet();
        }
        
    }

    public void displayAssetsByGroupName(){
        displayAssetList = assetMap.get(assetGroupingValue);
    }

    public PageReference runSearch(){
        //ApexPages.currentPage() != null && ApexPages.currentPage().getParameters() != null && ApexPages.currentPage().getParameters().get('id')
        if(sobjectId != null){
            displayAssetList = [SELECT Id, Name,Assignee__c,InstallDate,Assignee__r.Name,Assignee__r.AccountId,CC_Product__r.Name,Product_Level_1__c,Product_Level_2__c,Product_Level_3__c,CurrentExpirationDate__c,CancelDate__c,Status__c FROM Asset
            WHERE Assignee__r.AccountId=:sobjectId AND CancelDate__c = null AND Product_Level_2__c != NULL AND Product_Level_2__c =: assetGroupingValue AND Status__c = 'Active' AND Name LIKE : '%'+searchText+'%' ORDER BY CurrentExpirationDate__c];
        }

        else{
            displayAssetList = [SELECT Id, Name,Assignee__c,InstallDate,Assignee__r.Name,CC_Product__r.Name,Product_Level_1__c,Product_Level_2__c,Product_Level_3__c,CurrentExpirationDate__c,CancelDate__c,Status__c FROM Asset
            WHERE CancelDate__c = null AND Product_Level_2__c != NULL AND Product_Level_2__c =: assetGroupingValue AND Status__c = 'Active' AND Name LIKE : '%'+searchText+'%' ORDER BY CurrentExpirationDate__c];
        }
        return null;
    }
}