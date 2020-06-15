@IsTest
public class ExamResultHelper_Test {

    static CCAviTestUtil util = new CCAviTestUtil();

    @IsTest
    static void UpdateCertResult_test() {
        Map<String, Object> testData = util.initData();
        Date myDate = Date.newInstance(1990, 11, 21);

        Contact con = (Contact) testData.get(CCAviTestUtil.PN_USER_CONTACT);

        Voucher__c voucher = new Voucher__c();
        voucher.Contact__c = con.Id;
        voucher.Product_Code__c = 'CAMS English';
        insert voucher;

        Exam_Results__c exam = new Exam_Results__c();
        List<Exam_Results__c> examlist = new List<Exam_Results__c>();
        exam.Contact__c = con.Id;
        exam.Voucher_Code__c = voucher.Id;
        exam.Result__c = 'Pass';
        exam.Exam_Type__c = 'CAMS';
        exam.Test_Date__c = myDate;
        examlist.add(exam);
        insert exam;

        Exam_Results__c exam2 = new Exam_Results__c();
        List<Exam_Results__c> examlist2 = new List<Exam_Results__c>();
        exam2.Contact__c = con.Id;
        exam2.Voucher_Code__c = voucher.Id;
        exam2.Result__c = 'Pass';
        exam2.Exam_Type__c = 'Singapore AML Regime Exam';
        exam2.Test_Date__c = myDate;
        examlist2.add(exam2);
        insert exam2;

        Regional_Funding__c rg = new Regional_Funding__c();
        List<Regional_Funding__c> rglist = new List<Regional_Funding__c>();
        rg.Status__c = 'exam App Approved';
        rg.Contact__c = con.Id;
        rglist.add(rg);
        insert rg;

        ExamResultHelper.UpdateCertResult(examlist);
        List<Regional_Funding__c> regList = [
                SELECT
                        Id,
                        Passed_AML_Regime_Exam_Date__c,
                        Passed_CAMS_Exam_Date__c
                FROM
                        Regional_Funding__c
                WHERE
                        Contact__c = :con.Id
        ];
        System.assert(regList.get(0).Passed_CAMS_Exam_Date__c == myDate);
        ExamResultHelper.UpdateCertResult(examlist2);
        regList = [
                SELECT
                        Id,
                        Passed_AML_Regime_Exam_Date__c,
                        Passed_CAMS_Exam_Date__c
                FROM
                        Regional_Funding__c
                WHERE
                        Contact__c = :con.Id
        ];
        System.assert(regList.get(0).Passed_AML_Regime_Exam_Date__c == myDate);
    }

    @IsTest
    static void UpdateCertResult2_test() {
        Map<String, Object> testData = util.initData();
        Date myDate = Date.newInstance(1990, 11, 21);

        Contact con = (Contact) testData.get(CCAviTestUtil.PN_USER_CONTACT);

        Voucher__c voucher = new Voucher__c();
        voucher.Contact__c = con.Id;
        voucher.Product_Code__c = 'CAMS English';
        insert voucher;

        Exam_Results__c exam = new Exam_Results__c();
        List<Exam_Results__c> examlist = new List<Exam_Results__c>();
        exam.Contact__c = con.Id;
        exam.Voucher_Code__c = voucher.Id;
        exam.Result__c = 'Pass';
        exam.Test_Date__c = myDate;
        examlist.add(exam);
        insert exam;

        Regional_Funding__c rg = new Regional_Funding__c();
        List<Regional_Funding__c> rglist = new List<Regional_Funding__c>();
        rg.Status__c = 'exam App Approved';
        rg.Contact__c = con.Id;
        rglist.add(rg);
        insert rg;

        List<Regional_Funding__c> regList = [
                SELECT
                        Id,
                        Passed_AML_Regime_Exam_Date__c,
                        Passed_CAMS_Exam_Date__c
                FROM
                        Regional_Funding__c
                WHERE
                        Contact__c = :con.Id
        ];

        ExamResultHelper.UpdateCertResult(examlist);
        System.assert(regList.get(0).Passed_AML_Regime_Exam_Date__c == null && regList.get(0).Passed_CAMS_Exam_Date__c == null);
    }

