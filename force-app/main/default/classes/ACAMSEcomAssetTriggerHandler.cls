public with sharing class ACAMSEcomAssetTriggerHandler extends CCAviTriggerHandler {

    private List<Asset> newList;
    private List<Asset> oldList;
    private Map<Id, Asset> newMap;
    private Map<Id, Asset> oldMap;

    public ACAMSEcomAssetTriggerHandler() {
        this.newList = (List<Asset>) Trigger.new;
        this.oldList = (List<Asset>) Trigger.old;
        this.newMap = (Map<Id, Asset>) Trigger.newMap;
        this.oldMap = (Map<Id, Asset>) Trigger.oldMap;
    }

    public override void beforeInsert() {
        createMasterAssets();
    }

    public override void afterInsert() {
        updatePersonAccountStatuses();
    }

    public override void beforeUpdate() {
        createMasterAssets();
    }
    public override void afterUpdate() {
        updatePersonAccountStatuses();
    }

    private void createMasterAssets() {
        Set<Id> contactIds = new Set<Id>();
        for (Asset asset : newList) {
            if (asset.Assignee__c != null && (oldMap == null ||
                    (oldMap.get(asset.Id).Assignee__c != asset.Assignee__c)) && !isMasterAsset(asset)) {
                contactIds.add(asset.Assignee__c);
            }
        }
        if (!contactIds.isEmpty()) {
            List<Contact> contacts = [
                    SELECT Id, AccountId
                    FROM Contact
                    WHERE Id IN :contactIds
            ];
            Map<Id, Id> contactToAccountIdsMap = new Map<Id, Id>();
            for (Contact contact : contacts) {
                contactToAccountIdsMap.put(contact.Id, contact.AccountId);
            }
            List<Asset> masterAssets = [
                    SELECT Id, Name, Assignee__c
                    FROM Asset
                    WHERE Assignee__c IN :contactIds
                    AND ParentId = NULL
                    AND Status__c = NULL
            ];
            Map<Id, List<Asset>> assigneeToMasterAssetsMap = new Map<Id, List<Asset>>();
            for (Asset asset : masterAssets) {
                if (asset.Assignee__c != null) {
                    if (assigneeToMasterAssetsMap.containsKey(asset.Assignee__c)) {
                        assigneeToMasterAssetsMap.get(asset.Assignee__c).add(asset);
                    } else {
                        assigneeToMasterAssetsMap.put(asset.Assignee__c, new List<Asset>{asset});
                    }
                }
            }
            List<Asset> masterAssetsToInsert = new List<Asset>();
            for (Asset asset : newList) {
                if (!assigneeToMasterAssetsMap.containsKey(asset.Assignee__c)) {
                    Asset masterAsset = new Asset(
                            Name = asset.Name,
                            Assignee__c = asset.Assignee__c,
                            AccountId = asset.AccountId,
                            ContactId = asset.Assignee__c,
                            Status__c = null
                    );
                    masterAssetsToInsert.add(masterAsset);
                } else {
                    Boolean masterFound = false;
                    for (Asset masterAsset : assigneeToMasterAssetsMap.get(asset.Assignee__c)) {
                        if (asset.Name == masterAsset.Name) {
                            masterFound = true;
                            break;
                        }
                    }
                    if (!masterFound) {
                        Asset masterAsset = new Asset(
                                Name = asset.Name,
                                Assignee__c = asset.Assignee__c,
                                AccountId = contactToAccountIdsMap.get(asset.Assignee__c),
                                ContactId = asset.Assignee__c,
                                Status__c = null
                        );
                        masterAssetsToInsert.add(masterAsset);
                    }
                }
            }
            insert masterAssetsToInsert;
            for (Asset asset : masterAssetsToInsert) {
                if (asset.Assignee__c != null) {
                    if (assigneeToMasterAssetsMap.containsKey(asset.Assignee__c)) {
                        assigneeToMasterAssetsMap.get(asset.Assignee__c).add(asset);
                    } else {
                        assigneeToMasterAssetsMap.put(asset.Assignee__c, new List<Asset>{asset});
                    }
                }
            }
            for (Asset asset : newList) {
                if (assigneeToMasterAssetsMap.containsKey(asset.Assignee__c)) {
                    for (Asset masterAsset : assigneeToMasterAssetsMap.get(asset.Assignee__c)) {
                        if (asset.Name == masterAsset.Name) {
                            if (asset.ParentId != masterAsset.Id) {
                                asset.ParentId = masterAsset.Id;
                            }
                        }
                    }
                }
            }
        }
    }

    private Boolean isMasterAsset(Asset asset) {
        if (asset.ParentId == null && asset.Status__c == null && asset.Assignee__c != null &&
                asset.CC_Product__c == null) {
            return true;
        }
        return false;
    }

    private void updatePersonAccountStatuses() {
        Set<Id> contactIds = new Set<Id>();
        List<Contact> contactsWithMembershipsToUpdate = new List<Contact>();
        List<Contact> contactsWithChapterMembershipsToUpdate = new List<Contact>();
        List<Contact> contactsWithACAMSTodayToUpdate = new List<Contact>();
        List<Contact> contactsWithMLDCToUpdate = new List<Contact>();
        List<Contact> contactsWithCAMSToUpdate = new List<Contact>();
        List<Contact> contactsWithCGSSToUpdate = new List<Contact>();
        List<Contact> contactsWithCAMSRMToUpdate = new List<Contact>();
        List<Contact> contactsWithRegimeToUpdate = new List<Contact>();
        List<Contact> contactsWithCAMSFCIToUpdate = new List<Contact>();
        List<Contact> contactsWithCAMSAuditToUpdate = new List<Contact>();
        List<Contact> contactsWithCKYCAToUpdate = new List<Contact>();
        String chapterMembership = ACAMSUtil.CHAPTER + ' ' + ACAMSUtil.MEMBERSHIP;
        String acamsTodayPrintedSubscription = ACAMSUtil.ACAMS_TODAY + ' ' + ACAMSUtil.PRINTED_SUBSCRIPTION;

        for (Asset asset : newList) {
            if (asset.Assignee__c != null && !isMasterAsset(asset) && (oldMap == null ||
                    oldMap.get(asset.Id).Status__c != asset.Status__c ||
                    oldMap.get(asset.Id).CurrentExpirationDate__c != asset.CurrentExpirationDate__c ||
                    oldMap.get(asset.Id).Effective_Date__c != asset.Effective_Date__c)) {
                contactIds.add(asset.Assignee__c);
            }
        }

        if (!contactIds.isEmpty()) {
            Map<Id, List<Asset>> mapContactWithMembershipAssets = new Map<Id, List<Asset>>();
            Map<Id, List<Asset>> mapContactWithChapterMembershipAssets = new Map<Id, List<Asset>>();
            Map<Id, List<Asset>> mapContactWithACAMSTodayAssets = new Map<Id, List<Asset>>();
            Map<Id, List<Asset>> mapContactWithMLDCAssets = new Map<Id, List<Asset>>();
            Map<Id, List<Asset>> mapContactWithCAMSAssets = new Map<Id, List<Asset>>();
            Map<Id, List<Asset>> mapContactWithCGSSAssets = new Map<Id, List<Asset>>();
            Map<Id, List<Asset>> mapContactWithCAMSRMAssets = new Map<Id, List<Asset>>();
            Map<Id, List<Asset>> mapContactWithRegimeAssets = new Map<Id, List<Asset>>();
            Map<Id, List<Asset>> mapContactWithCAMSFCIAssets = new Map<Id, List<Asset>>();
            Map<Id, List<Asset>> mapContactWithCAMSAuditAssets = new Map<Id, List<Asset>>();
            Map<Id, List<Asset>> mapContactWithCKYCAAssets = new Map<Id, List<Asset>>();
            for (Asset asset : [
                    SELECT Id, Name, Effective_Date__c, CurrentExpirationDate__c, Assignee__c, CC_Product__c,
                            CC_Product__r.Level_1__c
                    FROM Asset
                    WHERE Assignee__c IN :contactIds
                    AND (
                            Name = :ACAMSUtil.MEMBERSHIP
                            OR Name = :chapterMembership
                            OR
                            Name = :acamsTodayPrintedSubscription
                            OR Name = :ACAMSUtil.MONEYLAUNDERINGDOTCOM
                            OR
                            Name = 'CAMS Certification'
                            OR Name = 'CAMS Audit'
                            OR Name = 'CAMS FCI'
                            OR
                            Name = 'CAMSRM'
                            OR Name = :ACAMSUtil.REGIME_EXAM
                            OR Name = 'CGSS Certification'
                            OR
                            Name = 'CKYCA Certification'
                    )
                    AND Status__c = :ACAMSUtil.ACTIVE
                    AND CancelDate__c = NULL
                    AND CurrentExpirationDate__c >= TODAY
            ]) {
                if (asset.Name == ACAMSUtil.MEMBERSHIP && mapContactWithMembershipAssets.get(asset.Assignee__c) == null) {
                    mapContactWithMembershipAssets.put(asset.Assignee__c, new List<Asset>{
                            asset
                    });
                } else if (asset.Name == ACAMSUtil.MEMBERSHIP) {
                    mapContactWithMembershipAssets.get(asset.Assignee__c).add(asset);
                } else if (asset.Name == chapterMembership && mapContactWithChapterMembershipAssets.get(asset.Assignee__c) == null) {
                    mapContactWithChapterMembershipAssets.put(asset.Assignee__c, new List<Asset>{
                            asset
                    });
                } else if (asset.Name == chapterMembership) {
                    mapContactWithChapterMembershipAssets.get(asset.Assignee__c).add(asset);
                } else if (asset.Name == acamsTodayPrintedSubscription && mapContactWithACAMSTodayAssets.get(asset.Assignee__c) == null) {
                    mapContactWithACAMSTodayAssets.put(asset.Assignee__c, new List<Asset>{
                            asset
                    });
                } else if (asset.Name == acamsTodayPrintedSubscription) {
                    mapContactWithACAMSTodayAssets.get(asset.Assignee__c).add(asset);
                } else if (asset.Name == ACAMSUtil.MONEYLAUNDERINGDOTCOM && mapContactWithMLDCAssets.get(asset.Assignee__c) == null) {
                    mapContactWithMLDCAssets.put(asset.Assignee__c, new List<Asset>{
                            asset
                    });
                } else if (asset.Name == ACAMSUtil.MONEYLAUNDERINGDOTCOM) {
                    mapContactWithMLDCAssets.get(asset.Assignee__c).add(asset);
                } else if (asset.Name == 'CAMS Certification' && mapContactWithCAMSAssets.get(asset.Assignee__c) == null) {
                    mapContactWithCAMSAssets.put(asset.Assignee__c, new List<Asset>{
                            asset
                    });
                } else if (asset.Name == 'CAMS Certification') {
                    mapContactWithCAMSAssets.get(asset.Assignee__c).add(asset);
                } else if (asset.Name == 'CAMS Audit' && mapContactWithCAMSAuditAssets.get(asset.Assignee__c) == null) {
                    mapContactWithCAMSAuditAssets.put(asset.Assignee__c, new List<Asset>{
                            asset
                    });
                } else if (asset.Name == 'CAMS Audit') {
                    mapContactWithCAMSAuditAssets.get(asset.Assignee__c).add(asset);
                } else if (asset.Name == 'CAMS FCI' && mapContactWithCAMSFCIAssets.get(asset.Assignee__c) == null) {
                    mapContactWithCAMSFCIAssets.put(asset.Assignee__c, new List<Asset>{
                            asset
                    });
                } else if (asset.Name == 'CAMS FCI') {
                    mapContactWithCAMSFCIAssets.get(asset.Assignee__c).add(asset);
                } else if (asset.Name == 'CAMSRM' && mapContactWithCAMSRMAssets.get(asset.Assignee__c) == null) {
                    mapContactWithCAMSRMAssets.put(asset.Assignee__c, new List<Asset>{
                            asset
                    });
                } else if (asset.Name == 'CAMSRM') {
                    mapContactWithCAMSRMAssets.get(asset.Assignee__c).add(asset);
                } else if (asset.Name == ACAMSUtil.REGIME_EXAM && mapContactWithRegimeAssets.get(asset.Assignee__c) == null) {
                    mapContactWithRegimeAssets.put(asset.Assignee__c, new List<Asset>{
                            asset
                    });
                } else if (asset.Name == ACAMSUtil.REGIME_EXAM) {
                    mapContactWithRegimeAssets.get(asset.Assignee__c).add(asset);
                } else if (asset.Name == 'CGSS Certification' && mapContactWithCGSSAssets.get(asset.Assignee__c) == null) {
                    mapContactWithCGSSAssets.put(asset.Assignee__c, new List<Asset>{
                            asset
                    });
                } else if (asset.Name == 'CGSS Certification') {
                    mapContactWithCGSSAssets.get(asset.Assignee__c).add(asset);
                } else if (asset.Name == 'CKYCA Certification' && mapContactWithCKYCAAssets.get(asset.Assignee__c) == null) {
                    mapContactWithCKYCAAssets.put(asset.Assignee__c, new List<Asset>{
                            asset
                    });
                } else if (asset.Name == 'CKYCA Certification') {
                    mapContactWithCKYCAAssets.get(asset.Assignee__c).add(asset);
                }
            }

            for (Id contactId : contactIds) {
                if (mapContactWithMembershipAssets.get(contactId) == null || mapContactWithMembershipAssets.get(contactId).isEmpty()) {
                    Contact contact = new Contact(
                            Id = contactId,
                            ACAMS_Member__c = false,
                            Member_Expire_Date__c = null,
                            Membership_Type__c = ACAMSUtil.NON_MEMBER_CAPS
                    );
                    contactsWithMembershipsToUpdate.add(contact);
                } else {
                    Date highestExpireDate;
                    String membershipType = ACAMSUtil.NON_MEMBER_CAPS;
                    for (Asset asset : mapContactWithMembershipAssets.get(contactId)) {
                        if (highestExpireDate == null) {
                            highestExpireDate = asset.CurrentExpirationDate__c;
                        } else if (highestExpireDate < asset.CurrentExpirationDate__c) {
                            highestExpireDate = asset.CurrentExpirationDate__c;
                        }
                        if (asset.Effective_Date__c <= Date.today() && asset.CurrentExpirationDate__c >= Date.today()) {
                            membershipType = asset.CC_Product__r.Level_1__c == ACAMSUtil.MEMBERSHIP ?
                                    ACAMSUtil.MEMBER_CAPS : ACAMSUtil.ENTERPRISE_CAPS;
                        }
                    }
                    Contact contact = new Contact(
                            Id = contactId,
                            ACAMS_Member__c = true,
                            Member_Expire_Date__c = highestExpireDate,
                            Membership_Type__c = membershipType
                    );
                    contactsWithMembershipsToUpdate.add(contact);
                }

                if (mapContactWithChapterMembershipAssets.get(contactId) == null || mapContactWithChapterMembershipAssets.get(contactId).isEmpty()) {
                    Contact contact = new Contact(
                            Id = contactId,
                            Chapter_Member__c = false,
                            Chapter_Member_Expire_Date__c = null
                    );
                    contactsWithChapterMembershipsToUpdate.add(contact);
                } else {
                    Date highestExpireDate;
                    for (Asset asset : mapContactWithChapterMembershipAssets.get(contactId)) {
                        if (highestExpireDate == null) {
                            highestExpireDate = asset.CurrentExpirationDate__c;
                        } else if (highestExpireDate < asset.CurrentExpirationDate__c) {
                            highestExpireDate = asset.CurrentExpirationDate__c;
                        }
                    }
                    Contact contact = new Contact(
                            Id = contactId,
                            Chapter_Member__c = true,
                            Chapter_Member_Expire_Date__c = highestExpireDate
                    );
                    contactsWithChapterMembershipsToUpdate.add(contact);
                }

                if (mapContactWithACAMSTodayAssets.get(contactId) == null || mapContactWithACAMSTodayAssets.get(contactId).isEmpty()) {
                    Contact contact = new Contact(
                            Id = contactId,
                            ACAMS_Today_Expiration_Date__c = null
                    );
                    contactsWithACAMSTodayToUpdate.add(contact);
                } else {
                    Date highestExpireDate;
                    for (Asset asset : mapContactWithACAMSTodayAssets.get(contactId)) {
                        if (highestExpireDate == null) {
                            highestExpireDate = asset.CurrentExpirationDate__c;
                        } else if (highestExpireDate < asset.CurrentExpirationDate__c) {
                            highestExpireDate = asset.CurrentExpirationDate__c;
                        }
                    }
                    Contact contact = new Contact(
                            Id = contactId,
                            ACAMS_Today_Expiration_Date__c = highestExpireDate
                    );
                    contactsWithACAMSTodayToUpdate.add(contact);
                }

                if (mapContactWithMLDCAssets.get(contactId) == null || mapContactWithMLDCAssets.get(contactId).isEmpty()) {
                    Contact contact = new Contact(
                            Id = contactId,
                            MLDC_Expiration_Date__c = null
                    );
                    contactsWithMLDCToUpdate.add(contact);
                } else {
                    Date highestExpireDate;
                    for (Asset asset : mapContactWithMLDCAssets.get(contactId)) {
                        if (highestExpireDate == null) {
                            highestExpireDate = asset.CurrentExpirationDate__c;
                        } else if (highestExpireDate < asset.CurrentExpirationDate__c) {
                            highestExpireDate = asset.CurrentExpirationDate__c;
                        }
                    }
                    Contact contact = new Contact(
                            Id = contactId,
                            MLDC_Expiration_Date__c = highestExpireDate
                    );
                    contactsWithMLDCToUpdate.add(contact);
                }

                if (mapContactWithCAMSAssets.get(contactId) == null || mapContactWithCAMSAssets.get(contactId).isEmpty()) {
                    Contact contact = new Contact(
                            Id = contactId,
                            CAMS__c = false,
                            CAMS_Expiration_Date__c = null
                    );
                    contactsWithCAMSToUpdate.add(contact);
                } else {
                    Date highestExpireDate;
                    for (Asset asset : mapContactWithCAMSAssets.get(contactId)) {
                        if (highestExpireDate == null) {
                            highestExpireDate = asset.CurrentExpirationDate__c;
                        } else if (highestExpireDate < asset.CurrentExpirationDate__c) {
                            highestExpireDate = asset.CurrentExpirationDate__c;
                        }
                    }
                    Contact contact = new Contact(
                            Id = contactId,
                            CAMS__c = true,
                            CAMS_Expiration_Date__c = highestExpireDate
                    );
                    contactsWithCAMSToUpdate.add(contact);
                }

                if (mapContactWithCAMSAuditAssets.get(contactId) == null || mapContactWithCAMSAuditAssets.get(contactId).isEmpty()) {
                    Contact contact = new Contact(
                            Id = contactId,
                            CAMS_Audit__c = false,
                            CAMS_Audit_Expiration_Date__c = null
                    );
                    contactsWithCAMSAuditToUpdate.add(contact);
                } else {
                    Date highestExpireDate;
                    for (Asset asset : mapContactWithCAMSAuditAssets.get(contactId)) {
                        if (highestExpireDate == null) {
                            highestExpireDate = asset.CurrentExpirationDate__c;
                        } else if (highestExpireDate < asset.CurrentExpirationDate__c) {
                            highestExpireDate = asset.CurrentExpirationDate__c;
                        }
                    }
                    Contact contact = new Contact(
                            Id = contactId,
                            CAMS_Audit__c = true,
                            CAMS_Audit_Expiration_Date__c = highestExpireDate
                    );
                    contactsWithCAMSAuditToUpdate.add(contact);
                }

                if (mapContactWithCAMSFCIAssets.get(contactId) == null || mapContactWithCAMSFCIAssets.get(contactId).isEmpty()) {
                    Contact contact = new Contact(
                            Id = contactId,
                            CAMS_FCI__c = false,
                            CAMS_FCI_Expiration_Date__c = null
                    );
                    contactsWithCAMSFCIToUpdate.add(contact);
                } else {
                    Date highestExpireDate;
                    for (Asset asset : mapContactWithCAMSFCIAssets.get(contactId)) {
                        if (highestExpireDate == null) {
                            highestExpireDate = asset.CurrentExpirationDate__c;
                        } else if (highestExpireDate < asset.CurrentExpirationDate__c) {
                            highestExpireDate = asset.CurrentExpirationDate__c;
                        }
                    }
                    Contact contact = new Contact(
                            Id = contactId,
                            CAMS_FCI__c = true,
                            CAMS_FCI_Expiration_Date__c = highestExpireDate
                    );
                    contactsWithCAMSFCIToUpdate.add(contact);
                }

                if (mapContactWithCAMSRMAssets.get(contactId) == null || mapContactWithCAMSRMAssets.get(contactId).isEmpty()) {
                    Contact contact = new Contact(
                            Id = contactId,
                            CAMSRM__c = false,
                            CAMSRM_Expiration_Date__c = null
                    );
                    contactsWithCAMSRMToUpdate.add(contact);
                } else {
                    Date highestExpireDate;
                    for (Asset asset : mapContactWithCAMSRMAssets.get(contactId)) {
                        if (highestExpireDate == null) {
                            highestExpireDate = asset.CurrentExpirationDate__c;
                        } else if (highestExpireDate < asset.CurrentExpirationDate__c) {
                            highestExpireDate = asset.CurrentExpirationDate__c;
                        }
                    }
                    Contact contact = new Contact(
                            Id = contactId,
                            CAMSRM__c = true,
                            CAMSRM_Expiration_Date__c = highestExpireDate
                    );
                    contactsWithCAMSRMToUpdate.add(contact);
                }

                if (mapContactWithRegimeAssets.get(contactId) == null || mapContactWithRegimeAssets.get(contactId).isEmpty()) {
                    Contact contact = new Contact(
                            Id = contactId,
                            Singapore_Regime__c = false,
                            India_Regime__c = false,
                            Singapore_Regime_Expiration_Date__c = null,
                            India_Regime_Expiration_Date__c = null
                    );
                    contactsWithRegimeToUpdate.add(contact);
                } else {
                    Date highestSingaporeExpireDate;
                    Date highestIndiaExpireDate;
                    for (Asset asset : mapContactWithRegimeAssets.get(contactId)) {
                        if (asset.CC_Product__r.Name.contains('Singapore')) {
                            if (highestSingaporeExpireDate == null) {
                                highestSingaporeExpireDate = asset.CurrentExpirationDate__c;
                            } else if (highestSingaporeExpireDate < asset.CurrentExpirationDate__c) {
                                highestSingaporeExpireDate = asset.CurrentExpirationDate__c;
                            }
                        } else if (asset.CC_Product__r.Name.contains('India')) {
                            if (highestIndiaExpireDate == null) {
                                highestIndiaExpireDate = asset.CurrentExpirationDate__c;
                            } else if (highestIndiaExpireDate < asset.CurrentExpirationDate__c) {
                                highestIndiaExpireDate = asset.CurrentExpirationDate__c;
                            }
                        }

                    }
                    Contact contact = new Contact(
                            Id = contactId,
                            Singapore_Regime__c = highestSingaporeExpireDate != null ? true : false,
                            Singapore_Regime_Expiration_Date__c = highestSingaporeExpireDate,
                            India_Regime__c = highestIndiaExpireDate != null ? true : false,
                            India_Regime_Expiration_Date__c = highestIndiaExpireDate
                    );
                    contactsWithRegimeToUpdate.add(contact);
                }

                if (mapContactWithCGSSAssets.get(contactId) == null || mapContactWithCGSSAssets.get(contactId).isEmpty()) {
                    Contact contact = new Contact(
                            Id = contactId,
                            CGSS__c = false,
                            CGSS_Expiration_Date__c = null
                    );
                    contactsWithCGSSToUpdate.add(contact);
                } else {
                    Date highestExpireDate;
                    for (Asset asset : mapContactWithCGSSAssets.get(contactId)) {
                        if (highestExpireDate == null) {
                            highestExpireDate = asset.CurrentExpirationDate__c;
                        } else if (highestExpireDate < asset.CurrentExpirationDate__c) {
                            highestExpireDate = asset.CurrentExpirationDate__c;
                        }
                    }
                    Contact contact = new Contact(
                            Id = contactId,
                            CGSS__c = true,
                            CGSS_Expiration_Date__c = highestExpireDate
                    );
                    contactsWithCGSSToUpdate.add(contact);
                }

                if (mapContactWithCKYCAAssets.get(contactId) == null || mapContactWithCKYCAAssets.get(contactId).isEmpty()) {
                    Contact contact = new Contact(
                            Id = contactId,
                            CKYCA__c = false,
                            CKYCA_Expiration_Date__c = null
                    );
                    contactsWithCKYCAToUpdate.add(contact);
                } else {
                    Date highestExpireDate;
                    for (Asset asset : mapContactWithCKYCAAssets.get(contactId)) {
                        if (highestExpireDate == null) {
                            highestExpireDate = asset.CurrentExpirationDate__c;
                        } else if (highestExpireDate < asset.CurrentExpirationDate__c) {
                            highestExpireDate = asset.CurrentExpirationDate__c;
                        }
                    }
                    Contact contact = new Contact(
                            Id = contactId,
                            CKYCA__c = true,
                            CKYCA_Expiration_Date__c = highestExpireDate
                    );
                    contactsWithCKYCAToUpdate.add(contact);
                }
            }
        }
        if (!contactsWithMembershipsToUpdate.isEmpty()) {
            update contactsWithMembershipsToUpdate;
        }
        if (!contactsWithChapterMembershipsToUpdate.isEmpty()) {
            update contactsWithChapterMembershipsToUpdate;
        }
        if (!contactsWithACAMSTodayToUpdate.isEmpty()) {
            update contactsWithACAMSTodayToUpdate;
        }
        if (!contactsWithMLDCToUpdate.isEmpty()) {
            update contactsWithMLDCToUpdate;
        }
        if (!contactsWithCAMSToUpdate.isEmpty()) {
            update contactsWithCAMSToUpdate;
        }
        if (!contactsWithCAMSAuditToUpdate.isEmpty()) {
            update contactsWithCAMSAuditToUpdate;
        }
        if (!contactsWithCAMSFCIToUpdate.isEmpty()) {
            update contactsWithCAMSFCIToUpdate;
        }
        if (!contactsWithCAMSRMToUpdate.isEmpty()) {
            update contactsWithCAMSRMToUpdate;
        }
        if (!contactsWithRegimeToUpdate.isEmpty()) {
            update contactsWithRegimeToUpdate;
        }
        if (!contactsWithCGSSToUpdate.isEmpty()) {
            update contactsWithCGSSToUpdate;
        }
        if (!contactsWithCKYCAToUpdate.isEmpty()) {
            update contactsWithCKYCAToUpdate;
        }
    }
}