public with sharing class ACAMSCertAppTriggerHandler extends CCAviTriggerHandler {

    private List<Certification_Application__c> newList = (List<Certification_Application__c>) Trigger.new;
    private List<Certification_Application__c> oldList = (List<Certification_Application__c>) Trigger.old;
    private Map<Id, Certification_Application__c> newMap = (Map<Id, Certification_Application__c>) Trigger.newMap;
    private Map<Id, Certification_Application__c> oldMap = (Map<Id, Certification_Application__c>) Trigger.oldMap;

    protected override void beforeInsert() {
        Set<Id> contactIds = new Set<Id>();
        for (Certification_Application__c certApp : newList) {
            if (certApp.Application_Type__c == ACAMSUtil.CGSS) {
                certApp.CGSS_Check__c = true;
            }
            if (certApp.Contact__c != null) {
                contactIds.add(certApp.Contact__c);
            }
        }
        if (!ACAMSCertAppHelper.isAssetUpdated) {
            ACAMSCertAppHelper.UpdateAsset(newList);
        }
        //linkCertAppsToAssets(contactIds);
    }

    protected override void afterInsert() {
        if (!ACAMSCertAppHelper.isAssetUpdated) {
            ACAMSCertAppHelper.UpdateAsset(newList);
        }
        if (!ACAMSCertAppHelper.isLocaleUpdated) {
            ACAMSCertAppHelper.UpdateLocaleOnContact(Trigger.new);
        }
    }

    protected override void beforeUpdate() {
        Set<Id> contactIds = new Set<Id>();
        for (Certification_Application__c certApp : newMap.values()) {
            if (certApp.Application_Type__c == ACAMSUtil.CGSS) {
                certApp.CGSS_Check__c = true;
            } else {
                certApp.CGSS_Check__c = false;
            }
            if (certApp.Contact__c != null) {
                contactIds.add(certApp.Contact__c);
            }
        }
        if (!ACAMSCertAppHelper.isAssetUpdated) {
            ACAMSCertAppHelper.UpdateAsset(newList);
        }
        //linkCertAppsToAssets(contactIds);
    }

    protected override void afterUpdate() {
        if (!ACAMSCertAppHelper.isAssetUpdated) {
            ACAMSCertAppHelper.UpdateAsset(newList);
        }
        if (!ACAMSCertAppHelper.isLocaleUpdated) {
            ACAMSCertAppHelper.UpdateLocaleOnContact(Trigger.new);
        }
    }

    private void linkCertAppsToAssets(Set<Id> contactIds) {
        List<Asset> assets = ACAMSAssetDAO.getAssetsByContactIds(contactIds);
        Map<Id, List<Asset>> idToAssetMap = new Map<Id, List<Asset>>();
        for (Asset asset : assets) {
            if (idToAssetMap.containsKey(asset.Assignee__c)) {
                idToAssetMap.get(asset.Assignee__c).add(asset);
            } else {
                idToAssetMap.put(asset.Assignee__c, new List<Asset>{
                        asset
                });
            }
        }

        for (Certification_Application__c certApp : this.newList) {
            if (idToAssetMap.containsKey(certApp.Contact__c)) {
                List<Asset> contactAssets = idToAssetMap.get(certApp.Contact__c);
                for (Asset asset : contactAssets) {
                    if (asset.Name.contains(ACAMSUtil.CERTIFICATION)) {
                        if ((certApp.Application_Type__c == ACAMSUtil.CAMS && asset.Name.contains(ACAMSUtil.CAMS)) ||
                                (certApp.Application_Type__c == ACAMSUtil.CGSS &&
                                        asset.Name.contains(ACAMSUtil.CGSS)) ||
                                (certApp.Application_Type__c.contains(ACAMSUtil.ADVANCED) &&
                                        asset.Name.contains(ACAMSUtil.ADVANCED))) {
                            if (certApp.Asset__c == null) {
                                certApp.Asset__c = asset.Id;
                            }
                        }
                    }
                }
            }
        }
    }
}