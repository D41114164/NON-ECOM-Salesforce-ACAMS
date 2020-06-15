@IsTest
class ACAMSOpportunityCreateOrderTest {

    @IsTest
    static void createOrder() {
        CCACAMSTestUtil testUtil = new CCACAMSTestUtil();
        ACAMSContactAddressTriggerHandler.skipAddressValidation = true;
        Map<String, Object> testData = testUtil.initData();
        ACAMSContactAddressTriggerHandler.skipAddressValidation = false;
        Account testAccount = (Account) testData.get(CCAviTestUtil.PN_USER_ACCOUNT);
        ccrz__E_Cart__c testCart = (ccrz__E_Cart__c) testData.get(CCAviTestUtil.PN_CART);
        ccrz__E_Order__c testOrder = (ccrz__E_Order__c) testData.get(CCAviTestUtil.PN_ORDER);
        Opportunity testOpportunity;
        testOpportunity = new Opportunity(
                AccountId = testAccount.Id,
                CC_Cart__c = testCart.Id,
                Name = 'Test Opportunity',
                StageName = Opportunity.StageName.getDescribe().getPicklistValues()[0].getValue(),
                CloseDate = Date.today().addDays(10)
        );
        ACAMSOpportunityTriggerHandler.skipCartCreationOnInsert = true;
        insert testOpportunity;
        ACAMSOpportunityTriggerHandler.skipCartCreationOnInsert = false;
        ApexPages.StandardController opportunityController = new ApexPages.StandardController(testOpportunity);
        ACAMSOpportunityCreateOrderController controller = new ACAMSOpportunityCreateOrderController(
                opportunityController
        );
        ACAMSOpportunityCreateOrderController.testOrderId = testOrder.Id;
        Test.setCurrentPage(Page.ACAMSOpportunityCreateOrder);
        ApexPages.PageReference opportunityReference = controller.goToOpportunityPage();
        System.assert(opportunityReference.getUrl().contains(testOpportunity.Id));
        controller.createOrder();
        System.assert(controller.successful);
        ApexPages.PageReference oderReference = controller.goToOrderPage();
        System.assert(oderReference.getUrl().contains(testOrder.Id));
    }

    @IsTest
    static void createOrderError() {
        CCACAMSTestUtil testUtil = new CCACAMSTestUtil();
        ACAMSContactAddressTriggerHandler.skipAddressValidation = true;
        Map<String, Object> testData = testUtil.initData();
        ACAMSContactAddressTriggerHandler.skipAddressValidation = false;
        Account testAccount = (Account) testData.get(CCAviTestUtil.PN_USER_ACCOUNT);
        ccrz__E_Cart__c testCart = (ccrz__E_Cart__c) testData.get(CCAviTestUtil.PN_CART);
        ccrz__E_Order__c testOrder = (ccrz__E_Order__c) testData.get(CCAviTestUtil.PN_ORDER);
        Opportunity testOpportunity;
        testOpportunity = new Opportunity(
                AccountId = testAccount.Id,
                CC_Cart__c = null,
                Name = 'Test Opportunity',
                StageName = Opportunity.StageName.getDescribe().getPicklistValues()[0].getValue(),
                CloseDate = Date.today().addDays(10)
        );
        ACAMSOpportunityTriggerHandler.skipCartCreationOnInsert = true;
        insert testOpportunity;
        ACAMSOpportunityTriggerHandler.skipCartCreationOnInsert = false;
        ApexPages.StandardController opportunityController = new ApexPages.StandardController(testOpportunity);
        ACAMSOpportunityCreateOrderController controller = new ACAMSOpportunityCreateOrderController(
                opportunityController
        );
        ACAMSOpportunityCreateOrderController.testOrderId = testOrder.Id;
        ApexPages.PageReference opportunityReference = controller.goToOpportunityPage();
        System.assert(opportunityReference.getUrl().contains(testOpportunity.Id));
        controller.createOrder();
        System.assert(!controller.successful);
        System.assert(!ApexPages.getMessages().isEmpty());
    }
}