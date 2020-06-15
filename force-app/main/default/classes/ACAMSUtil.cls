public with sharing class ACAMSUtil {
    /** Utility class for static string constants and utility methods */

    /* STRING CONSTANTS */
    public static final String ACAMS_TODAY = 'ACAMS Today';
    public static final String ACCOUNT_RECORD_TYPE_BUSINESS = 'Business_Account';
    public static final String ACCOUNT_RECORD_TYPE_PERSON = 'PersonAccount';
    public static final String ACH_CAPS = 'ACH';
    public static final String ACTIVE = 'Active';
    public static final String ADVANCED = 'Advanced';
    public static final String ASYNCHRONOUS = 'Asynchronous';
    public static final String ATTENDANCE = 'Attendance';
    public static final String AUTHORIZATION = 'authorization';
    public static final String AUTO = 'auto';
    public static final String B2B_COMMERCE_USER = 'B2B Storefront Registered Users acams';
    public static final String BUNDLE = 'Bundle';
    public static final String CAMS = 'CAMS';
    public static final String CAPTURE = 'capture';
    public static final String CASE_SUBTYPE_PAYMENT = 'Payment';
    public static final String CASE_TYPE_REVENUE = 'Revenue Impacting';
    public static final String CC = 'Credit Card';
    public static final String CERTIFICATE_COURSES = 'Certificate Courses';
    public static final String CERTIFICATES = 'Certificates';
    public static final String CERTIFICATION = 'Certification';
    public static final String CGSS = 'CGSS';
    public static final String CHAPTER = 'Chapter';
    public static final String CHECK = 'Check';
    public static final String CHECK_REFUND_CASE = 'An order purchased by Check has been refunded';
    public static final String COMPLETED = 'Completed';
    public static final String CONFERENCES = 'Conferences';
    public static final String CREDIT = 'CREDIT';
    public static final String CREDIT_TYPE_REFUND = 'Refund';
    public static final String CSR_ZERO_DOLLAR = 'CSR Zero Dollar';
    public static final String CSR_PROFILE = 'ACAMS - Customer Service';
    public static final String CUSTOM_TRAINING = 'Custom Training';
    public static final String CUSTOMER = 'Customer';
    public static final String DIGITAL = 'DIGITAL';
    public static final String ENTERPRISE_CAPS = 'ENTERPRISE';
    public static final String ENTERPRISE_BUNDLE = 'Enterprise Bundle';
    public static final String EVENT = 'Event';
    public static final String EVENTS = 'Events';
    public static final String EXAM_PREP = 'Exam Prep';
    public static final String FACE_TO_FACE = 'Face to Face';
    public static final String INACTIVE = 'Inactive';
    public static final String IN_PROCESS = 'In Process';
    public static final String KIT = 'Kit';
    public static final String DYNAMIC_KIT = 'Dynamic Kit';
    public static final String MAJOR = 'Major';
    public static final String MEMBER_CAPS = 'MEMBER';
    public static final String MEMBERSHIP = 'Membership';
    public static final String MINOR = 'Minor';
    public static final String MONEYLAUNDERINGDOTCOM = 'Moneylaundering.com';
    public static final String NO_UPGRADE_MSG = 'You have not previously enrolled in the lower tier product.';
    public static final String NON_MEMBER_CAPS = 'NON-MEMBER';
    public static final String ON_HOLD = 'On Hold';
    public static final String ORDER_ITEM_STATUS_REFUNDED_CREDIT = 'Refunded - Credit';
    public static final String ORDER_NUMBER_START = '1000000'; // TODO: Change to correct value
    public static final String ORDER_STATUS_REFUNDED_CREDIT = 'Refunded - Credit';
    public static final String ORDER_SUBMITTED = 'Order Submitted';
    public static final String PARTNERSHIPS = 'Partnerships';
    public static final String PAYMENT = 'Payment';
    public static final String PHYSICAL = 'PHYSICAL';
    public static final String PO = 'po';
    public static final String PORTAL_ACCOUNT = 'PortalAccount';
    public static final String PORTAL_ACCOUNT_GOV = 'PortalAccount-Government/Non-Member';
    public static final String PORTAL_ACCOUNT_MEMBER = 'PortalAccount-Private/Member';
    public static final String PORTAL_ACCOUNT_GOV_MEMBER = 'PortalAccount-Government/Member';
    public static final String PREREQUISITE_MSG = 'You have not carted or purchased the prerequisite product(s).';
    public static final String PRICELIST_PRIVATE_NON_MEMBER = 'Private/Non-Member';
    public static final String PRICELIST_PRIVATE_MEMBER = 'Private/Member';
    public static final String PRINTED_SUBSCRIPTION = 'Printed Subscription';
    public static final String PUBLICATIONS = 'Publications';
    public static final String RELEASED = 'RELEASED';
    public static final String REPLACE_PRODUCT_MSG = 'Previously carted product was replaced by the now displayed product.';
    public static final String CANCELLED = 'Cancelled';
    public static final String REFUNDED = 'Refunded';
    public static final String REFUNDED_CREDIT_ORDER = 'Refunded Credit Order';
    public static final String REFUNDED_ORDER = 'Refunded Order';
    public static final String REGIME_EXAM = 'Regime Exam';
    public static final String SALES_PROFILE = 'ACAMS - Sales';
    public static final String SEMINARS = 'Seminars';
    public static final String SHIPPING_PRODUCT_SKU = 'SHPCST';
    public static final String SPONSORSHIP = 'Sponsorship';
    public static final String TRAINING = 'Training';
    public static final String USER_EMAIL = 'userEmail';
    public static final String VIRTUAL_CLASSROOM = 'Virtual Classroom';
    public static final String WEBINARS = 'Webinars';
    public static final String WIRE_TRANSFER = 'Wire Transfer';
    public static final String WIRE_TRANSFER_REFUND_CASE = 'An order purchased by Wire Transfer has been refunded';
    public static final String WT_CAPS = 'WT';
    public static final String ZERO_DOLLAR_API = 'zero_dollar';
    public static final String ZERO_DOLLAR = 'Zero Dollar';

    public class UpdateObject implements Queueable {
        List<SObject> toUpdate;

        public UpdateObject(List<SObject> toUpdate) {
            this.toUpdate = toUpdate;
        }

        public void execute(QueueableContext context) {
            try {
                update toUpdate;
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, e.getMessage() + '\n' + e.getStackTraceString());
            }
        }
    }

    public static String getISO3Country(String country) {
        List<String> countrySettings = new List<String>();
        for (CountrySettings__mdt countrySetting : [
                SELECT IsoCode_3__c
                FROM CountrySettings__mdt
                WHERE IsoCode_2__c = :country
        ]) {
            countrySettings.add(countrySetting.IsoCode_3__c);
        }

        if (countrySettings != null) {
            return countrySettings[0];
        }
        return '';
    }

    public static String getPhonecode(String country) {
        List<String> countrySettings = new List<String>();
        for (CountrySettings__mdt countrySetting : [
                SELECT PhoneCode__c
                FROM CountrySettings__mdt
                WHERE IsoCode_2__c = :country
        ]) {
            countrySettings.add(countrySetting.PhoneCode__c);
        }

        if (countrySettings != null) {
            return countrySettings[0];
        }
        return '';

    }

    public static String getISO2DigitState(String state) {
        List<StateSettings__mdt> stateSettings = [
                SELECT  IsoCode__c
                FROM    StateSettings__mdt
                WHERE   MasterLabel = :state
                LIMIT   1
        ];

        if (!stateSettings.isEmpty()) {
            return stateSettings[0].IsoCode__c;
        } else {
            stateSettings = [
                    SELECT  IsoCode__c
                    FROM    StateSettings__mdt
                    WHERE   IsoCode__c = :state
                    LIMIT   1
            ];
            if (!stateSettings.isEmpty()) {
                return stateSettings[0].IsoCode__c;
            }
        }
        return '';
    }

    public static Boolean isEvent(ccrz__E_OrderItem__c orderItem) {
        if (orderItem.ccrz__Product__r.Level_1__c.equalsIgnoreCase('Conferences')) {
            return true;
        }

        if (orderItem.ccrz__Product__r.Level_1__c.equalsIgnoreCase('Training')) {
            if (orderItem.ccrz__Product__r.Level_2__c != null &&
                    (orderItem.ccrz__Product__r.Level_2__c.equalsIgnoreCase('Webinars') ||
                            orderItem.ccrz__Product__r.Level_2__c.equalsIgnoreCase('Seminars')) ||
                    (orderItem.ccrz__Product__r.Level_2__c.equalsIgnoreCase('Certificates') &&
                            orderItem.ccrz__Product__r.Level_3__c.equalsIgnoreCase('Asynchronous')) ||
                    (orderItem.ccrz__Product__r.Level_2__c.equalsIgnoreCase('Exam Prep') &&
                            orderItem.ccrz__Product__r.Level_3__c.equalsIgnoreCase('Face to Face')) ||
                    (orderItem.ccrz__Product__r.Level_2__c.equalsIgnoreCase('Custom') &&
                            !orderItem.ccrz__Product__r.Level_3__c.equalsIgnoreCase('Asynchronous'))) {
                return true;
            }
        }

        if (orderItem.ccrz__Product__r.Level_1__c.equalsIgnoreCase('Chapter')) {
            if (orderItem.ccrz__Product__r.Level_2__c != null &&
                    orderItem.ccrz__Product__r.Level_2__c.equalsIgnoreCase('Event')) {
                return true;
            }
        }

        return false;
    }
}