    @IsTest
    static void UpsertExamResultOnAsset_test() {
        Map<String, Object> testData = util.initData();
        Date myDate = Date.newInstance(1990, 11, 21);
        Account a = (Account) testData.get(CCAviTestUtil.PN_USER_ACCOUNT);

        System.assert(a.Id != null);
        Contact con = (Contact) testData.get(CCAviTestUtil.PN_USER_CONTACT);
        con.AccountId = a.Id;
        update con;

        Voucher__c voucher = new Voucher__c();
        voucher.Contact__c = con.Id;
        voucher.Product_Code__c = 'CAMS English';
        insert voucher;

        ccrz__E_Product__c prod = (ccrz__E_Product__c) testData.get(CCAviTestUtil.PN_PRODUCT);
        prod.Level_1__c = 'Certification';
        prod.Exam_Code__c = 'test';
        prod.ProductCategory__c = 'Certifications';
        update prod;

        Asset ast = new Asset();
        ast.Name = 'Certifications';
        ast.Status__c = 'Active';
        ast.AccountId = a.Id;
        ast.ContactId = con.Id;
        ast.Assignee__c = con.Id;
        ast.Paid_Cert__c = true;
        ast.EAD_created__c = false;
        ast.CC_Product__c = prod.Id;
        insert ast;

        List<Exam_Results__c> examlist = new List<Exam_Results__c>();
        Exam_Results__c exam = new Exam_Results__c();
        exam.Contact__c = con.Id;
        exam.Voucher_Code__c = voucher.Id;
        exam.Result__c = 'pass';
        exam.Exam_Type__c = 'CAMS';
        exam.Test_Date__c = myDate;
        examlist.add(exam);
        insert exam;

        ExamResultHelper.UpsertExamResultOnAsset(examlist);

        Asset asset1 = [
                SELECT
                        Id, ExamResult__c
                FROM
                        Asset
                WHERE
                        Name = 'Certifications'
        ];
        System.assert(asset1.ExamResult__c != null);
    }

    @IsTest
    static void UpsertExamResultOnAsset2_test() {
        Map<String, Object> testData = util.initData();
        Date myDate = Date.newInstance(1990, 11, 21);

        Account a = (Account) testData.get(CCAviTestUtil.PN_USER_ACCOUNT);

        System.assert(a.Id != null);
        Contact con = (Contact) testData.get(CCAviTestUtil.PN_USER_CONTACT);
        con.AccountId = a.Id;
        update con;

        ccrz__E_Product__c prod = (ccrz__E_Product__c) testData.get(CCAviTestUtil.PN_PRODUCT);
        prod.Level_1__c = 'Certification';
        prod.ProductCategory__c = 'Advanced Certifications';
        prod.Exam_Code__c = 'test';
        prod.ccrz__SKU__c = 'ADV1';
        update prod;

        Asset ast = new Asset();
        ast.Name = 'Advanced Certification';
        ast.Status__c = 'Active';
        ast.AccountId = a.Id;
        ast.ContactId = con.Id;
        ast.Assignee__c = con.Id;
        ast.Paid_Cert__c = true;
        ast.EAD_created__c = false;
        ast.CC_Product__c = prod.Id;
        insert ast;

        Voucher__c voucher = new Voucher__c();
        voucher.Contact__c = con.Id;
        voucher.Product_Code__c = 'CAMS English';
        insert voucher;

        List<Exam_Results__c> examlist = new List<Exam_Results__c>();
        Exam_Results__c exam = new Exam_Results__c();
        exam.Contact__c = con.Id;
        exam.Voucher_Code__c = voucher.Id;
        exam.Result__c = 'pass';
        exam.Exam_Type__c = 'CAMS-Audit';
        exam.Test_Date__c = myDate;
        examlist.add(exam);
        insert exam;

        List<Exam_Results__c> examlist2 = new List<Exam_Results__c>();
        Exam_Results__c exam2 = new Exam_Results__c();
        exam2.Contact__c = con.Id;
        exam2.Voucher_Code__c = voucher.Id;
        exam2.Result__c = 'pass';
        exam2.Exam_Type__c = 'CAMS-FCI';
        exam2.Test_Date__c = myDate;
        examlist2.add(exam2);
        insert exam2;

        ExamResultHelper.UpsertExamResultOnAsset(examlist);
        ExamResultHelper.UpsertExamResultOnAsset(examlist2);
        Asset asset1 = [
                SELECT
                        Id, ExamResult__c
                FROM
                        Asset
                WHERE
                        Name = 'Advanced Certification'
        ];
        System.assert(asset1.ExamResult__c != null);
    }

