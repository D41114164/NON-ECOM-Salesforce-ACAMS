/*
 Trigger on Exam Result object. 
* Updates Exam Result on the related asset
* Updates Result on related regional funding record
* Sends Exam Authorization and Contact information to PearsonVue
*/
trigger ExamResult on Exam_Results__c (after insert, after update, before insert, before update) {

    public Data_Migration_User__mdt dMig = new Data_Migration_User__mdt();
    public Set<Id> contactIds = new Set<Id>();
    public Set<Id> eadIds = new Set<Id>();
    public Set<Id> extnsnIds = new Set<Id>();
    public Boolean exec = false;
    public Boolean isPearsonVUE = false;
    public String type;
    PearsonVueIntegration__c pv = PearsonVueIntegration__c.getOrgDefaults();

    try {
        dMig = [SELECT MasterLabel, ProfileId__c FROM Data_Migration_User__mdt WHERE MasterLabel = :'ProfileId' LIMIT 1];
    } catch (Exception e) {
        System.debug('No Data Migration User found in ExamResult.trigger.');
    }

    String pfid = dMig.ProfileId__c;
    Id ProfId = UserInfo.getProfileId();
    //Filtering out Data Migration Profile from executing the following code.
    if (ProfId != pfid) {
        if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
            //Calling Method to Update Regional Funding Record
            ExamResultHelper.UpdateCertResult(Trigger.new);
            ExamResultHelper.UpdateExamType(Trigger.new);
            ExamResultHelper.UpdatePVDates(Trigger.new);

        }
        if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
            //Calling Method to Update Exam Result on Asset
            for (Exam_Results__c e : Trigger.new) {
                if (e.PearsonVUE__c != true) {
                    ExamResultHelper.UpsertExamResultOnAsset(Trigger.new);
                }
            }
        }
        if (Trigger.isAfter && Trigger.isInsert) {
            //Calling Method to make callout to CDD Web Service

            for (Exam_Results__c e : Trigger.new) {
                if (e.PearsonVUE__c == true) {
                    isPearsonVUE = true;
                }
                if (e.Extension__c == true) {
                    type = 'extension';
                } else if (e.Retake__c == true) {
                    type = 'retake';
                } else if (e.Original_EAD__c == true) {
                    type = 'original';
                }
                if (e.Original_EAD__c == true) {
                    contactIds.add(e.Contact__c);
                    eadIds.add(e.Id);

                    exec = true;
                } else if (e.Original_EAD__c == false) {

                    eadIds.add(e.Id);
                }
            }
            if (isPearsonVUE) {
                if (exec == true) {
                    if (!ExamResultHelper.isVUERecursiveCheck) {
                        ExamResultHelper.SendContactInfo(contactIds);
                    }
                    if (!ExamResultHelper.isVUERecursiveEADCheck) {
                        ExamResultHelper.SendEADInfo(eadIds, pv.AddTransaction__c, type);
                    }
                } else {
                    if (!ExamResultHelper.isVUERecursiveEADCheck) {
                        ExamResultHelper.SendEADInfo(eadIds, pv.AddTransaction__c, type);
                    }

                }
            }

        }

        if (Trigger.isAfter && Trigger.isUpdate) {
            for (Exam_Results__c e : Trigger.new) {
                for (Exam_Results__c o : Trigger.old) {
                    if (e.Extension__c == true) {
                        type = 'extension';
                    } else if (e.Retake__c == true) {
                        type = 'retake';
                    }

                    if (e.PearsonVUE__c == true && ((o.Extension__c != e.Extension__c && e.Extension__c == true) || o.eligibilityApptDateFirst__c != e.eligibilityApptDateFirst__c || o.eligibilityApptDateLast__c != e.eligibilityApptDateLast__c || o.examSeriesCode__c != e.examSeriesCode__c)) {
                        extnsnIds.add(e.Id);
                    }


                }
            }

            if (!ExamResultHelper.isVUERecursiveEADCheck) {
                ExamResultHelper.SendEADInfo(extnsnIds, pv.UpdateTransaction__c, type);
            }
        }
    }
}