@RestResource(UrlMapping='/api/cart/tax')
global with sharing class ACAMSCartTaxService {

    @HttpPost
    global static TaxResponse checkTax(String cartId) {
        ccrz__E_Cart__c cart = ACAMSCartDAO.getCartById(cartId);

        ACAMSCartTaxRecalculationController.recalculateTaxes(cartId);

        TaxResponse taxResponse = new TaxResponse();
        if (cart.ccrz__TaxAmount__c == null) {
            taxResponse.tax = 0;
        } else {
            taxResponse.tax = cart.ccrz__TaxAmount__c;
        }

        return taxResponse;
    }

    global class TaxResponse {
        public Decimal tax { get; set; }
    }
}