    @IsTest
    static void UpsertExamResultOnAsset3_test() {
        Map<String, Object> testData = util.initData();
        Date myDate = Date.newInstance(1990, 11, 21);

        Account a = (Account) testData.get(CCAviTestUtil.PN_USER_ACCOUNT);

        System.assert(a.Id != null);
        Contact con = (Contact) testData.get(CCAviTestUtil.PN_USER_CONTACT);
        con.AccountId = a.Id;
        update con;

        ccrz__E_Product__c prod = (ccrz__E_Product__c) testData.get(CCAviTestUtil.PN_PRODUCT);
        prod.Level_1__c = 'Certification';
        prod.ProductCategory__c = 'Advanced Certifications';
        prod.Exam_Code__c = 'test';
        prod.ccrz__SKU__c = 'ADV2';
        update prod;

        Asset ast = new Asset();
        ast.Name = 'Advanced Certification';
        ast.Status__c = 'Active';
        ast.AccountId = a.Id;
        ast.ContactId = con.Id;
        ast.Assignee__c = con.Id;
        ast.Paid_Cert__c = true;
        ast.EAD_created__c = false;
        ast.CC_Product__c = prod.Id;
        insert ast;

        Voucher__c voucher = new Voucher__c();
        voucher.Contact__c = con.Id;
        voucher.Product_Code__c = 'CAMS English';
        insert voucher;

        List<Exam_Results__c> examlist = new List<Exam_Results__c>();
        Exam_Results__c exam = new Exam_Results__c();
        exam.Contact__c = con.Id;
        exam.Voucher_Code__c = voucher.Id;
        exam.Result__c = 'pass';
        exam.Exam_Type__c = 'CAMS-FCI';
        exam.Test_Date__c = myDate;
        examlist.add(exam);
        insert exam;

        ExamResultHelper.UpsertExamResultOnAsset(examlist);
        Asset asset1 = [
                SELECT
                        Id, ExamResult__c
                FROM
                        Asset
                WHERE
                        Name = 'Advanced Certification'
        ];
        System.assert(asset1.ExamResult__c != null);
    }

    @IsTest
    static void UpsertExamResultOnAsset4_test() {
        Map<String, Object> testData = util.initData();
        Date myDate = Date.newInstance(1990, 11, 21);

        Account a = (Account) testData.get(CCAviTestUtil.PN_USER_ACCOUNT);

        System.assert(a.Id != null);
        Contact con = (Contact) testData.get(CCAviTestUtil.PN_USER_CONTACT);
        con.AccountId = a.Id;
        update con;

        ccrz__E_Product__c prod = (ccrz__E_Product__c) testData.get(CCAviTestUtil.PN_PRODUCT);
        prod.Level_1__c = 'Certification';
        prod.ProductCategory__c = 'Certifications';
        prod.ccrz__SKU__c = 'SG-AML-Regime';
        prod.Exam_Code__c = 'test';
        update prod;

        Asset ast = new Asset();
        ast.Name = 'Certification';
        ast.Status__c = 'Active';
        ast.AccountId = a.Id;
        ast.ContactId = con.Id;
        ast.Assignee__c = con.Id;
        ast.Paid_Cert__c = true;
        ast.EAD_created__c = false;
        ast.CC_Product__c = prod.Id;
        insert ast;

        Voucher__c voucher = new Voucher__c();
        voucher.Contact__c = con.Id;
        voucher.Product_Code__c = 'CAMS English';
        insert voucher;

        List<Exam_Results__c> examlist = new List<Exam_Results__c>();
        Exam_Results__c exam = new Exam_Results__c();
        exam.Contact__c = con.Id;
        exam.Voucher_Code__c = voucher.Id;
        exam.Result__c = 'pass';
        exam.Exam_Type__c = 'Singapore AML Regime Exam';
        exam.Test_Date__c = myDate;
        examlist.add(exam);
        insert exam;

        ExamResultHelper.UpsertExamResultOnAsset(examlist);
        Asset asset1 = [
                SELECT
                        Id, ExamResult__c
                FROM
                        Asset
                WHERE
                        Name = 'Certification'
        ];
        System.assert(asset1.ExamResult__c != null);
    }


