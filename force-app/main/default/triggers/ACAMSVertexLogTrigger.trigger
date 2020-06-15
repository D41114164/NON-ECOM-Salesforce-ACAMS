trigger ACAMSVertexLogTrigger on Vertex__VertexLog__c (after insert) {
    (new ACAMSVertexLogTriggerHandler()).run();
}