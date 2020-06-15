/*
Helper Class for Certification Application Trigger
Contains methods to update related asset based on status and also update contact's locale from language selected field.
 */
public class ACAMSCertAppHelper {

    public static Boolean isAssetUpdated = false;
    public static Boolean isLocaleUpdated = false;

    public static void UpdateAsset(List<Certification_Application__c> newCertApps) {
        Set<Id> contactIds = new Set <Id>();
        Boolean isCgss;
        Map<Certification_Application__c, Id> certAppConIDMap = new Map<Certification_Application__c, Id>();
        Map<Id, List<Asset>> conAssetsMap = new Map<Id, List<Asset>>();
        List<Asset> astLstUpdt = new List<Asset>();
        List<Asset> astLst = new List<Asset>();

        for (Certification_Application__c certApp : newCertApps) {
            if (certApp.Asset_Pending_to_Process__c == true) {
                contactIds.add(certApp.Contact__c);
                certAppConIDMap.put(certApp, certApp.Contact__c);
            }
            if (certApp.CGSS_Check__c == true) {
                isCgss = true;
            } else {
                isCgss = false;
            }
        }

        if (!contactIds.isEmpty()) {
            if (isCgss) {
                astLst = [
                        SELECT Id, Assignee__c
                        FROM Asset
                        WHERE Assignee__c IN :contactIds
                        AND Paid_Cert__c = TRUE
                        AND Status__c = 'Active'
                        AND Name = :'Certifications'
                        AND Enterprise_Product_HL__c != 'SG-AML-Regime'
                        AND Product_level_2__c = :'CGSS'
                        LIMIT 50
                ];
            } else {
                astLst = [
                        SELECT Id, Assignee__c
                        FROM Asset
                        WHERE Assignee__c IN :contactIds
                        AND Paid_Cert__c = TRUE
                        AND Status__c = 'Active'
                        AND Name = :'Certifications'
                        AND Enterprise_Product_HL__c != 'SG-AML-Regime'
                        AND Product_level_2__c != 'CGSS'
                        LIMIT 50
                ];
            }
            for (Asset ast : astLst) {
                for (Id conId : contactIds) {
                    if (ast.Assignee__c == conId) {
                        if (conAssetsMap.containsKey(conId)) {
                            conAssetsMap.get(conId).add(ast);
                        } else {
                            conAssetsMap.put(conId, new List<Asset>{
                                    ast
                            });
                        }
                    }
                }
            }
        }
        if (!conAssetsMap.isEmpty() && !certAppConIDMap.isEmpty()) {
            for (Certification_Application__c certApp : certAppConIDMap.keySet()) {
                if (conAssetsMap.containsKey(certApp.Contact__c) && conAssetsMap.get(certApp.Contact__c).size() > 0) {
                    if (certApp.Status__c == 'Under Review') {
                        for (Asset ast : conAssetsMap.get(certApp.Contact__c)) {
                            ast.Application_Received__c = true;
                            astLstUpdt.add(ast);
                        }
                    }
                    if (certApp.Status__c == 'Approved') {
                        certApp.Application_Approval_Date__c = System.today();
                        for (Asset ast : conAssetsMap.get(certApp.Contact__c)) {
                            ast.Application_Received__c = true;
                            ast.Certification_Approved_Application__c = true;
                            ast.Application_Date__c = certApp.Application_Approval_Date__c.date();
                            astLstUpdt.add(ast);
                            certApp.Asset_Pending_to_Process__c = false;
                        }
                    }
                }
            }
        }
        Map<Id, Asset> asstmap = new Map<Id, Asset>();
        asstmap.putAll(astLstUpdt);
        if (asstmap.size() > 0) {
            isAssetUpdated = true;
            update asstmap.values();
        }
    }

    public static void UpdateLocaleOnContact(List<Certification_Application__c> newCertApps) {
        isLocaleUpdated = true;
        Map<Id, Certification_Application__c> maplocales = new Map<Id, Certification_Application__c>();
        List<Contact> contacts = new List<Contact>();
        for (Certification_Application__c crtt : newCertApps) {
            if (crtt.Language_Selected__c != null) {
                maplocales.put(crtt.Contact__c, crtt);
            }
        }
        contacts = [
                SELECT Id, Locale_for_PearsonVUE__c
                FROM Contact
                WHERE Id IN :maplocales.keySet()
        ];
        for (Certification_Application__c crt : maplocales.values()) {
            for (Contact c : contacts) {
                if (crt.Language_Selected__c != null) {
                    if (crt.Language_Selected__c == 'de') {
                        c.Locale_for_PearsonVUE__c = 'de-DE';
                    } else if (crt.Language_Selected__c == 'en_US') {
                        c.Locale_for_PearsonVUE__c = 'en-US';
                    } else if (crt.Language_Selected__c == 'es') {
                        c.Locale_for_PearsonVUE__c = 'es-US';
                    } else if (crt.Language_Selected__c == 'fr') {
                        c.Locale_for_PearsonVUE__c = 'fr-FR';
                    } else if (crt.Language_Selected__c == 'pt') {
                        c.Locale_for_PearsonVUE__c = 'pt-BR';
                    } else if (crt.Language_Selected__c == 'ja') {
                        c.Locale_for_PearsonVUE__c = 'ja-JP';
                    } else if (crt.Language_Selected__c == 'zh_CN') {
                        c.Locale_for_PearsonVUE__c = 'zh-CN';
                    } else if (crt.Language_Selected__c == 'zh_TW') {
                        c.Locale_for_PearsonVUE__c = 'zh-TW';
                    }
                }
            }
        }
        if (Test.isRunningTest()) {
            update contacts;
        } else if (!System.isFuture() && !contacts.isEmpty()) {
            System.enqueueJob(new ACAMSUtil.UpdateObject(contacts));
        }
    }
}