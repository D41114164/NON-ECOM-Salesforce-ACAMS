global with sharing class ACAMSLogicCartPlace extends ccrz.ccLogicCartPlace {

    global virtual override Map<String, Object> process(Map<String, Object> inputData) {
        Boolean isSuccess = false;
        Map<String, Object> outputData;
        ccrz.cc_hk_Payment.TransactionPaymentParams tpParams;
        // Workaround for getting ccrz__E_TransactionPayment__c objects to be created through API calls
        try {
            Map<String, Object> tpMso = (Map<String, Object>) inputData.get(ccrz.ccApiCart.TRANSPAYMENTDATA);
            tpParams = ccrz.cc_hk_Payment.deserializeTransactionParams(JSON.serialize(tpMso));
        } catch (Exception e) {
            tpParams = (ccrz.cc_hk_Payment.TransactionPaymentParams) inputData.get(ccrz.ccApiCart.TRANSPAYMENTDATA);
        }
        inputData.put(ccrz.ccApiCart.TRANSPAYMENTDATA, tpParams);
        outputData = super.process(inputData);
        isSuccess = (Boolean) outputData.get(ccrz.ccApi.SUCCESS);

        if (isSuccess) {
            try {
                String orderId = (String) outputData.get(ccrz.ccApiCart.ORDER_ID);
                ACAMSInvoiceService.splitOrderInvoice(orderId);
                ccrz__E_Order__c order = ACAMSOrderDAO.getOrder(orderId);
                addNumberOfOrdersToAccount(order.ccrz__Account__c);

                List<ccrz__E_OrderItem__c> orderItems = ACAMSOrderDAO.getOrderItems(orderId);
                List<ccrz__E_CartItem__c> cartItems = ACAMSCartDAO.getCartItemsByCartId(order.ccrz__OriginatedCart__c);
                Map<String, Boolean> autoRenewCartItemsMap = new Map<String, Boolean>();
                for (ccrz__E_CartItem__c cartItem : cartItems) {
                    if (cartItem.ccrz__SubProdTerm__c != null) {
                        autoRenewCartItemsMap.put(cartItem.Id, cartItem.Auto_Renew_Subscription__c);
                    }
                }
                Map<String, List<ccrz__E_Subscription__c>> orderItemToSubscriptionsMap = new Map<String, List<ccrz__E_Subscription__c>>();
                List<ccrz__E_Subscription__c> subscriptions = ACAMSSubscriptionDAO.getSubscriptionsByOrder(orderId);
                for (ccrz__E_Subscription__c sub : subscriptions) {
                    if (!orderItemToSubscriptionsMap.containsKey(sub.ccrz__CCOrderItem__c)) {
                        List<ccrz__E_Subscription__c> subList = new List<ccrz__E_Subscription__c>{sub};
                        orderItemToSubscriptionsMap.put(sub.ccrz__CCOrderItem__c, subList);
                    } else {
                        orderItemToSubscriptionsMap.get(sub.ccrz__CCOrderItem__c).add(sub);
                    }
                }
                Set<String> ceregoIds = new Set<String>();
                Boolean zeroDollar = false;
                for (ccrz__E_OrderItem__c orderItem : orderItems) {
                    if (orderItem.ccrz__OrderLineType__c.equalsIgnoreCase(ACAMSUtil.MAJOR) &&
                            orderItem.ccrz__Product__r.ccrz__ProductType__c != ACAMSUtil.KIT &&
                            orderItem.ccrz__Product__r.ccrz__ProductType__c != ACAMSUtil.DYNAMIC_KIT) {
                        if (orderItem.ccrz__SubAmount__c == 0) {
                            if (orderItem.ccrz__Price__c == 0) {
                                zeroDollar = true;
                            }
                        }
                    }
                    orderItem.Educational_Credits__c = orderItem.ccrz__Product__r.Educational_Credits__c;
                    if (orderItem.ccrz__Product__r.Cerego_ID__c != null) {
                        ceregoIds.add(orderItem.ccrz__Product__r.Cerego_ID__c);
                    }
                    if (orderItemToSubscriptionsMap.containsKey(orderItem.Id)) {
                        List<ccrz__E_Subscription__c> subs = orderItemToSubscriptionsMap.get(orderItem.Id);
                        List<ccrz__E_Subscription__c> subsToUpdate = new List<ccrz__E_Subscription__c>();
                        for (ccrz__E_Subscription__c sub : subs) {
                            if (autoRenewCartItemsMap.containsKey(orderItem.ccrz__OrderItemId__c)) {
                                sub.ccrz__AutoRenew__c = autoRenewCartItemsMap.get(orderItem.ccrz__OrderItemId__c);
                                subsToUpdate.add(sub);
                            }
                        }
                        update subsToUpdate;
                    }
                }
                update orderItems;

                if (!ceregoIds.isEmpty()) {
                    String ceregoUsername = order.ccrz__BuyerFirstName__c + ' ' + order.ccrz__BuyerLastName__c;
                    ACAMSCeregoService.ceregoProductCall(ceregoIds, ceregoUsername, order.ccrz__BuyerEmail__c, order.Id);
                }

                Boolean wirePayment = false;
                Boolean checkPayment = false;
                Boolean creditCardPayment = false;
                Boolean purchaseOrderPayment = false;
                List<ccrz__E_TransactionPayment__c> payments = ACAMSOrderDAO.getTransactionPayments(new Set<Id>{
                        orderId
                });
                for (ccrz__E_TransactionPayment__c payment : payments) {
                    if (Test.isRunningTest()) {
                        payment.ccrz__RequestAmount__c = 1.00;
                        update payment;
                    }
                    if (payment.ccrz__AccountType__c == ACAMSUtil.PO) {
                        purchaseOrderPayment = true;
                        break;
                    } else if (payment.ccrz__AccountType__c == ACAMSUtil.WT_CAPS) {
                        wirePayment = true;
                        break;
                    } else if (payment.ccrz__AccountType__c == ACAMSUtil.ACH_CAPS) {
                        checkPayment = true;
                        break;
                    } else if (payment.ccrz__AccountType__c == ACAMSUtil.ZERO_DOLLAR_API) {
                        zeroDollar = true;
                        break;
                    } else {
                        creditCardPayment = true;
                        break;
                    }
                }
                if (order.ccrz__ShipAmount__c != null && order.ccrz__ShipAmount__c > 0) {
                    ccrz__E_OrderItem__c shippingOrderItem = new ccrz__E_OrderItem__c(ccrz__Order__c = orderId, ccrz__Product__c = ACAMSProductDAO.getShippingProductId(), ccrz__Price__c = order.ccrz__ShipAmount__c != null ? order.ccrz__ShipAmount__c : 0, ccrz__Quantity__c = 1, ccrz__SubAmount__c = 0);
                    insert shippingOrderItem;
                }

                order.ccrz__BuyerFirstName__c = order.ccrz__Contact__r.FirstName;
                order.ccrz__BuyerLastName__c = order.ccrz__Contact__r.LastName;
                order.ccrz__BuyerEmail__c = order.ccrz__Contact__r.Email;
                order.Purchaser_Email__c = (String) inputData.get(ACAMSUtil.USER_EMAIL);

                order.Account_Group__c = order.ccrz__Account__r.ccrz__E_AccountGroup__c;

                if (order.ccrz__TaxAmount__c == null) {
                    order.ccrz__TaxAmount__c = 0;
                }
                if (wirePayment) {
                    order.ccrz__OrderStatus__c = ACAMSUtil.ON_HOLD;
                    order.ccrz__PaymentMethod__c = ACAMSUtil.WIRE_TRANSFER;
                } else if (checkPayment) {
                    order.ccrz__OrderStatus__c = ACAMSUtil.ON_HOLD;
                    order.ccrz__PaymentMethod__c = ACAMSUtil.CHECK;
                } else if (creditCardPayment) {
                    order.ccrz__OrderStatus__c = ACAMSUtil.IN_PROCESS;
                    order.ccrz__PaymentMethod__c = ACAMSUtil.CC;
                } else if (zeroDollar) {
                    order.ccrz__OrderStatus__c = ACAMSUtil.IN_PROCESS;
                    if (order.ccrz__BuyerEmail__c != order.Purchaser_Email__c) {
                        order.ccrz__PaymentMethod__c = ACAMSUtil.CSR_ZERO_DOLLAR;
                    } else {
                        order.ccrz__PaymentMethod__c = ACAMSUtil.ZERO_DOLLAR;
                    }
                }

                updateOrderWithMinorLineItems(order, orderItems);
                updateOrderWithOrderShipments(order, orderItems);
                update order;

                stampOrders(order.Id);
                ACAMSAssetHelper.generateAssets(order.Id);
            } catch (Exception e) {
                System.debug('ERROR: ' + e.getMessage());
            }
        }
        return outputData;
    }

    private void updateOrderWithMinorLineItems(ccrz__E_Order__c order, List<ccrz__E_OrderItem__c> orderItems) {
        Map<String, ccrz__E_OrderItem__c> productToMajorLineItem = new Map<String, ccrz__E_OrderItem__c>();
        List<String> productIds = new List<Id>();

        for (ccrz__E_OrderItem__c orderItem : orderItems) {
            if (orderItem.ccrz__OrderLineType__c != null &&
                    orderItem.ccrz__OrderLineType__c.equalsIgnoreCase(ACAMSUtil.MAJOR) &&
                    orderItem.ccrz__Product__r.ccrz__ProductType__c.equalsIgnoreCase(ACAMSUtil.BUNDLE)) {
                productToMajorLineItem.put(orderItem.ccrz__Product__c, orderItem);
                productIds.add(orderItem.ccrz__Product__c);
            }
        }

        if (productIds != null && !productIds.isEmpty()) {
            List<ccrz__E_OrderItem__c> newMinorItems = new List<ccrz__E_OrderItem__c>();
            List<ccrz__E_CompositeProduct__c> childBundles = ACAMSProductDAO.getChildBundles(productIds);

            if (childBundles != null && !childBundles.isEmpty()) {
                for (ccrz__E_CompositeProduct__c childBundle : childBundles) {
                    ccrz__E_OrderItem__c parentOrderItem = productToMajorLineItem.get(childBundle.ccrz__Composite__c);
                    ccrz__E_OrderItem__c minorItem = new ccrz__E_OrderItem__c();
                    minorItem.ccrz__Order__c = order.Id;
                    minorItem.ccrz__Price__c = 0.00;
                    minorItem.ccrz__Quantity__c = parentOrderItem.ccrz__Quantity__c;
                    minorItem.ccrz__SubAmount__c = 0.00;
                    minorItem.ccrz__RequestDate__c = parentOrderItem.ccrz__RequestDate__c;
                    minorItem.ccrz__PricingType__c = ACAMSUtil.AUTO;
                    minorItem.ccrz__OrderLineType__c = ACAMSUtil.MINOR;
                    minorItem.ccrz__Product__c = childBundle.ccrz__Component__c;
                    minorItem.ccrz__ProductType__c = ACAMSUtil.BUNDLE;
                    minorItem.ccrz__ParentOrderItem__c = parentOrderItem.Id;
                    minorItem.ccrz__StoreId__c = parentOrderItem.ccrz__StoreId__c;
                    minorItem.ccrz__OriginalQuantity__c = parentOrderItem.ccrz__OriginalQuantity__c;
                    minorItem.ccrz__OriginalItemPrice__c = 0.00;
                    newMinorItems.add(minorItem);
                }
                insert newMinorItems;
            }
        }
    }

    private void updateOrderWithOrderShipments(ccrz__E_Order__c order, List<ccrz__E_OrderItem__c> orderItems) {
        List<ccrz__E_OrderShipment__c> orderShipments = new List<ccrz__E_OrderShipment__c>();
        List<ccrz__E_OrderShipmentItem__c> orderShipmentItems = new List<ccrz__E_OrderShipmentItem__c>();

        Integer orderItemCount = 1;
        for (ccrz__E_OrderItem__c orderItem : orderItems) {
            ccrz__E_OrderShipment__c orderShipment = new ccrz__E_OrderShipment__c();
            orderShipment.ccrz__Order__c = order.Id;
            orderShipment.ccrz__OrderShipmentId__c = order.ccrz__OrderNumber__c + '-' + orderItemCount++;
            orderShipment.ccrz__ShippingMethod__c = order.ccrz__ShipMethod__c;
            if (orderItem.ccrz__Product__r.ccrz__ShippingWeight__c > 0 && orderItem.ccrz__Product__r.ccrz__ProductType__c != ACAMSUtil.BUNDLE) {
                orderShipment.Status__c = ACAMSUtil.RELEASED;
                orderShipment.Shipment_Type__c = ACAMSUtil.PHYSICAL;
            } else {
                orderShipment.Status__c = ACAMSUtil.RELEASED;
                orderShipment.Shipment_Type__c = ACAMSUtil.DIGITAL;
            }
            orderShipment.Order_Shipment_Email__c = order.ccrz__Contact__r.Email;
            if (order.ccrz__ShipTo__c != null) {
                orderShipment.Shipping_Address__c = order.ccrz__ShipTo__c;
            }
            orderShipment.CC_Order_Item__c = orderItem.Id;
            orderShipments.add(orderShipment);
        }
        insert orderShipments;

        Integer index = 0;
        for (ccrz__E_OrderShipment__c orderShipment : orderShipments) {
            ccrz__E_OrderShipmentItem__c orderShipmentItem = new ccrz__E_OrderShipmentItem__c();
            orderShipmentItem.ccrz__OrderShipment__c = orderShipment.Id;
            orderShipmentItem.ccrz__Quantity__c = 1;
            orderShipmentItem.ccrz__SKU__c = orderItems.get(index).ccrz__Product__r.ccrz__SKU__c;
            orderShipmentItems.add(orderShipmentItem);
        }
        insert orderShipmentItems;
    }

    @Future
    public static void addNumberOfOrdersToAccount(Id accountId) {
        List<ccrz__E_Order__c> orderList = [
                SELECT
                        Id
                FROM
                        ccrz__E_Order__c
                WHERE
                ccrz__Account__c = :accountId
                AND
                ccrz__Name__c != :ACAMSUtil.REFUNDED_ORDER
        ];

        List<Account> accounts = [
                SELECT
                        Id, Number_of_Orders__c
                FROM
                        Account
                WHERE
                        Id = :accountId
        ];

        if (!accounts.isEmpty()) {
            Account account = accounts.get(0);
            account.Number_of_Orders__c = orderList.size();
            if (Schema.SObjectType.Account.isUpdateable()) {
                update account;
            }
        }
    }

    @Future
    private static void stampOrders(Id orderId) {

        ccrz__E_Order__c orderToUpdate = ACAMSOrderDAO.getOrder(orderId);

        if (orderToUpdate.ccrz__Account__r.RecordType.DeveloperName == ACAMSUtil.ACCOUNT_RECORD_TYPE_BUSINESS) {
            orderToUpdate.ccrz__BuyerCompanyName__c = orderToUpdate.ccrz__Account__r.Name;
            orderToUpdate.Account_Owner__c = orderToUpdate.ccrz__Account__r.OwnerId;
        } else {
            orderToUpdate.ccrz__BuyerCompanyName__c = orderToUpdate.ccrz__Account__r.ccrz__CompanyName__pc;
            orderToUpdate.Account_Owner__c = orderToUpdate.ccrz__Account__r.CommunityUser__c;
        }
        if (orderToUpdate.Opportunity__c != null) {
            orderToUpdate.Opportunity_Owner__c = orderToUpdate.Opportunity__r.OwnerId;
        }

        orderToUpdate.BillTo_City__c = orderToUpdate.ccrz__BillTo__r.ccrz__City__c;
        orderToUpdate.BillTo_AddressFirstLine__c = orderToUpdate.ccrz__BillTo__r.ccrz__AddressFirstline__c;
        orderToUpdate.BillTo_StateISOCode__c = orderToUpdate.ccrz__BillTo__r.ccrz__State__c;
        orderToUpdate.BillTo_PostalCode__c = orderToUpdate.ccrz__BillTo__r.ccrz__PostalCode__c;
        orderToUpdate.BillTo_CountryISOCode__c = orderToUpdate.ccrz__BillTo__r.ccrz__CountryISOCode__c;
        orderToUpdate.BillTo_Named_Territory__c = orderToUpdate.ccrz__BillTo__r.Named_Territory__c;
        orderToUpdate.BillTo_Region__c = orderToUpdate.ccrz__BillTo__r.Region__c;
        orderToUpdate.BillTo_SubTerritory__c = orderToUpdate.ccrz__BillTo__r.SubTerritory__c;
        orderToUpdate.Enterprise_Account__c = orderToUpdate.Account_Group__r.Enterprise_Account__c;
        orderToUpdate.Industry__c = orderToUpdate.ccrz__Account__r.Industry;

        List<ccrz__E_Order__c> orderList = [
                SELECT
                        Id
                FROM
                        ccrz__E_Order__c
                WHERE
                        ccrz__Account__c = :orderToUpdate.ccrz__Account__c
                AND
                        ccrz__Name__c != :ACAMSUtil.REFUNDED_ORDER
        ];

        if (orderList.size() > 1) {
            orderToUpdate.New_or_Existing__c = 'Existing';
        } else {
            orderToUpdate.New_or_Existing__c = 'New';
        }

        Map<String, Profile> profileMap = ACAMSUserDAO.getProfilesMap(new Set<String>{
                ACAMSUtil.SALES_PROFILE, ACAMSUtil.CSR_PROFILE
        });
        Profile salesProfile = profileMap.containsKey(ACAMSUtil.SALES_PROFILE) ? profileMap.get(ACAMSUtil.SALES_PROFILE) : null;
        Profile customerServiceProfile = profileMap.containsKey(ACAMSUtil.CSR_PROFILE) ? profileMap.get(ACAMSUtil.CSR_PROFILE) : null;
        User userFromOrder = [
                SELECT
                        Id, ProfileId
                FROM
                        User
                WHERE
                        Id = :orderToUpdate.OwnerId
        ];
        if (salesProfile != null && userFromOrder.ProfileId == salesProfile.Id) {
            orderToUpdate.Channel__c = 'Sales';
        } else if (orderToUpdate.Opportunity__c == null && (!orderToUpdate.ccrz__BuyerEmail__c.equals(orderToUpdate.Purchaser_Email__c))) {
            orderToUpdate.Channel__c = 'Web Assisted';
        } else if (orderToUpdate.Opportunity__c == null) {
            orderToUpdate.Channel__c = 'Web Order';
        } else if (customerServiceProfile != null && userFromOrder.ProfileId == customerServiceProfile.Id) {
            orderToUpdate.Channel__c = 'Customer Service';
        }

        if (orderToUpdate.Opportunity__c == null) {
            if (orderToUpdate.Number_of_B2B_Order_Items__c > 0) {
                orderToUpdate.Type__c = 'B2B';
            } else if (orderToUpdate.Number_of_B2B_Order_Items__c == 0) {
                orderToUpdate.Type__c = 'B2C';
            }
        } else if (orderToUpdate.Opportunity__c != null) {
            if (orderToUpdate.ccrz__Account__r.RecordType.DeveloperName == ACAMSUtil.ACCOUNT_RECORD_TYPE_PERSON) {
                orderToUpdate.Type__c = 'B2C';
            } else {
                orderToUpdate.Type__c = 'B2B';
            }
        }
        if (orderToUpdate.Number_of_B2B_Order_Items__c > 0) {
            createUnassignedAssetsCase(orderToUpdate);
        }
        update orderToUpdate;
    }

    private static void createUnassignedAssetsCase(ccrz__E_Order__c order) {
        Case unassignedAssetCase = new Case();

        unassignedAssetCase.CC_Order__c = order.Id;
        unassignedAssetCase.Subject = 'Unassigned Assets on Order: ' + order.Name;
        unassignedAssetCase.Description = 'Unassigned Assets on created Order';
        unassignedAssetCase.ContactId = order.ccrz__Contact__c;
        unassignedAssetCase.AccountId = order.ccrz__Account__c;
        unassignedAssetCase.Origin = 'Order';
        unassignedAssetCase.Type = 'Revenue Impacting';
        unassignedAssetCase.Secondary_Case_Type__c = 'Group Orders';

        insert unassignedAssetCase;
    }
}