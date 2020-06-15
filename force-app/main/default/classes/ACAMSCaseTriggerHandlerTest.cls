@IsTest
class ACAMSCaseTriggerHandlerTest {

    @IsTest
    static void createCaseWithCountry() {
        List<Case> testCases = new List<Case>{
                new Case(
                        Subject = 'Test 1',
                        AddressCountry__c = 'CA'
                ),
                new Case(
                        Subject = 'Test 2',
                        AddressCountry__c = 'AU'
                )
        };
        insert testCases;
        for (Case testCase : [
                SELECT AddressCountry__c, AddressRegion__c
                FROM Case
                WHERE Id IN :testCases
        ]) {
            if (testCase.AddressCountry__c == 'CA') {
                System.assertEquals('Americas', testCase.AddressRegion__c);
            } else if (testCase.AddressCountry__c == 'AU') {
                System.assertEquals('APAC', testCase.AddressRegion__c);
            }
        }
    }

    @IsTest
    static void test1() {
        List<Case> newlist = new List<Case>();
        Map<Id, Case> oldMap = new Map<Id, Case>();

        Case c = new Case();
        c.Subject = 'Test Case';
        c.Description = 'Test Case';
        c.Origin = 'Email - Europe';
        c.Type = 'Other';
        c.Target_Close_Date__c = System.now();

        //insert c;
        newlist.add(c);
        //oldmap.put(c.id, c);

        Case c1 = new Case();
        c1.Subject = 'Test Case 1';
        c1.Description = 'Test Case 1';
        c1.Origin = 'Email - Europe';
        c1.Type = 'Revenue Impacting';
        // insert c1;
        newlist.add(c1);
        //oldmap.put(c1.id, c1);

        Case c2 = new Case();
        c2.Subject = 'Test Case 2';
        c2.Description = 'Test Case 2';
        c2.Origin = 'Email - Asia';
        c2.Type = 'Other';
        // insert c2;
        newlist.add(c2);
        //oldmap.put(c2.id, c2);

        Case c3 = new Case();
        c3.Subject = 'Test Case 3';
        c3.Description = 'Test Case 3';
        c3.Origin = 'Email - Asia';
        c3.Type = 'Revenue Impacting';
        //insert c3;
        newlist.add(c3);
        //oldmap.put(c3.id, c3);

        Case c4 = new Case();
        c4.Subject = 'Test Case 4';
        c4.Description = 'Test Case 4';
        c4.Origin = 'Email - Test';
        c4.Type = 'Other';
        //insert c4;
        newlist.add(c4);
        //oldmap.put(c4.id, c4);

        Case c5 = new Case();
        c5.Subject = 'Test Case 4';
        c5.Description = 'Test Case 4';
        c5.Origin = 'Email - Test';
        c5.Type = 'Urgent';
        //insert c5;
        newlist.add(c5);
        //oldmap.put(c5.id, c5); 

        insert newlist;

        update newlist;

        Test.startTest();
        List<BusinessHours> bhs = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE];
        //BusinessHours cstory1=[select id from businesshours where name = 'Asia Hours' limit 1];
        //BusinessHours cstory2=[select id from businesshours where name = 'Europe Hours' limit 1];

        //c.origin=cstory1.name;
        //Update c;

        //newlist.add(cstory1);
        //ACAMSCaseTriggerHandler ac = new ACAMSCaseTriggerHandler();
        //ac.getCaseWithBusinessHours(newlist,oldMap);
        Test.stopTest();
    }
}