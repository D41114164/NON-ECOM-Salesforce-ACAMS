public with sharing class ACAMSCaseTriggerHandler extends CCAviTriggerHandler {

    private List<Case> newList;
    private List<Case> oldList;
    private Map<Id, Case> newMap;
    private Map<Id, Case> oldMap;

    public ACAMSCaseTriggerHandler() {
        super();
        this.newList = (List<Case>) Trigger.new;
        this.oldList = (List<Case>) Trigger.old;
        this.newMap = (Map<Id, Case>) Trigger.newMap;
        this.oldMap = (Map<Id, Case>) Trigger.oldMap;
    }

    public override void beforeInsert() {
        Boolean result = this.fetchprofileid();
        this.setRegionFieldByCountry(this.newList);
        if (result) {
            // this.CaseLookupContact(this.newList);
            this.caseAssignmentQueues(this.newList);
            //  this.WebcaseCountryMapping(this.newList); commented as per business requirement
            this.CaseAssignmentInsert(this.newList);
        }
    }

    public override void beforeUpdate() {

        this.setRegionFieldByCountry(
                this.getCaseWithCountriesChanged(this.newList, this.oldMap)
        );
        this.getCaseWithBusinessHours(this.newList, this.oldMap);
        Boolean result = this.fetchprofileid();
        if (result) {
            this.CaseTriggeremails(this.newList, this.oldMap);
            //  this.CaseLookupContact(this.newList);
            this.caseAssignmentQueues(this.newList);
            //   this.WebcaseCountryMapping(this.newList); commented as per business requirement
            this.CaseAssignmentUpdate(this.newList, this.oldMap);
        }
    }

    private List<Case> getCaseWithCountriesChanged(List<Case> currentCases, Map<Id, Case> oldCases) {
        List<Case> casesWithCountriesChanged = new List<Case>();
        for (Case currentCase : currentCases) {
            Case oldCase = oldCases.get(currentCase.Id);
            if (oldCase.AddressCountry__c != currentCase.AddressCountry__c) {
                casesWithCountriesChanged.add(currentCase);
            }
        }
        return casesWithCountriesChanged;
    }

    private void setRegionFieldByCountry(List<Case> cases) {
        Set<String> countryCodes = new Set<String>();
        Map<String, String> regionByCountryCode = new Map<String, String>();
        for (Case caseToUpdate : cases) {
            if (!String.isBlank(caseToUpdate.AddressCountry__c)) {
                countryCodes.add(caseToUpdate.AddressCountry__c);
            }
        }
        for (CountrySettings__mdt countrySetting : [
                SELECT DeveloperName, Region__c
                FROM CountrySettings__mdt
                WHERE DeveloperName IN :countryCodes
        ]) {
            regionByCountryCode.put(countrySetting.DeveloperName, countrySetting.Region__c);
        }
        for (Case caseToUpdate : cases) {
            if (regionByCountryCode.containsKey(caseToUpdate.AddressCountry__c)) {
                caseToUpdate.AddressRegion__c = regionByCountryCode.get(caseToUpdate.AddressCountry__c);
            } else if (String.isBlank(caseToUpdate.AddressCountry__c)) {
                caseToUpdate.AddressRegion__c = '';
            }
        }
    }

    //Business Hours - Closedate
    @TestVisible
    private void getCaseWithBusinessHours(List<Case> currentCases, Map<Id, Case> oldCases) {
        Data_Migration_User__mdt dMig = new Data_Migration_User__mdt();
        dMig = [SELECT MasterLabel, ProfileId__c FROM Data_Migration_User__mdt WHERE MasterLabel = :'ProfileId' LIMIT 1];
        String pfid = dMig.ProfileId__c;
        Id ProfId = UserInfo.getProfileId();
        System.debug(ProfId);
        System.debug(pfid);
        System.debug(ProfId != pfid);
        if (ProfId != pfid) {
            BusinessHours stdBusinessHours = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];

            BusinessHours EurBusinessHours = [SELECT Id FROM BusinessHours WHERE Name = 'Europe Hours' LIMIT 1];
            String Eurd = String.valueOf(EurBusinessHours);

            BusinessHours AsiBusinessHours = [SELECT Id FROM BusinessHours WHERE Name = 'Asia Hours' LIMIT 1];
            String Asia = String.valueOf(AsiBusinessHours);


            for (Case c : currentCases) {
                Boolean AssignedToEuropeSupport = false;
                Boolean AssignedToAsiaSupport = false;

                if (c.Origin <> 'Phone' && c.Origin <> 'Chat' && c.Origin <> 'Email - Certification' && c.Origin <> 'Email - Enterprise' && c.Origin <> 'Email - Group Exams') {

                    if (c.Origin == 'Email - Europe' || c.Region__c == 'Europe') {
                        AssignedToEuropeSupport = true;
                    } else {
                        if (c.Origin == 'Email - Asia' || c.Region__c == 'Asia/Pacific') {
                            AssignedToAsiaSupport = true;
                        } else {
                        }
                    }

                    if (c.Target_Close_Date__c == null) {
                        if (AssignedToEuropeSupport) {

                            if (c.Type == 'Data entry updates' || c.Type == 'Other' || c.Type == 'Technical Support' || c.Type == 'Sales inquiry' || c.Type == 'General inquiry' || c.Type == 'Pending Categorization') {
                                c.Target_Close_Date__c = BusinessHours.addGmt (EurBusinessHours.Id, c.CreatedDate, 9 * 60 * 60 * 1000L);
                            } else {
                                if (c.Type == 'Revenue Impacting' || c.Type == 'Urgent') {
                                    c.Target_Close_Date__c = BusinessHours.addGmt (EurBusinessHours.Id, c.CreatedDate, 5 * 60 * 60 * 1000L);
                                } else {
                                }
                            }
                        } else {


                            if (AssignedToAsiaSupport) {

                                if (c.Type == 'Data entry updates' || c.Type == 'Other' || c.Type == 'Technical Support' || c.Type == 'Sales inquiry' || c.Type == 'General inquiry' || c.Type == 'Pending Categorization') {
                                    c.Target_Close_Date__c = BusinessHours.addGmt (AsiBusinessHours.Id, c.CreatedDate, 9 * 60 * 60 * 1000L);
                                } else {
                                    if (c.Type == 'Revenue Impacting' || c.Type == 'Urgent') {
                                        c.Target_Close_Date__c = BusinessHours.addGmt (AsiBusinessHours.Id, c.CreatedDate, 5 * 60 * 60 * 1000L);
                                    } else {
                                    }
                                }
                            } else {

                                if (c.Type == 'Data entry updates' || c.Type == 'Other' || c.Type == 'Technical Support' || c.Type == 'Sales inquiry' || c.Type == 'General inquiry' || c.Type == 'Pending Categorization') {
                                    c.Target_Close_Date__c = BusinessHours.addGmt (stdBusinessHours.Id, c.CreatedDate, 9 * 60 * 60 * 1000L);
                                } else {
                                    if (c.Type == 'Revenue Impacting' || c.Type == 'Urgent') {
                                        c.Target_Close_Date__c = BusinessHours.addGmt (stdBusinessHours.Id, c.CreatedDate, 5 * 60 * 60 * 1000L);
                                    } else {
                                    }
                                }
                            }
                        }
                    }


                } else {
                }
            }
        }
    }
    //casetype trigger for Emails
    private void CaseTriggeremails(List<Case> currentCases, Map<Id, Case> oldCases) {
        for (Case cse : currentCases) {

            Boolean FromInternal = false;
            if (!String.isBlank(cse.SuppliedEmail)) {
                if (cse.SuppliedEmail.contains('acams') || cse.SuppliedEmail.contains('alertglobal')) {
                    FromInternal = true;
                }
            }

            if (cse.Type <> 'Pending Categorization') {
                {
                }

            } else {
                if (cse.Subject.contains('Technical_Support_Access_Issue_') && (FromInternal == true)) {
                    cse.Type = 'Technical Support';
                    cse.Secondary_Case_Type__c = 'Access Issue';
                } else {
                    if (cse.Subject.contains('Technical_Support_Resend_') && (FromInternal == true)) {
                        cse.Type = 'Technical Support';
                        cse.Secondary_Case_Type__c = 'Resend Communication';
                    } else {
                        if (cse.Subject.contains('Technical_Support_Other_') && (FromInternal == true)) {
                            cse.Type = 'Technical Support';
                            cse.Secondary_Case_Type__c = 'Other';
                        } else {
                            if (cse.Subject.contains('Technical_Support_') && (FromInternal == true)) {
                                cse.Type = 'Technical Support';

                            } else {
                                if (cse.Subject.contains('General_inquiry_Memberships_') && (FromInternal == true)) {
                                    cse.Type = 'General Inquiry';
                                    cse.Secondary_Case_Type__c = 'Memberships';
                                } else {
                                    if (cse.Subject.contains('General_inquiry_Chapters_') && (FromInternal == true)) {
                                        cse.Type = 'General Inquiry';
                                        cse.Secondary_Case_Type__c = 'Chapter';
                                    } else {
                                        if (cse.Subject.contains('General_inquiry_Certifications_') && (FromInternal == true)) {
                                            cse.Type = 'General Inquiry';
                                            cse.Secondary_Case_Type__c = 'Certifications';
                                        } else {
                                            if (cse.Subject.contains('General_inquiry_Training_') && (FromInternal == true)) {
                                                cse.Type = 'General Inquiry';
                                                cse.Secondary_Case_Type__c = 'Training';
                                            } else {
                                                if (cse.Subject.contains('General_inquiry_RA_') && (FromInternal == true)) {
                                                    cse.Type = 'General Inquiry';
                                                    cse.Secondary_Case_Type__c = 'RA';
                                                } else {
                                                    if (cse.Subject.contains('General_inquiry_Other_') && (FromInternal == true)) {
                                                        cse.Type = 'General Inquiry';
                                                        cse.Secondary_Case_Type__c = 'Other';
                                                    } else {
                                                        if (cse.Subject.contains('General_inquiry_Other_') && (FromInternal == true)) {
                                                            cse.Type = 'General Inquiry';

                                                        } else {
                                                            if (cse.Subject.contains('Enterprise_Onboarding_') && (FromInternal == true)) {
                                                                cse.Type = 'Enterprise';
                                                                cse.Secondary_Case_Type__c = 'Onboarding';
                                                            } else {
                                                                if (cse.Subject.contains('Enterprise_Change_') && (FromInternal == true)) {
                                                                    cse.Type = 'Enterprise';
                                                                    cse.Secondary_Case_Type__c = 'Change request';
                                                                } else {
                                                                    if (cse.Subject.contains('Enterprise_Other_') && (FromInternal == true)) {
                                                                        cse.Type = 'Enterprise';
                                                                        cse.Secondary_Case_Type__c = 'Other';
                                                                    } else {
                                                                        if (cse.Subject.contains('Enterprise_') && (FromInternal == true)) {
                                                                            cse.Type = 'Enterprise';

                                                                        } else {
                                                                            if (cse.Subject.contains('Certifications_Cert_App_') && (FromInternal == true)) {
                                                                                cse.Type = 'Certifications';
                                                                                cse.Secondary_Case_Type__c = 'Certification Application';
                                                                            } else {
                                                                                if (cse.Subject.contains('Certifications_Recert_App_') && (FromInternal == true)) {
                                                                                    cse.Type = 'Certifications';
                                                                                    cse.Secondary_Case_Type__c = 'Recertification Application';
                                                                                } else {
                                                                                    if (cse.Subject.contains('Certifications_Retake_') && (FromInternal == true)) {
                                                                                        cse.Type = 'Certifications';
                                                                                        cse.Secondary_Case_Type__c = 'Retake Exam';
                                                                                    } else {
                                                                                        if (cse.Subject.contains('Certifications_Extension_') && (FromInternal == true)) {
                                                                                            cse.Type = 'Certifications';
                                                                                            cse.Secondary_Case_Type__c = 'Extension';
                                                                                        } else {
                                                                                            if (cse.Subject.contains('Certifications_Reissue_VC_') && (FromInternal == true)) {
                                                                                                cse.Type = 'Certifications';
                                                                                                cse.Secondary_Case_Type__c = 'Reissue Voucher Code';
                                                                                            } else {
                                                                                                if (cse.Subject.contains('Certifications_Group_Exam_') && (FromInternal == true)) {
                                                                                                    cse.Type = 'Certifications';
                                                                                                    cse.Secondary_Case_Type__c = 'Group Exam';
                                                                                                } else {
                                                                                                    if (cse.Subject.contains('Certifications_Resend_Cert_') && (FromInternal == true)) {
                                                                                                        cse.Type = 'Certifications';
                                                                                                        cse.Secondary_Case_Type__c = 'Resend certificate';
                                                                                                    } else {
                                                                                                        if (cse.Subject.contains('Certifications_Reschedule_') && (FromInternal == true)) {
                                                                                                            cse.Type = 'Certifications';
                                                                                                            cse.Secondary_Case_Type__c = 'Reschedule';
                                                                                                        } else {
                                                                                                            if (cse.Subject.contains('Certifications_Other_') && (FromInternal == true)) {
                                                                                                                cse.Type = 'Certifications';
                                                                                                                cse.Secondary_Case_Type__c = 'Other';
                                                                                                            } else {
                                                                                                                if (cse.Subject.contains('Certifications_') && (FromInternal == true)) {
                                                                                                                    cse.Type = 'Certifications';

                                                                                                                } else {
                                                                                                                    if (cse.Subject.contains('Revenue_Impacting_Invoice_') && (FromInternal == true)) {
                                                                                                                        cse.Type = 'Revenue Impacting';
                                                                                                                        cse.Secondary_Case_Type__c = 'Invoice';
                                                                                                                    } else {
                                                                                                                        if (cse.Subject.contains('Revenue_Impacting_Payment_') && (FromInternal == true)) {
                                                                                                                            cse.Type = 'Revenue Impacting';
                                                                                                                            cse.Secondary_Case_Type__c = 'Payment';
                                                                                                                        } else {
                                                                                                                            if (cse.Subject.contains('Revenue_Impacting_Group_Order_') && (FromInternal == true)) {
                                                                                                                                cse.Type = 'Revenue Impacting';
                                                                                                                                cse.Secondary_Case_Type__c = 'Group Orders';
                                                                                                                            } else {
                                                                                                                                if (cse.Subject.contains('Revenue_Impacting_Refund_') && (FromInternal == true)) {
                                                                                                                                    cse.Type = 'Revenue Impacting';
                                                                                                                                    cse.Secondary_Case_Type__c = 'Refund';
                                                                                                                                } else {
                                                                                                                                    if (cse.Subject.contains('Revenue_Impacting_Credit_') && (FromInternal == true)) {
                                                                                                                                        cse.Type = 'Revenue Impacting';
                                                                                                                                        cse.Secondary_Case_Type__c = 'Credit';
                                                                                                                                    } else {
                                                                                                                                        if (cse.Subject.contains('Revenue_Impacting_Transfer_') && (FromInternal == true)) {
                                                                                                                                            cse.Type = 'Revenue Impacting';
                                                                                                                                            cse.Secondary_Case_Type__c = 'Transfer';
                                                                                                                                        } else {
                                                                                                                                            if (cse.Subject.contains('Revenue_Wire_') && (FromInternal == true)) {
                                                                                                                                                cse.Type = 'Revenue Impacting';
                                                                                                                                                cse.Secondary_Case_Type__c = 'Wire';
                                                                                                                                            } else {
                                                                                                                                                if (cse.Subject.contains('Revenue_Impacting_RegOnline_') && (FromInternal == true)) {
                                                                                                                                                    cse.Type = 'Revenue Impacting';
                                                                                                                                                    cse.Secondary_Case_Type__c = 'RegOnline';
                                                                                                                                                } else {
                                                                                                                                                    if (cse.Subject.contains('Revenue_Comp_') && (FromInternal == true)) {
                                                                                                                                                        cse.Type = 'Revenue Impacting';
                                                                                                                                                        cse.Secondary_Case_Type__c = 'Complimentary Order';
                                                                                                                                                    } else {
                                                                                                                                                        if (cse.Subject.contains('Revenue_Impacting_Other_') && (FromInternal == true)) {
                                                                                                                                                            cse.Type = 'Revenue Impacting';
                                                                                                                                                            cse.Secondary_Case_Type__c = 'Other';
                                                                                                                                                        } else {
                                                                                                                                                            if (cse.Subject.contains('Revenue_Impacting_') && (FromInternal == true)) {
                                                                                                                                                                cse.Type = 'Revenue Impacting';

                                                                                                                                                            } else {
                                                                                                                                                                if (cse.Subject.contains('Data_entry_updates_Contact_Info_') && (FromInternal == true)) {
                                                                                                                                                                    cse.Type = 'Data Entry Updates';
                                                                                                                                                                    cse.Secondary_Case_Type__c = 'Contact information';
                                                                                                                                                                } else {
                                                                                                                                                                    if (cse.Subject.contains('Data_entry_updates_Merge_Dups_') && (FromInternal == true)) {
                                                                                                                                                                        cse.Type = 'Data Entry Updates';
                                                                                                                                                                        cse.Secondary_Case_Type__c = 'Merge Duplicates';
                                                                                                                                                                    } else {
                                                                                                                                                                        if (cse.Subject.contains('Data_entry_updates_Missing_ECU_') && (FromInternal == true)) {
                                                                                                                                                                            cse.Type = 'Data Entry Updates';
                                                                                                                                                                            cse.Secondary_Case_Type__c = 'Missing ECU';
                                                                                                                                                                        } else {
                                                                                                                                                                            if (cse.Subject.contains('Data_entry_updates_Other_') && (FromInternal == true)) {
                                                                                                                                                                                cse.Type = 'Data Entry Updates';
                                                                                                                                                                                cse.Secondary_Case_Type__c = 'Other';
                                                                                                                                                                            } else {
                                                                                                                                                                                if (cse.Subject.contains('Data_entry_updates_') && (FromInternal == true)) {
                                                                                                                                                                                    cse.Type = 'Data Entry Updates';

                                                                                                                                                                                    //      }  else {  if(cse.Subject.contains('Urgent_Case_') && (FromInternal == true)){
                                                                                                                                                                                    //                 cse.Type = 'Urgent';

                                                                                                                                                                                } else {
                                                                                                                                                                                    if (cse.Subject.contains('Report_Issue_Case_') && (FromInternal == true)) {
                                                                                                                                                                                        cse.Type = 'Report Issue';

                                                                                                                                                                                    } else {
                                                                                                                                                                                        if (cse.Subject.contains('Other_Case_') && (FromInternal == true)) {
                                                                                                                                                                                            cse.Type = 'Other';


                                                                                                                                                                                        } else {
                                                                                                                                                                                            if (!String.isBlank(cse.SuppliedEmail)) {
                                                                                                                                                                                                if (cse.SuppliedEmail.contains('achalerts_mail@comerica.com')) {
                                                                                                                                                                                                    cse.Type = 'Revenue Impacting';
                                                                                                                                                                                                    cse.Secondary_Case_Type__c = 'Wire';
                                                                                                                                                                                                } else {
                                                                                                                                                                                                    if (cse.SuppliedEmail.contains('notification@securemail.comerica.com')) {
                                                                                                                                                                                                        cse.Type = 'Revenue Impacting';
                                                                                                                                                                                                        cse.Secondary_Case_Type__c = 'Wire';
                                                                                                                                                                                                    } else {
                                                                                                                                                                                                        if (cse.SuppliedEmail.contains('events@regonline.com')) {
                                                                                                                                                                                                            cse.Type = 'Revenue Impacting';
                                                                                                                                                                                                            cse.Secondary_Case_Type__c = 'RegOnline';
                                                                                                                                                                                                        }
                                                                                                                                                                                                    }
                                                                                                                                                                                                }
                                                                                                                                                                                            }
                                                                                                                                                                                        }


                                                                                                                                                                                    }
                                                                                                                                                                                }
                                                                                                                                                                            }
                                                                                                                                                                        }
                                                                                                                                                                    }
                                                                                                                                                                }
                                                                                                                                                            }
                                                                                                                                                        }
                                                                                                                                                    }
                                                                                                                                                }
                                                                                                                                            }
                                                                                                                                        }
                                                                                                                                    }
                                                                                                                                }
                                                                                                                            }
                                                                                                                        }
                                                                                                                    }
                                                                                                                }
                                                                                                            }
                                                                                                        }
                                                                                                    }
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        // End Case Type Trigger for Emails

    }
    /*
     private void CaseLookupContact(List<Case> currentCases){
        // Contact Form Case Lookup Contact


        List<String> CustomerEmail = new List<String>();

         for (Case c:currentCases){
         CustomerEmail.add(c.SuppliedEmail);
             }

     List <Contact> ContactList = [Select ID, Email, Work_Email__c, Home_E_Mail_Address__c, Other_Email__c, Secondary_Email__c from contact where Email in :CustomerEmail OR Work_Email__c in :CustomerEmail OR Home_E_Mail_Address__c in :CustomerEmail OR Other_Email__c in :CustomerEmail OR Secondary_Email__c in :CustomerEmail Limit 1];

     for (Integer i = 0; i <currentCases.size(); i++){
         if (ContactList.size() > 0 && currentCases[i].SuppliedEmail !=null && currentCases[i].Contactid ==null){
                         for (Contact z:ContactList){
                 if (currentCases[i].SuppliedEmail == z.Email || currentCases[i].SuppliedEmail == z.Work_Email__c || currentCases[i].SuppliedEmail == z.Home_E_Mail_Address__c || currentCases[i].SuppliedEmail == z.Other_Email__c || currentCases[i].SuppliedEmail == z.Secondary_Email__c){
                         currentCases[i].Contactid = z.ID;
                                 }
                         }
         }
         else{
  //JG082317       Trigger.new[i].Contactid = null;
         }

     }

     // End Contact Form Case Lookup Contact
     } */

    private void caseAssignmentQueues(List<Case> currentCases) {

        // Case assignment to queues

        //Removed this section - Jairo Gomez - 07122017

        for (Case c : currentCases) {

            //only run trigger when my business condiions are met and not invoked by an @future method to avoid infinite recursion
            if (!String.valueOf(c.OwnerId).startsWith('00G') && c.Assigned_to_Service_Cloud_Agent__c == false && !System.isFuture()) {

                MyCaseReassignmentClass.reassignCaseWithActiveRule(c.Id);

            }

        }


        // End of Case assignment to queues
    }

    /*  // Web to case country mapping
      private void WebcaseCountryMapping(List<case> currentCases){


     Map<string,Country_Names__c> countries = Country_Names__c.getAll();//get all the countries

      for(Case cs:currentCases)
      { if(cs.Web_Country__c == NULL){ } else {
          for(String s : countries.keySet())
          {
              if(s.containsIgnoreCase(cs.Web_Country__c))
              {
                  cs.Region__c=countries.get(s).Country_Region__c;
              }
          }}
      }

      // End of Web to Case Country Mapping


      } */
    private Boolean fetchprofileid() {
        Data_Migration_User__mdt dMig = new Data_Migration_User__mdt();
        dMig = [SELECT MasterLabel, ProfileId__c FROM Data_Migration_User__mdt WHERE MasterLabel = :'ProfileId' LIMIT 1];
        String pfid = dMig.ProfileId__c;
        Id ProfId = UserInfo.getProfileId();
        System.debug(ProfId);
        System.debug(pfid);
        System.debug(ProfId != pfid);
        if (ProfId != pfid) {
            return true;
        } else {
            return false;
        }
    }

    private void CaseAssignmentInsert(List<Case> currentCases) {

        Map<Integer, Id> queueIds = new Map<Integer, Id>();
        Integer idx = 0;
        for (Case cs : currentCases) {

            queueIds.put(idx, cs.OwnerId);

            idx++;
        }
        System.debug('>>>>>queueIds: ' + queueIds);
        CaseAssignment(queueIds, currentCases);

    }

    private void CaseAssignmentUpdate(List<Case> currentCases, Map<Id, Case> oldCases) {

        Map<Integer, Id> queueIds = new Map<Integer, Id>();
        Integer idx = 0;
        for (Case cs : currentCases) {
            if (cs.OwnerId <> oldCases.get(cs.Id).OwnerId) {
                if (cs.TempOwnerId__c == 'SKIP') {
                    currentCases[idx].TempOwnerId__c = '';
                } else {
                    queueIds.put(idx, cs.OwnerId);
                }
            }
            idx++;
        }
        CaseAssignment(queueIds, currentCases);
    }


    private void CaseAssignment(Map<Integer, Id> queueIds, List<Case> currentCases) {

        if (queueIds.isEmpty()) return;

        //
        //Find active Assignment Group for Queue
        //
        Map<Integer, Id> asgnGroupNameIds = new Map<Integer, Id>();   //Trigger index --> Assignment_Group_Name ID
        Map<Id, Assignment_Group_Queues__c> asgnGroupQueues = new Map<Id, Assignment_Group_Queues__c>(); //Queue ID --> Assignment Group Queues

        for (Assignment_Group_Queues__c[] agq : [
                SELECT Assignment_Group_Name__c, QueueId__c
                FROM Assignment_Group_Queues__c
                WHERE QueueId__c IN :queueIds.values()
                AND Active__c = 'True'
        ]) {
            for (Integer i = 0; i < agq.size(); i++) {
                asgnGroupQueues.put(agq[i].QueueId__c, agq[i]);
            }
        }
        System.debug('>>>>>asgnGroupQueues: ' + asgnGroupQueues);
        if (asgnGroupQueues.isEmpty()) return;

        for (Integer i : queueIds.keySet()) {
            Assignment_Group_Queues__c agq = asgnGroupQueues.get(queueIds.get(i));

            if (agq <> null) {
                asgnGroupNameIds.put(i, agq.Assignment_Group_Name__c);
            }
            //else no active assignment group queue error
        }
        System.debug('>>>>>asgnGroupNameIds: ' + asgnGroupNameIds);
        if (asgnGroupNameIds.isEmpty()) return;

        //
        //Determine next valid user in Queue/Assignment Group for round robin
        //User with earliest last assignment date wins.
        //
        Map<Id, Assignment_Groups__c[]> asgnGroups = new Map<Id, Assignment_Groups__c[]>(); // Assignment Group Name ID --> User ID
        for (Assignment_Groups__c[] ags : [
                SELECT Group_Name__c, User__c, Last_Assignment__c, Millisecond__c, User__r.IsActive
                FROM Assignment_Groups__c
                WHERE Group_Name__c IN :asgnGroupNameIds.values()
                AND Active__c = 'True'
                AND User__r.IsActive = TRUE
                ORDER BY Last_Assignment__c, Millisecond__c
        ]) {
            if (ags.size() > 0) {
                asgnGroups.put(ags[0].Group_Name__c, ags);
            }
        }
        System.debug('>>>>>asgnGroups: ' + asgnGroups);
        if (asgnGroups.isEmpty()) return;

        Map<Id, Assignment_Groups__c> updateAssignmentGroups = new Map<Id, Assignment_Groups__c>();
        Map<Id, Datetime> latestAGDateTime = new Map<Id, Datetime>();
        Integer idx = 0;
        for (Integer i : queueIds.keySet()) {
            Assignment_Groups__c[] ags = asgnGroups.get(asgnGroupNameIds.get(i));
            if (ags.size() > 0) {
                //Choose next user in line if user ID has already been used but not committed in this trigger batch
                Assignment_Groups__c ag = ags[Math.mod(idx, ags.size())];

                //Assign User to Case as the new owner
                // System.debug('>>>>>Owner changed for Case ' + Trigger.new[i].Id + ' from '+Trigger.new[i].OwnerId+' to '+ ag.User__c);
                currentCases[i].OwnerId = ag.User__c;
                currentCases[i].TempOwnerId__c = ag.User__c;

                //Set last assignment datetime
                Datetime now = Datetime.now();
                ag.Last_Assignment__c = now;
                ag.Millisecond__c = now.millisecondGmt();

                //update only latest Assignment Groups per ID
                if (latestAGDateTime.containsKey(ag.Id)) {
                    if (latestAGDateTime.get(ag.Id) < now) {
                        updateAssignmentGroups.put(ag.Id, ag);
                        latestAGDateTime.put(ag.Id, now);
                    }
                } else {
                    updateAssignmentGroups.put(ag.Id, ag);
                    latestAGDateTime.put(ag.Id, now);
                }

                idx++;
            }
        }
        //Map --> List/Array for DML update
        List<Assignment_Groups__c> updateAG = new List<Assignment_Groups__c>();
        for (Id agId : updateAssignmentGroups.keySet()) {
            updateAG.add(updateAssignmentGroups.get(agId));
        }

        System.debug('>>>>>Update Assignment Groups: ' + updateAG);

        //
        //Update last assignment for Assignment Group in batch
        //
        if (updateAG.size() > 0) {
            try {
                update updateAG;
            } catch (Exception e) {
                for (Integer i : queueIds.keySet()) {
                    Trigger.new[i].addError('ERROR: Could not update Assignment Group records ' + ' DETAIL: ' + e.getMessage());
                }
            }

        }
    }

}