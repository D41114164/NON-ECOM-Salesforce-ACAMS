/*
* Class Name: BatchWebinarsUpdate - Batch class to update Webinars
* 8/25/2017           mmurphy               Created class.
*/

global class BatchWebinarsUpsert implements
Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful{
    public class customException extends Exception {}
    global List<CalloutUtility.AsyncEnrollmentJSON> webinars = new List<CalloutUtility.AsyncEnrollmentJSON>();
    
    global Database.querylocator start(Database.BatchableContext info){
        webinars = CalloutUtility.GetWebinarEnrollments();
        System.debug('*****BatchWebinarsUpdate.start.webinars: ' + webinars);
        return Database.getQueryLocator([SELECT Id from BeckerLMS_Enrollment__c 
                                         Where Status__c != 'Completed' AND Status__c != 'Cancelled'
                                        Limit 1]);
    }
    
    //global void execute(Database.BatchableContext info, List<BeckerLMS_Enrollment__c> lstwebinars){
    global void execute(Database.BatchableContext info, List<BeckerLMS_Enrollment__c> lstwebinars){
        System.debug('*****BatchWebinarsUpdate.execute.webinars: ' + webinars);
        List<BeckerLMS_Enrollment__c> webinarsToUpsert = new List<BeckerLMS_Enrollment__c>();
        set<BeckerLMS_Enrollment__c> webinarsToUpdate = new set<BeckerLMS_Enrollment__c>();
        Map<String,Id> mapLmsCourseIds = new Map<String,Id>();
        Map<Id, BeckerLMS_Enrollment__c> mapParentLmsEnrollmentsByIds = new Map<Id, BeckerLMS_Enrollment__c>();
        Set<String> lmsCourseIds = new Set<String>();
        Set<Id> parentLmsEnrollmentIds = new Set<Id>();
        
        for (CalloutUtility.AsyncEnrollmentJSON we : webinars){
            if (we != NULL){
                if (String.isNotBlank(we.lmsCourseId))
                    lmsCourseIds.add(we.lmsCourseId);
                if (we.parentLMSEnrollmentId != NULL)
                    parentLmsEnrollmentIds.add(we.parentLMSEnrollmentId);
            }
        }
        mapLmsCourseIds = GetLMSCourseIds(lmsCourseIds);
        mapParentLmsEnrollmentsByIds = GetLMSEnrollments(parentLmsEnrollmentIds);
        System.debug('*****BatchWebinarsUpdate.execute.mapLmsCourseIds: ' + mapLmsCourseIds);
        System.debug('*****BatchWebinarsUpdate.execute.mapParentLmsEnrollmentsByIds: ' + mapParentLmsEnrollmentsByIds);
        
        for(CalloutUtility.AsyncEnrollmentJSON we : webinars){
            BeckerLMS_Enrollment__c lms_enrollment = new BeckerLMS_Enrollment__c();
            
            if (we.lmsEnrollmentId != NULL) lms_enrollment.Id = we.lmsEnrollmentId;
            lms_enrollment.LMS_ID__c = String.valueof(we.id);
            lms_enrollment.Account__c = we.enrollee;
            lms_enrollment.LMS_Course__c = (mapLmsCourseIds.containsKey(we.lmsCourseId) ? mapLmsCourseIds.get(we.lmsCourseId) : NULL);
            lms_enrollment.Purchase_Date__c = we.purchaseDate;
            lms_enrollment.Start_Date__c = we.startDate;
            lms_enrollment.End_Date__c = we.endDate;
            lms_enrollment.Completed_On__c = we.completionDate;
            BeckerLMS_Enrollment__c lms_enrollmentParent = (mapParentLmsEnrollmentsByIds.containsKey(we.parentLMSEnrollmentId) ? mapParentLmsEnrollmentsByIds.get(we.parentLMSEnrollmentId) : NULL);
            if (we.parentLMSEnrollmentId != NULL )
                lms_enrollment.BeckerLMS_Enrollment__c = we.parentLMSEnrollmentId;
            lms_enrollment.Self_enrolled__c = (we.selfEnrolled == NULL ? false : we.selfEnrolled);
            lms_enrollment.GenerateCEU__c = ((we.selfEnrolled == NULL || !we.selfEnrolled || lms_enrollmentParent == NULL) ? false : !lms_enrollmentParent.GenerateCEU__c);
            lms_enrollment.Live_Viewing_Duration__c = we.webinarViewTime;
            lms_enrollment.Recorded_Viewing_Duration__c = we.recordingViewTime;
            lms_enrollment.Status__c = we.status;
            lms_enrollment.Score__c = we.score;
            
            if (String.IsNotBlank(lms_enrollment.Id)) webinarsToUpdate.add(lms_enrollment);
            else webinarsToUpsert.add(lms_enrollment);
        }
        Map<Id, BeckerLMS_Enrollment__c> mapwebinarsToUpdate = new Map<Id, BeckerLMS_Enrollment__c>();
        for(BeckerLMS_Enrollment__c oh : webinarsToUpdate)
        {
            mapwebinarsToUpdate.put(oh.id, oh);
        }
        System.debug('*****BatchWebinarsUpdate.execute.webinarsToUpsert: ' + webinarsToUpsert);
        if (webinarsToUpsert != NULL && webinarsToUpsert.size() > 0){
            Schema.SObjectField f = BeckerLMS_Enrollment__c.Fields.LMS_ID__c;
            Database.UpsertResult [] urList = Database.upsert(webinarsToUpsert, f, false);
            for (Database.UpsertResult ur : urList) {
                if (ur.isSuccess()) {
                    System.debug('*****BatchWebinarsUpdate.execute - Successfully Upsert objects: ' + ur.getId());
                }
                else {
                    for(Database.Error err : ur.getErrors()) {
                        System.debug('*****BatchWebinarsUpdate.execute - The following error has occurred: ' + err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('*****BatchWebinarsUpdate.execute. - SObject fields that affected this error: ' + err.getFields());
                        customException ex = new customException('DML Error: ' + err.getStatusCode() + ': ' + err.getMessage());
                        //Utils.LogException(ex);
                    }
                }
            }
        }
        
        System.debug('*****BatchWebinarsUpdate.execute.webinarsToUpdate: ' + mapwebinarsToUpdate);
        if (mapwebinarsToUpdate != NULL && mapwebinarsToUpdate.size() > 0){
            Database.SaveResult [] urList = Database.update(mapwebinarsToUpdate.values(), false);
            for (Database.SaveResult ur : urList) {
                if (ur.isSuccess()) {
                    System.debug('*****BatchWebinarsUpdate.execute - Successfully Update objects: ' + ur.getId());
                }
                else {
                    for(Database.Error err : ur.getErrors()) {
                        System.debug('*****BatchWebinarsUpdate.execute - The following error has occurred: ' + err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('*****BatchWebinarsUpdate.execute. - SObject fields that affected this error: ' + err.getFields());
                        customException ex = new customException('DML Error: ' + err.getStatusCode() + ': ' + err.getMessage());
                        //Utils.LogException(ex);
                    }
                }
            }
        }
        
    }
    
    global void finish(Database.BatchableContext info){}
    
    private static Map<String,Id> GetLMSCourseIds(Set<String> lmsCourseIds){
        Map<String,Id> result = new Map<String,Id>();
        for (LMSCourse__c c : [SELECT Id, LMSID__c  FROM LMSCourse__c WHERE LMSID__c IN:lmsCourseIds]){
            result.put(c.LMSID__c, c.Id);
        }
        return result;
    }
    
    private static Map<Id, BeckerLMS_Enrollment__c> GetLMSEnrollments(Set<Id> lmsEnrollmentIds){
        Map<Id, BeckerLMS_Enrollment__c> result = new Map<Id, BeckerLMS_Enrollment__c>();
        for (BeckerLMS_Enrollment__c e : [SELECT Id, End_Date__c, Status__c, Score__c, GenerateCEU__c FROM BeckerLMS_Enrollment__c WHERE Id IN:lmsEnrollmentIds]){
            result.put(e.Id, e);
        }
        return result;
    }
}