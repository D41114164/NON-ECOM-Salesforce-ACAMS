trigger ACAMSExamResultTrigger on Exam_Results__c (before insert, after insert, before update, after update) {
    (new ACAMSExamResultTriggerHandler()).run();
}