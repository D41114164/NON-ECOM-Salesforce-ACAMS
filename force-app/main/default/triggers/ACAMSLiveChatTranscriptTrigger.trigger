trigger ACAMSLiveChatTranscriptTrigger on LiveChatTranscript (After insert) {
    (new ACAMSLiveChatTranscriptTriggerHandler()).run();
}