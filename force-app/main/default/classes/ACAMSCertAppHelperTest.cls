@IsTest
public class ACAMSCertAppHelperTest {

    static CCAviTestUtil util = new CCAviTestUtil();

    @IsTest static void UpdateAsset_test() {
        Map<String, Object> testData = util.initData();
        Account a = (Account) testData.get(CCAviTestUtil.PN_USER_ACCOUNT);
        System.assert(a.Id != null);

        Contact c = (Contact) testData.get(CCAviTestUtil.PN_USER_CONTACT);
        System.assert(c.Id != null);

        ccrz__E_Product__c prod = (ccrz__E_Product__c) testData.get(CCAviTestUtil.PN_PRODUCT);
        prod.Level_1__c = 'Certification';
        prod.Exam_Code__c = 'test';
        update prod;

        Asset ast = new Asset();
        ast.CC_Product__c = prod.Id;
        ast.Name = 'Certifications';
        ast.Status__c = 'Active';
        ast.AccountId = a.Id;
        ast.ContactId = c.Id;
        ast.Assignee__c = c.Id;
        ast.Paid_Cert__c = true;
        ast.CurrentExpirationDate__c = Date.today().addDays(20);
        insert ast;

        List<Certification_Application__c> calist = new List<Certification_Application__c>();
        Certification_Application__c ca = new Certification_Application__c();
        ca.Contact__c = c.Id;
        ca.Asset_Pending_to_Process__c = true;

        insert ca;
        ca.Status__c = 'Under Review';
        update ca;
        ast.Application_Received__c = true;
        update ast;

        ca.Status__c = 'Approved';
        update ca;
        ast.Certification_Approved_Application__c = true;
        update ast;
        calist.add(ca);
        ACAMSCertAppHelper.UpdateAsset(calist);
    }

    @IsTest static void UpdateLocaleOnContact_test() {
        Map<String, Object> testData = util.initData();
        Account a = (Account) testData.get(CCAviTestUtil.PN_USER_ACCOUNT);
        System.assert(a.Id != null);

        Contact c = (Contact) testData.get(CCAviTestUtil.PN_USER_CONTACT);
        System.assert(c.Id != null);

        List<Certification_Application__c> calist = new List<Certification_Application__c>();
        Certification_Application__c ca = new Certification_Application__c();
        ca.Language_Selected__c = 'en_US';
        ca.Contact__c = c.Id;

        calist.add(ca);
        Certification_Application__c ca2 = new Certification_Application__c();
        ca2.Language_Selected__c = 'de';
        ca2.Contact__c = c.Id;
        calist.add(ca2);
        c.Locale_for_PearsonVUE__c = 'de-DE';
        update c;
        Certification_Application__c ca3 = new Certification_Application__c();
        ca3.Language_Selected__c = 'es';
        ca3.Contact__c = c.Id;
        calist.add(ca3);
        Certification_Application__c ca4 = new Certification_Application__c();
        ca4.Language_Selected__c = 'fr';
        ca4.Contact__c = c.Id;
        calist.add(ca4);
        Certification_Application__c ca5 = new Certification_Application__c();
        ca5.Language_Selected__c = 'pt';
        ca5.Contact__c = c.Id;
        calist.add(ca5);
        Certification_Application__c ca6 = new Certification_Application__c();
        ca6.Language_Selected__c = 'ja';
        ca6.Contact__c = c.Id;
        calist.add(ca6);
        Certification_Application__c ca7 = new Certification_Application__c();
        ca7.Language_Selected__c = 'zh_CN';
        ca7.Contact__c = c.Id;
        calist.add(ca7);
        Certification_Application__c ca8 = new Certification_Application__c();
        ca8.Language_Selected__c = 'zh_TW';
        ca8.Contact__c = c.Id;
        calist.add(ca8);
        ACAMSCertAppHelper.UpdateLocaleOnContact(calist);
    }
}