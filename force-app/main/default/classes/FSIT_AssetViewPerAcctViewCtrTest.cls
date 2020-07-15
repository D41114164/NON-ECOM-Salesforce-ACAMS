@Istest
public with sharing class FSIT_AssetViewPerAcctViewCtrTest {
    public FSIT_AssetViewPerAcctViewCtrTest() {

    }

    @IsTest
    static void testAssetView() {
        Account account = new Account(
                Name = 'Facebook'
        );
        insert account;

        Contact contact = new Contact(
                AccountId = account.Id,
                LastName = 'Karl'
        );
        insert contact;

        ccrz__E_Product__c prod = new ccrz__E_Product__c();
        prod.Name = 'name';
        prod.ccrz__SKU__c = 'CAMS';
        prod.ccrz__ProductStatus__c = 'Released';
        prod.Level_1__c = 'Certification';
        prod.Level_2__c = 'CAMS';
        insert prod;

        Asset asst = new Asset(
            Name = 'test_Asset',
            Status__c = 'Active',
            CC_Product__c = prod.Id,
            Assignee__c = contact.Id,
            ContactId = contact.Id
        );
        insert asst;

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(account);
        FSIT_AssetViewPersonalAccountController testCtr = new FSIT_AssetViewPersonalAccountController(sc);
        FSIT_AssetViewPersonalAccountController testCtrNo = new FSIT_AssetViewPersonalAccountController();

        PageReference pageRef = Page.FSIT_AssetViewPersonalAccountPage;
        pageRef.getParameters().put('id', String.valueOf(account.Id));
        Test.setCurrentPage(pageRef);
        testCtr.dataInit();
        testCtr.displayAssetsByGroupName();
        testCtr.searchText = 'CAMS';
        testCtr.runSearch();

        Test.stopTest();
    }
}