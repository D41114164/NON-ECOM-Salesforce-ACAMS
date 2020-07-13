/**
 * @ Descritpion: display asset view when user navigate to the cc order record detail page
 * @ source: E2E new feature - asset functionality row 27
 * @ Date: July 12, 2020 Rui
 */
public with sharing class FSIT_AssetViewCCOrderController {

    // define assign asset map, order id, asset list
    public Map<String, List<Asset>> assignedAssetMap {get; set;} 

    // define unassign asset mpa, <order id, asset list>
    public Map<String, List<Asset>> unassignedAssetMap {get; set;} 

    // define inactive asset map, <order ids, asset List>
    public Map<String, List<Asset>> inactivedAssetMap {get; set;} 

    // define sku asset map, <sku,asset list>
    public Map<String, List<Asset>> allAssetMap {get; set;} 

    // define search text
    public String searchText {get; set{searchText = value;}}

    // define select asset type
    public String assetTypes {get; set;}

    // record id
    public Id sobjectId {get;set;}

    // set all asset list
    public List<Asset> assetList {get; set;}

    // set sku name list
    public Set<String> skuSet {get; set;}

    // sku - product id mapping
    public Map<String, Id> skuProductIdMap {get; set;}

    // set three size maps
    public Map<String, Decimal> allAssetSize {get; set;}
    public Map<String, String> productNameSize {get; set;}
    public Map<String, Decimal> assignedAssetSize {get; set;}
    public Map<String, Decimal> unassignedAssetSize {get; set;}
    public Map<String, Decimal> inactiveAssetSize {get; set;}

    // set val for total asset #
    public Decimal totalAssets {get; set;}

    // displaying asset list
    public List<Asset> displayAssetList {get; set;}
    
    
    public FSIT_AssetViewCCOrderController(ApexPages.StandardController stdController) {
        // constructor init list/maps
        skuProductIdMap = new Map<String, Id>();

        assignedAssetMap = new Map<String, List<Asset>>();
        assignedAssetSize = new Map<String, Decimal>();

        unassignedAssetMap = new Map<String, List<Asset>>();


        inactivedAssetMap = new Map<String, List<Asset>>();


        allAssetMap = new Map<String, List<Asset>>();
        allAssetSize = new Map<String, Decimal>();
        productNameSize = new Map<String,String>();
        assignedAssetSize = new Map<String, Decimal>();
        unassignedAssetSize = new Map<String, Decimal>();

        inactiveAssetSize = new Map<String, Decimal>();

        sobjectId = stdController.getId();
        
        skuSet = new Set<String>();

        totalAssets = 0;

        displayAssetList = new List<Asset>();
    }

    // define init funciton to set all maps
    public void dataInit(){
        
        if(sobjectId != null){
            assetList = [
                SELECT Id, Name,CC_Product__c,CC_Product__r.ccrz__SKU__c,Status__c,Assignee__c,CC_Order__c,CC_Product__r.Name,Product_Level_1__c,Product_Level_2__c,Product_Level_3__c,CurrentExpirationDate__c,InstallDate 
                FROM Asset 
                WHERE CC_Order__c =: sobjectId 
                ORDER BY CC_Product__r.ccrz__SKU__c 
                ];

            for(Asset ast : assetList){
                if(ast.CC_Product__c != null && ast.CC_Product__r.ccrz__SKU__c != null){
                    if(!skuSet.contains(String.valueOf(ast.CC_Product__r.ccrz__SKU__c))){
                        skuSet.add(String.valueOf(ast.CC_Product__r.ccrz__SKU__c));
                    }
                }
            }
            
            if(assetList != null && assetList.size() > 0){
                
                // init all asset mapping
                for(String s : skuSet){
                    allAssetMap.put(s, new List<Asset>());
                    assignedAssetMap.put(s, new List<Asset>());
                    unassignedAssetMap.put(s, new List<Asset>());
                    inactivedAssetMap.put(s, new List<Asset>());
                }

                for(Asset ast : assetList){
                    if(ast.CC_Product__c != null && ast.CC_Product__r.ccrz__SKU__c != null && allAssetMap.keySet() != null && allAssetMap.keySet().contains(String.valueOf(ast.CC_Product__r.ccrz__SKU__c))){
                        allAssetMap.get(String.valueOf(ast.CC_Product__r.ccrz__SKU__c)).add(ast);
                    }
                    // else if(ast.CC_Product__c != null && ast.CC_Product__r.ccrz__SKU__c != null && allAssetMap.get(String.valueOf(ast.CC_Product__r.ccrz__SKU__c)) == null){
                    //     List<Asset> astList = new List<Asset>();
                    //     astList.add(ast);
                    //     allAssetMap.put(String.valueOf(ast.CC_Product__r.ccrz__SKU__c), astList);
                    // }
                    if(ast.CC_Product__c != null && ast.CC_Product__r.ccrz__SKU__c != null){
                        skuProductIdMap.put(ast.CC_Product__r.ccrz__SKU__c,ast.CC_Product__c);
                    }
                }
                
                if(allAssetMap != null && allAssetMap.size() > 0){
                    for(String s : allAssetMap.keySet()){
                        if(allAssetMap.get(s) != null){
                            allAssetSize.put(s,allAssetMap.get(s).size());
                            productNameSize.put(s,allAssetMap.get(s)[0].CC_Product__r.Name);
                            totalAssets += allAssetMap.get(s).size();
                        }
                    }
                }
                

                //init assigned asset map
                for(Asset ast : assetList){
                    if(ast.Assignee__c != null){
                        if(ast.CC_Product__c != null && ast.CC_Product__r.ccrz__SKU__c != null && assignedAssetMap.keySet() != null  && assignedAssetMap.keySet().contains(ast.CC_Product__r.ccrz__SKU__c)){
                            assignedAssetMap.get(String.valueOf(ast.CC_Product__r.ccrz__SKU__c)).add(ast);
                        }
                        // else if(ast.CC_Product__c != null && ast.CC_Product__r.ccrz__SKU__c != null && assignedAssetMap.get(String.valueOf(ast.CC_Product__r.ccrz__SKU__c)) == null){
                        //     List<Asset> astList = new List<Asset>();
                        //     astList.add(ast);
                        //     assignedAssetMap.put(String.valueOf(ast.CC_Product__r.ccrz__SKU__c), astList);
                        // }
                    }
                    // else{
                    //     List<Asset> astList = new List<Asset>();
                    //     assignedAssetMap.put(String.valueOf(ast.CC_Product__r.ccrz__SKU__c),astList);
                    // }

                }

                if(assignedAssetMap != null && assignedAssetMap.size() > 0){
                    for(String s : assignedAssetMap.keySet()){
                        assignedAssetSize.put(s, assignedAssetMap.get(s).size());
                    }
                }

                //init unassigned asset map
                for(Asset ast : assetList){
                    if(ast.Assignee__c == null && ast.CC_Product__c != null){
                        if(ast.CC_Product__c != null && ast.CC_Product__r.ccrz__SKU__c != null && unassignedAssetMap.keySet() != null  && unassignedAssetMap.keySet().contains(ast.CC_Product__r.ccrz__SKU__c)){
                            unassignedAssetMap.get(String.valueOf(ast.CC_Product__r.ccrz__SKU__c)).add(ast);
                        }
                        // else if(ast.CC_Product__c != null && ast.CC_Product__r.ccrz__SKU__c != null &&  unassignedAssetMap.get(String.valueOf(ast.CC_Product__r.ccrz__SKU__c)) == null){
                        //     List<Asset> astList = new List<Asset>();
                        //     astList.add(ast);
                        //     unassignedAssetMap.put(String.valueOf(ast.CC_Product__r.ccrz__SKU__c), astList);
                        // }
                    }
                    // else{
                    //     List<Asset> astList = new List<Asset>();
                    //     unassignedAssetMap.put(String.valueOf(ast.CC_Product__r.ccrz__SKU__c),astList);
                    // }
                }

               
                if(unassignedAssetMap != null && unassignedAssetMap.size() > 0){
                    for(String s : unassignedAssetMap.keySet()){
                        if(unassignedAssetMap.get(s) != null){
                            unassignedAssetSize.put(s, unassignedAssetMap.get(s).size());
                        }
                    }
                }

                //init inactive asset map
                for(Asset ast : assetList){
                    if(ast.Status__c != null && ast.Status__c == 'Inactive'){
                        if(ast.CC_Product__c != null  &&  ast.CC_Product__r.ccrz__SKU__c != null && inactivedAssetMap.keySet() != null  && inactivedAssetMap.keySet().contains(ast.CC_Product__r.ccrz__SKU__c)){
                            inactivedAssetMap.get(String.valueOf(ast.CC_Product__r.ccrz__SKU__c)).add(ast);
                        }
                        
                        // else if(ast.CC_Product__c != null && ast.CC_Product__r.ccrz__SKU__c != null && inactivedAssetMap.get(String.valueOf(ast.CC_Product__r.ccrz__SKU__c)) == null){
                        //     List<Asset> astList = new List<Asset>();
                        //     astList.add(ast);
                        //     inactivedAssetMap.put(String.valueOf(ast.CC_Product__r.ccrz__SKU__c), astList);
                        // }
                    }
                    // else{
                    //     if(inactivedAssetMap.values() == null || inactivedAssetMap.values().size() <= 0){
                    //         List<Asset> astList = new List<Asset>();
                    //         inactivedAssetMap.put(String.valueOf(ast.CC_Product__r.ccrz__SKU__c),astList);
                    //     }
                    // }
                }
               
                if(inactivedAssetMap != null && inactivedAssetMap.size() > 0){
                    for(String s : inactivedAssetMap.keySet()){
                        inactiveAssetSize.put(s, inactivedAssetMap.get(s).size());
                    }
                }



            }
        }
        
    }

    // filter by asset filter first then filter by product name
    public PageReference filterWithProductSKU(){
        // clear the input
        assetTypes = '';

        if(sobjectId != null){
            displayAssetList = [
                SELECT Id, Name,CC_Product__c,CC_Product__r.ccrz__SKU__c,Status__c,Assignee__c,CC_Order__c,CC_Product__r.Name,CreatedDate,Product_Level_1__c,Product_Level_2__c,Product_Level_3__c,CurrentExpirationDate__c,InstallDate 
                FROM Asset 
                WHERE CC_Product__c =: skuProductIdMap.get(searchText) AND CC_Order__c =: sobjectId 
                ORDER BY CreatedDate
            ];
        }

        return null;

    }

    public PageReference runSearch(){
        /*
        displayAssetList = [
                SELECT Id, Name,CC_Product__c,CC_Product__r.ccrz__SKU__c,Status__c,Assignee__c,CC_Order__c,CC_Product__r.Name,CreatedDate  
                FROM Asset 
                WHERE CC_Product__c =: skuProductIdMap.get(searchText) AND CC_Order__c =: sobjectId 
                ORDER BY CreatedDate
            ];
            */

            if(assetTypes == 'Assigned_Asset'){
                displayAssetList = assignedAssetMap.get(searchText);
            }

            else if(assetTypes == 'Unassigned_Asset'){
                displayAssetList = unassignedAssetMap.get(searchText);
            }

            else if(assetTypes == 'Inactive_Asset'){
                displayAssetList = inactivedAssetMap.get(searchText);
            }

        return null;
    }

}