    @IsTest
    static void SendContactInfo_test() {
        Map<String, Object> testData = util.initData();
        Date myDate = Date.newInstance(1990, 11, 21);

        Set<Id> scnt = new Set<Id>();
        Account a = (Account) testData.get(CCAviTestUtil.PN_USER_ACCOUNT);

        System.assert(a.Id != null);
        Contact con = (Contact) testData.get(CCAviTestUtil.PN_USER_CONTACT);
        con.AccountId = a.Id;
        con.FirstName = 'test';
        con.LastName = 'test';
        con.MailingCountry = 'United States';
        con.Phone = '3221232321';
        con.MailingStreet = 'testtt ttttt ttttttt tttttes ttttttttt tttt ttttttt ttttttttestest test tes test tes test test';
        con.MailingState = 'Florida';
        con.Account_Name_Chinese__c = 'test';
        con.Account_Last_Name_Chinese__c = 'test';
        con.Address_Chinese__c = 'testtt ttttt ttttttt tttttes ttttttttt tttt ttttttt ttttttttestest test tes test tes test test';
        con.Asia_City__c = 'test';
        update con;

        scnt.add(con.Id);
        Voucher__c voucher = new Voucher__c();
        voucher.Contact__c = con.Id;
        voucher.Product_Code__c = 'CAMS English';
        insert voucher;

        List<Exam_Results__c> examlist = new List<Exam_Results__c>();
        Exam_Results__c exam = new Exam_Results__c();
        exam.Contact__c = con.Id;
        exam.Voucher_Code__c = voucher.Id;
        exam.Result__c = 'pass';
        exam.Exam_Type__c = 'CAMS';
        exam.Test_Date__c = myDate;
        examlist.add(exam);
        insert exam;

        ExamResultHelper.SendContactInfo(scnt);
    }
    @IsTest
    static void SendEADInfo_test() {
        Map<String, Object> testData = util.initData();
        Date myDate = Date.newInstance(1990, 11, 21);

        Account a = (Account) testData.get(CCAviTestUtil.PN_USER_ACCOUNT);

        System.assert(a.Id != null);
        Contact con = (Contact) testData.get(CCAviTestUtil.PN_USER_CONTACT);
        con.AccountId = a.Id;
        update con;

        Voucher__c voucher = new Voucher__c();
        voucher.Contact__c = con.Id;
        voucher.Product_Code__c = 'CAMS English';
        insert voucher;

        List<Exam_Results__c> examlist = new List<Exam_Results__c>();
        Set<Id> idlist = new Set<Id>();
        Exam_Results__c exam = new Exam_Results__c();
        exam.Contact__c = con.Id;
        exam.Voucher_Code__c = voucher.Id;
        exam.Result__c = 'pass';
        exam.Exam_Type__c = 'CAMS';
        exam.Test_Date__c = myDate;
        exam.examSeriesCode__c = 'CAMS6_ENU';
        exam.eligibilityApptDateFirst__c = System.today();
        exam.eligibilityApptDateLast__c = System.today() + 180;
        examlist.add(exam);
        insert exam;

        idlist.add(exam.Id);

        ExamResultHelper.SendEADInfo(idlist, 'original', 'Add');
        ExamResultHelper.SendEADInfo(idlist, 'retake', 'Add');
        ExamResultHelper.SendEADInfo(idlist, 'extension', 'update');
    }
}