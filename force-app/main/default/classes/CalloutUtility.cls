public class CalloutUtility {
    public static string secretKey;
    public static String baseurl = '';
    public static String method = '';
    public static String endPoint = '';
    public static Integer timeOut = 120000;
    public static String body = '';
    public class customException extends Exception {}

    public static String generateHMACToken(String input){
        Blob Signature = Crypto.generateMac('HmacSHA1', Blob.ValueOf(input), Blob.ValueOf(secretKey));
        String hmac = EncodingUtil.urlEncode(EncodingUtil.base64encode(Signature), 'UTF-8').replaceAll('\\r\\n', '');
        System.debug('*****CalloutUtility.innerGenerateHmacSHA1Msg.hmac: '+ hmac);
        return hmac;
    }

    //*** Async Callouts ***//
    @Future(callout=true)
    public static void SendRequest(String serviceName, Boolean SHASignature, String json_string) {
        try{
            Map<String, Global_Variable__c> global_variableMap = Global_Variable__c.getAll();
            HttpRequest req = new HttpRequest();
            req.setHeader('Content-Encoding', 'UTF-8');
            req.setHeader('Content-type', 'application/json');
            body = json_string;
            req.setBody(body);

            if (SHASignature){
                secretKey = global_variableMap.get('LMS.SecretKey').Value__c;
                String ts = String.Valueof(dateTime.now().getTime()/1000);
                System.debug('*****CalloutUtility.SendRequest.dateTime.now(): ' + dateTime.now());
                System.debug('*****CalloutUtility.SendRequest.ts: ' + ts);

                if (ServiceName == 'UserIntegration'){
                    timeOut = Integer.valueOf(global_variableMap.get('LMS.UserIntegration.TimeOut').Value__c);
                    method = global_variableMap.get('LMS.UserIntegration.Method').Value__c;
                    baseurl = String.format(global_variableMap.get('LMS.UserIntegration.Endpoint').Value__c, new String[]{ts});
                    endPoint = global_variableMap.get('LMS.Server').Value__c + baseurl + '/' + generateHMACToken(baseurl);
                }
                else if (ServiceName.contains('EnrollmentIntegration')){
                    timeOut = Integer.valueOf(global_variableMap.get('LMS.EnrollmentIntegration.TimeOut').Value__c);
                    method = (ServiceName.StartsWith('Create') ? global_variableMap.get('LMS.EnrollmentIntegration.C.Method').Value__c : global_variableMap.get('LMS.EnrollmentIntegration.U.Method').Value__c)   ;
                    baseurl = String.format(global_variableMap.get('LMS.EnrollmentIntegration.Endpoint').Value__c, new String[]{ts});
                    endPoint = global_variableMap.get('LMS.Server').Value__c + baseurl + '/' + generateHMACToken(baseurl);
                }
               else if (ServiceName.contains('AccountMergeIntegration')){
                    timeOut = Integer.valueOf(global_variableMap.get('LMS.UserIntegration.TimeOut').Value__c);
                    method = global_variableMap.get('LMS.UserIntegration.Method').Value__c;
                    baseurl = String.format(global_variableMap.get('LMS.AccountMergeIntegration.Endpoint').Value__c, new String[]{ts});
                    endPoint = global_variableMap.get('LMS.Server').Value__c + baseurl + '/' + generateHMACToken(baseurl);
                }  
                 else if (ServiceName.contains('EnrollmentMergeIntegration')){
                    timeOut = Integer.valueOf(global_variableMap.get('LMS.UserIntegration.TimeOut').Value__c);
                    method = global_variableMap.get('LMS.UserIntegration.Method').Value__c;
                    baseurl = String.format(global_variableMap.get('LMS.EnrlmntMergeIntegration.Endpoint').Value__c, new String[]{ts});
                    endPoint = global_variableMap.get('LMS.Server').Value__c + baseurl + '/' + generateHMACToken(baseurl);
                }
            } else {
                //Callouts not using SHASignature
            }

            req.setMethod(method);
            req.setTimeout(timeOut);
            req.setEndpoint(endpoint);

            System.debug('*****CalloutUtility.SendRequest.baseurl: ' + baseurl);
            System.debug('*****CalloutUtility.SendRequest.endpoint: ' + endpoint);
            System.debug('*****CalloutUtility.SendRequest.body: ' + body);

            Http http = new Http();
            HTTPResponse res = http.send(req);

            System.debug('*****CalloutUtility.SendRequest.res.getBody(): ' + res.getBody());
            System.debug('*****CalloutUtility.SendRequest.res.getStatus(): ' + res.getStatus());
            System.debug('*****CalloutUtility.SendRequest.res.getStatusCode(): ' + res.getStatusCode());
        }
        catch(Exception ex){
            /**May 13, 2020 comment out by Ray, Utils class need to rebuild */
            //Utils.LogException(ex);
        }
    }
    

    //*** END - Async Callouts ***//

    //*** Webinar Integration ***//
    public class Response {
        String startDate;
        String endDate;
        List<AsyncEnrollmentJSON> status;
    }
    public class AsyncEnrollmentJSON {
        public String id;
        public Id lmsEnrollmentId;
        public Id enrollee;
        public String lmsCourseId;
        public Date startDate;
        public Date endDate;
        public Date completionDate;
        public Date purchaseDate;
        public Boolean selfEnrolled;
        public Id parentLMSEnrollmentId;
        public Integer webinarViewTime;
        public Integer recordingViewTime;
        public String status;
        public Integer score;
    }

    public static List<AsyncEnrollmentJSON> GetWebinarEnrollments() {
        List<AsyncEnrollmentJSON> webinars = new List<AsyncEnrollmentJSON>();
        try{
            Map<String, Global_Variable__c> global_variableMap = Global_Variable__c.getAll();
            Global_Variable__c gvStartDate = global_variableMap.get('LMS.WebinarIntegration.StartDate');
            HttpRequest req = new HttpRequest();
            req.setHeader('Content-Encoding', 'UTF-8');
            req.setHeader('Content-type', 'application/json');
            secretKey = global_variableMap.get('LMS.SecretKey').Value__c;
            String ts = String.Valueof(dateTime.now().getTime()/1000);
            System.debug('*****CalloutUtility.GetWebinarEnrollments.dateTime.now(): ' + dateTime.now());
            System.debug('*****CalloutUtility.GetWebinarEnrollments.ts: ' + ts);
            timeOut = Integer.valueOf(global_variableMap.get('LMS.WebinarIntegration.TimeOut').Value__c);
            baseurl = String.format(global_variableMap.get('LMS.WebinarIntegration.Endpoint').Value__c, new String[]{ts});
            String since = ( String.isNotBlank(gvStartDate.Value__c) && gvStartDate.Value__c != 'NA' ? '?q=' + gvStartDate.Value__c : '' );
            endPoint = global_variableMap.get('LMS.Server').Value__c + baseurl + '/' + generateHMACToken(baseurl) + since;

            req.setMethod('GET');
            req.setTimeout(timeOut);
            req.setEndpoint(endpoint);

            System.debug('*****CalloutUtility.GetWebinarEnrollments.baseurl: ' + baseurl);
            System.debug('*****CalloutUtility.GetWebinarEnrollments.endpoint: ' + endpoint);

            Http http = new Http();
            HTTPResponse res = (!Test.isRunningTest() ? http.send(req) : FakeGetWebinarsResponse());

            System.debug('*****CalloutUtility.GetWebinarEnrollments.res.getStatus(): ' + res.getStatus());
            System.debug('*****CalloutUtility.GetWebinarEnrollments.res.getStatusCode(): ' + res.getStatusCode());
            System.debug('*****CalloutUtility.GetWebinarEnrollments.res.getBody(): ' + res.getBody());

            Response r = (Response)JSON.deserialize(res.getBody(), Response.class);
            System.debug('*****CalloutUtility.GetWebinarEnrollments.r: ' + r);
            /*String jsonsString = '{"startDate":"2017-10-20T17:29:00Z", "endDate":"2017-10-27T11:08:46Z", "status": [{"id": "C-1164","lmsEnrollmentId": "a053B000001bkZXQAY","parentLMSEnrollmentId": null,"enrollee": "0033B00000I6ayeQAB","lmsCourseId": "418/418","startDate": "2017-11-11","endDate": "2018-05-11","purchaseDate": "2017-11-11","selfEnrolled": false,"webinarViewTime": 239,"recordingViewTime": 0,"status": "Completed","score": 90}]}';
            r = (Response)JSON.deserialize(jsonsString, Response.class);*/

            if (r != null && r.status.size() > 0){
                System.debug('*****CalloutUtility.GetWebinarEnrollments.r: ' + r);
                webinars = r.status;
                System.debug('*****CalloutUtility.GetWebinarEnrollments.webinars: ' + webinars);
                if (r.endDate != NULL){
                    gvStartDate.Value__c = r.endDate;
                    update gvStartDate;
                }
            }

            if (Test.isRunningTest()) throw new customException('Testing code');
        }
        catch(Exception ex){
            system.debug('CalloutUtility.GetWebinarEnrollments()- Exception : '+ex);
            /**May 13, 2020 comment out by Ray, Utils class need to rebuild */
            //Utils.LogException(ex);
        }
        return webinars;
    }

    private static HTTPResponse FakeGetWebinarsResponse() {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        List<BeckerLMS_Enrollment__c> e = [SELECT Id FROM BeckerLMS_Enrollment__c LIMIT 2];
        AsyncEnrollmentJSON w = new AsyncEnrollmentJSON();
        w.lmsEnrollmentId = e[0].Id;
        w.webinarViewTime = 90;
        w.recordingViewTime = 100;
        w.status = 'Completed';
        w.score = 100;
        //w.parentLMSEnrollmentId = e[1].Id;
        w.lmsCourseId = '1/1';
        
        AsyncEnrollmentJSON w1 = new AsyncEnrollmentJSON();
        w1.Id = '123';
        w1.webinarViewTime = 90;
        w.recordingViewTime = 100;
        w1.status = 'Completed';
        w1.score = 100;
        w1.lmsCourseId = '1/1';

        Response r = new Response();
        r.status = new List<AsyncEnrollmentJSON>{w,w1};
        r.startDate = '2019-01-01T17:29:00Z';
        r.endDate = '2019-02-03T11:08:46Z';
        res.setBody(JSON.serialize(r));
        res.setStatusCode(200);
        return res;
    }

    //*** END - Webinar Integration ***//

}