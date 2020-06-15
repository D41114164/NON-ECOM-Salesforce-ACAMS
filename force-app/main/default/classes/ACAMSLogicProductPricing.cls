global with sharing class ACAMSLogicProductPricing extends ccrz.ccLogicProductPricing {

    /**
     * CloudCraze has a bug where it returns the price based on the autonumber. This reorders the priceListItems in
     * ascending order by price so that the lowest price available to the user is returned.
     */
    global virtual override Map<String, Object> evaluateSubProdTermPricing(Map<String, Object> inputData) {
        List<Map<String, Object>> priceListItems = (List<Map<String, Object>>) inputData.get('priceListItems');
        List<Map<String, Object>> newPriceListItems = new List<Map<String, Object>>();
        Map<String, Decimal> priceMap = new Map<String, Decimal>();
        Map<String, Map<String, Object>> priceListItemsMap = new Map<String, Map<String, Object>>();
        for (Map<String, Object> priceListItem : priceListItems) {
            String sfid = (String) priceListItem.get('sfid');
            priceMap.put(sfid, (Decimal) priceListItem.get('price'));
            priceListItemsMap.put(sfid, priceListItem);
        }
        List<Decimal> prices = priceMap.values();
        prices.sort();
        List<String> capturedIds = new List<String>();

        for (Decimal price : prices) {
            for (String sfid : priceMap.keySet()) {
                if (!capturedIds.contains(sfid)) {
                    Decimal mapPrice = priceMap.get(sfid);
                    if (price == mapPrice && price != 0) {
                        newPriceListItems.add(priceListItemsMap.get(sfid));
                        capturedIds.add(sfid);
                    }
                }
            }
        }
        inputData.put('priceListItems', newPriceListItems);
        System.debug('inputData: ' + JSON.serializePretty(newPriceListItems));
        Map<String, Object> outputData = super.evaluateSubProdTermPricing(inputData);
        return outputData;
    }
}