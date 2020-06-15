public without sharing class ACAMSUserTriggerHandler extends CCAviTriggerHandler {
    private List<User> newUsers;
    private Map<Id, User> newMap;
    private Map<Id, User> oldMap;
    public class customException extends Exception {
    }
    public static Boolean raiseException = false;
    public static Boolean isLMSUserCreated = false;
    public static Boolean isLMSUserUpdated = false;

    public ACAMSUserTriggerHandler() {
        this.newUsers = (List<User>) Trigger.new;
        this.newMap = (Map<Id, User>) Trigger.newMap;
        this.oldMap = (Map<Id, User>) Trigger.oldMap;
    }

    public override void afterInsert() {
        Id b2bCommerceUserId;

        Profile profile = ACAMSUserDAO.getB2BProfile();
        b2bCommerceUserId = profile != null ? profile.Id : null;
        ccrz__E_AccountGroup__c portalAccount = ACAMSUserDAO.getAccountGroupByName(ACAMSUtil.PORTAL_ACCOUNT);
        ccrz__E_AccountGroup__c govMilPortalAccount =
                ACAMSUserDAO.getAccountGroupByName(ACAMSUtil.PORTAL_ACCOUNT_GOV);

        Set<Id> accountIds = new Set<Id>();

        if (b2bCommerceUserId != null) {
            for (User u : this.newUsers) {
                if (u.ProfileId == b2bCommerceUserId) {
                    accountIds.add(u.AccountId);
                }
            }

            List<Account> accounts = ACAMSAccountDAO.getPersonAccountsFromIds(accountIds);
            Set<Id> userIds = new Set<Id>();
            for (Id userId : newMap.keySet()) {
                if (newMap.get(userId).ContactId != null) {
                    userIds.add(userId);
                }
            }

            Map<Id, Id> accountIdToCommunityIdMap = new Map<Id, Id>();
            Map<Id, User> usersMap = new Map<Id, User>(
                    ACAMSUserDAO.queryContactAccountsByIds(userIds)
            );

            for (Id userId : userIds) {
                try {
                    Id accountId = usersMap.get(userId).Contact.AccountId;
                    Id communityId = usersMap.get(userId).Contact.Account.CommunityUser__c;
                    if (communityId != userId) {
                        accountIdToCommunityIdMap.put(accountId, userId);
                    }
                } catch (Exception ex) {
                    System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
                }
            }
            for (Account account : accounts) {
                if (account.PersonEmail.endsWith('.gov') || account.PersonEmail.endsWith('.mil')) {
                    account.ccrz__E_AccountGroup__c = govMilPortalAccount.Id;
                } else {
                    account.ccrz__E_AccountGroup__c = portalAccount.Id;
                }
                account.Type = ACAMSUtil.CUSTOMER;
                Id communityId = accountIdToCommunityIdMap.get(account.Id);
                account.CommunityUser__c = communityId;
            }

            if (Test.isRunningTest()) {
                update accounts;
            } else if (!System.isFuture() && !accounts.isEmpty()) {
                System.enqueueJob(new ACAMSUtil.UpdateObject(accounts));
            }
        }
    }
    public override void afterUpdate() {

        if (!isLMSUserUpdated) {
            UpsertLMSUser(this.newUsers, this.oldMap);
        }
    }

    public static void UpsertLMSUser(List<User> newUsers, Map<Id, User> oldMapUsers) {
        try {
            if (raiseException) throw new customException('Testing code');

            Set<Id> contactIds = new Set<Id>();
            Map<Id, Contact> contactsMap = new Map<Id, Contact>();
            List<LMSUtility.LMSUserRequest> lmsuserList = new List<LMSUtility.LMSUserRequest>();

            System.debug('*****UserHelper.UpsertLMSUser.newUsers: ' + newUsers);
            System.debug('*****UserHelper.UpsertLMSUser.oldMapUsers: ' + oldMapUsers);

            if (newUsers != null && newUsers.size() > 0) {
                System.debug('pass 1');
                for (User u : newUsers) {
                    User oldU = (oldMapUsers != null && oldMapUsers.size() > 0 ? oldMapUsers.get(u.Id) : null);
                    //When LMS to SF sync in place: LMSIntegration user update should be excluded
                    if (u.ContactId != null && ((oldU == null && u.LMS_Role__c != 'STUDENT') || (oldU != null && (u.LMS_Role__c != oldU.LMS_Role__c || u.TimeZoneSidKey != oldU.TimeZoneSidKey || u.Membership_Type__c != oldU.Membership_Type__c)))) {
                        System.debug('pass 2');
                        isLMSUserCreated = (oldMapUsers != null && oldMapUsers.size() > 0);
                        isLMSUserUpdated = !isLMSUserCreated;
                        LMSUtility.LMSUserRequest lmsuser = new LMSUtility.LMSUserRequest();
                        lmsuser.contactId = u.AccountId;
                        lmsuser.username = u.Username;
                        lmsuser.firstName = u.FirstName;
                        System.debug('New user fname' + u.FirstName);
                        lmsuser.lastName = u.LastName;
                        lmsuser.role = u.LMS_Role__c;
                        lmsuser.timezone = ''; //--lmsuser.timezone = u.TimeZoneSidKey;
                        lmsuser.enabled = true;
                        if (u.Contact_Member_Type__c != 'MEMBER' && u.Contact_Member_Type__c != null) {
                            if (u.Contact_Member_Type__c == 'NON-MEMBER') {
                                lmsuser.customerType = 'NON_MEMBER';
                            } else {
                                lmsuser.customerType = u.Contact_Member_Type__c;
                            }
                        } else {
                            lmsuser.customerType = 'ENTERPRISE';
                        }
                        lmsuserList.add(lmsuser);

                        contactIds.add(u.ContactId);
                    }
                }
                System.debug('*****UserHelper.UpsertLMSUser.contactIds: ' + contactIds);

                if (contactIds.size() > 0) {
                    //When new Language field is added: Language should be added
                    for (Contact c : [SELECT Id, FirstName, LastName FROM Contact WHERE Id IN:contactIds]) {
                        contactsMap.put(c.Id, c);
                    }
                    for (LMSUtility.LMSUserRequest lmsU : lmsuserList) {
                        if (contactsMap.containsKey(lmsU.contactId)) {
                            Contact c = contactsMap.get(lmsU.contactId);
                            lmsU.firstName = (String.isNotBlank(c.FirstName) && c.FirstName != lmsU.firstName ? c.FirstName : lmsU.firstName);
                            lmsU.lastName = (String.isNotBlank(c.LastName) && c.LastName != lmsU.lastName ? c.LastName : lmsU.lastName);
                            lmsU.language = '';
                        }
                    }
                    System.debug('*****UserHelper.UpsertLMSUser.contactsMap: ' + contactsMap);
                }
            }
            System.debug('*****UserHelper.UpsertLMSUser.lmsuserList: ' + lmsuserList);

            if (lmsuserList.size() > 0) {
                CalloutUtility.SendRequest('UserIntegration', true, LMSUtility.BuildJson(lmsuserList));
            }
        } catch (Exception ex) {

        }
    }
}