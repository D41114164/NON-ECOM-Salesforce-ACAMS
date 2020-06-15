global without sharing class ACAMSSSOController {
    global String username { get; set; }
    global String password { get; set; }

    public String relaystate { get; set; }
    public String appName;
    public String pgtype { get; set; }
    public String pg { get; set; }
    public Boolean isLoginFailed { get; set; }
    public String registerPage { get; set; }

    public String drupalUrl = '';
    public String drupalRegisterUrl = '';


    global ACAMSSSOController() {
        isLoginFailed = false;
        pgtype = '';
        relaystate = System.currentPageReference().getParameters().get('RelayState');
        appName = System.currentPageReference().getParameters().get('AppName');
        pgtype = System.currentPageReference().getParameters().get('page');
        pg = System.currentPageReference().getParameters().get('pg');
        registerPage = '/store/SiteRegistrationPage';
        if (appName == null && pg == null) {
            appName = 'higherlogic';    //  default app name
        } else if (appName == 'lms') {
            registerPage += '?page=lms';
        }
        getDrupalInfo();
    }

    global PageReference redirect() {
        if (UserInfo.getUserType() != 'Guest') {
            return login();
        }
        return null;
    }

    global PageReference login() {
        ACAMSUserLogin.LoginResponse loginResponse;
        String rUrl = getRelayUrl();
        String startUrl = System.currentPageReference().getParameters().get('startUrl');
        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        String domain = isSandbox ? 'test' : 'login';
        loginResponse = ACAMSUserLogin.login(username, password, domain);

        if ((String.isBlank(startUrl) || !String.isBlank(rUrl)) && pg == null) {
            startUrl = rUrl;
        } else if (String.isBlank(startUrl) && pg != null) {
            startUrl = '/' + pg;
        }
        //  Redirect if User Already Logged in
        PageReference pageRef;
        if (UserInfo.getUserType() == 'Guest') {
            pageRef = Site.login(username, password, startUrl);
        } else {
            pageRef = new PageReference(startUrl);
        }
        return pageRef;
    }

    public String getRelayUrl() {
        String relaySubstr;
        String relayString = '';

        try {
            IDP_App_ID__mdt[] IDP_App_IDs = [
                    SELECT
                            MasterLabel,
                            External_ACAMS_IDPAppID_ID__c,
                            ID__c,
                            Long_Name__c,
                            Source_IDP_App_ID_ID__c
                    FROM IDP_App_ID__mdt
                    WHERE MasterLabel = :appName
                    LIMIT 1
            ];
            String idpID = '';
            if (!IDP_App_IDs.isEmpty()) {
                idpID = IDP_App_IDs[0].ID__c;
            }
            String idpStart = '/idp/login?app=' + idpID; // IdP initiated URL provided by SFDC
            relaySubstr = '&RelayState=' + relaystate;
            if (relaySubstr != '&RelayState=null') {
                relayString = idpStart + relaySubstr; // add the relay state
            } else {
                relayString = idpStart;
            }
        } catch (Exception x) {
            System.debug('Error: ' + x.getMessage());
        }

        return relayString;
    }

    public void getDrupalInfo() {
        try {
            Drupal_URLs__mdt[] drupalUrls = [
                    SELECT
                            MasterLabel,
                            Drupal_URL__c,
                            Drupal_URL_Register__c
                    FROM
                            Drupal_URLs__mdt
                    LIMIT
                            1
            ];

            if (!drupalUrls.isEmpty()) {
                drupalUrl = drupalUrls[0].Drupal_URL__c;
                drupalRegisterUrl = drupalUrls[0].Drupal_URL_Register__c;
            }

        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    public String getDrupalUrl() {
        return drupalUrl;
    }

    public String getDrupalRegisterUrl() {
        return drupalRegisterUrl;
    }
}