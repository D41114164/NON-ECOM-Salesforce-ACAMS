/***
 * @Description, handler business logic for Lead Trigger
 * @Date, May 6,2020
 * @Ray
 */
public class ACAMSLeadTriggerHandler extends CCAviTriggerHandler{
    private List<Lead> newList = (List<Lead>) Trigger.new;
    private Map<Id, Lead> oldMap = (Map<Id, Lead>) Trigger.oldMap;

    /***
     * constructor
     * **/
    public ACAMSLeadTriggerHandler() {

    }

    
    /***
     *  method execute after update
     */
    protected override void afterUpdate() {
        reassignLeadAfterUpdate();
    }

    /***
     * @Description: invoke reassignLeads method, execute this method after trigger udpate.
     */
    private void reassignLeadAfterUpdate(){
        Set<Id> leadSetIdsToReassign = new Set<Id>();
        for (Lead l : newList) {
            if (oldMap.get(l.Id).Reassign__c != l.Reassign__c && l.Reassign__c) {
                leadSetIdsToReassign.add(l.Id);
            }
        }

        if (leadSetIdsToReassign != null && leadSetIdsToReassign.size() > 0) {
            reassignLeads(leadSetIdsToReassign);
        }
    }

    /**
     *  @Description: ReassignLeads,assign owner to legacy leads records. 
     */
    private void reassignLeads(Set<Id> leadsToReassignSetIds) {
        Map<Id, lead> leadsToUpdateMap = new Map<Id, lead>();
        Map<Id, Lead> leadsToProcessMap = new Map<Id, Lead>();

        if (leadsToReassignSetIds != null && leadsToReassignSetIds.size() > 0) {
            for (Lead lead : [SELECT Id,Reassign__c FROM Lead WHERE Id IN:leadsToReassignSetIds]) {
                leadsToProcessMap.put(lead.Id, lead);
            }
        }

        List<AssignmentRule> arList = [select id from AssignmentRule where SobjectType = 'Lead' and Active = true limit 1];
        if(arList != null && arList.size() > 0){
            for (Lead lead : leadsToProcessMap.values()) {
                Database.DMLOptions dmo = new Database.DMLOptions();
                dmo.assignmentRuleHeader.assignmentRuleId = arList[0].id;
                if (lead.Reassign__c = true) {
                    Lead newLead = new Lead(Id = lead.Id);
                    newLead.setOptions(dmo);
                    newLead.Reassign__c = false;
                    leadsToUpdateMap.put(newLead.Id, newLead);
                }
            }

            try {
                if (leadsToUpdateMap.values().size() > 0) {
                    Database.SaveResult [] srList = Database.update(leadsToUpdateMap.values(), false);
                    for (Database.SaveResult sr : srList) {
                        if (sr.isSuccess()) {
                            System.debug(sr.getId() + ' IS THE VALUE OF sr.getId()  ');
                        } else {
                            for (Database.Error err : sr.getErrors()) {
                                    System.debug('The following error has occurred.');
                                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                    System.debug('Fields that affected this error: ' + err.getFields());
                            }
                        }
                    }
                }
            } catch (exception e) {
                System.debug(e.getMessage() + 'e.getMessage()');
                throw e;
            }
        }

    }

}