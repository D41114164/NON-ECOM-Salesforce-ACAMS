@IsTest
public class ACAMSOrderTriggerHandlerTest {

    static CCAviTestUtil util = new CCAviTestUtil();

    @IsTest
    public static void testReturnOrderCreated() {
        Map<String, Object> testData = util.initData();

        ccrz__E_Order__c order = (ccrz__E_Order__c) testData.get(CCAviTestUtil.PN_ORDER);
        ccrz__E_TransactionPayment__c tp =
                (ccrz__E_TransactionPayment__c) testData.get(CCAviTestUtil.PN_TRANSACTION_PAYMENT_AUTH);
        ccrz__E_TransactionPayment__c tp2 =
                (ccrz__E_TransactionPayment__c) testData.get(CCAviTestUtil.PN_TRANSACTION_PAYMENT_CAPTURE);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new refundCalloutMockImpl());
        order.ccrz__OrderStatus__c = ACAMSUtil.COMPLETED;
        update order;
        order.ccrz__OrderStatus__c = ACAMSUtil.REFUNDED;
        update order;
        Test.stopTest();
        List<ccrz__E_Order__c> cloneOrder = [
                SELECT
                        Id,
                        ccrz__Name__c
                FROM
                        ccrz__E_Order__c
                WHERE
                        ccrz__Name__c = :ACAMSUtil.REFUNDED_ORDER AND ccrz__Order__c = :order.Id
                LIMIT 1
        ];
        System.assert(cloneOrder[0] != null);
        System.assert(cloneOrder[0].ccrz__Name__c == ACAMSUtil.REFUNDED_ORDER);
        List <ccrz__E_TransactionPayment__c> transactionPayments = [
                SELECT
                        Id,
                        ccrz__TransactionCode__c,
                        ccrz__TransactionPaymentId__c,
                        ccrz__TransactionSubcode__c,
                        ccrz__TransactionType__c
                FROM
                        ccrz__E_TransactionPayment__c
                WHERE
                        ccrz__TransactionSubcode__c = '100'
                LIMIT 1
        ];
        ccrz__E_TransactionPayment__c transactionPayment = transactionPayments.get(0);
        System.assert(!transactionPayments.isEmpty());
        System.assert(transactionPayment.ccrz__TransactionCode__c == 'ACCEPT');
        System.assert(transactionPayment.ccrz__TransactionPaymentId__c == '9057101982752034820293');
        System.assert(transactionPayment.ccrz__TransactionSubcode__c == '100');
        System.assert(transactionPayment.ccrz__TransactionType__c == 'CREDIT');
    }

    class refundCalloutMockImpl implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setHeader('Content-Type', 'application/xml');
            XmlWriter xmlWriter = new XmlWriter();
            response.setBody(xmlWriter.getXml());

            return response;
        }
    }

    class XmlWriter {
        public String getXml() {
            Dom.Document doc = new Dom.Document();

            Dom.XmlNode root = doc.createRootElement('root', null, null);
            Dom.XmlNode body = root.addChildElement('Body', 'http://schemas.xmlsoap.org/soap/envelope/', null);
            Dom.XmlNode replyMessage = body.addChildElement('replyMessage',
                    'urn:schemas-cybersource-com:transaction-data-1.155', null);
            replyMessage.addChildElement('requestID', 'urn:schemas-cybersource-com:transaction-data-1.155', null)
                    .addTextNode('9057101982752034820293');
            replyMessage.addChildElement('decision', 'urn:schemas-cybersource-com:transaction-data-1.155', null)
                    .addTextNode('ACCEPT');
            replyMessage.addChildElement('reasonCode', 'urn:schemas-cybersource-com:transaction-data-1.155', null)
                    .addTextNode('100');

            return doc.toXmlString();
        }
    }

}