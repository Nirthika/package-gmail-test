// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

package wso2.gmail;

import org.wso2.ballerina.connectors.oauth2;
import ballerina.net.http;
import ballerina.util;
import ballerina.io;

@Description {value:"Gmail client connector"}
@Param {value:"userId: The userId of the Gmail account which means the email id"}
@Param {value:"accessToken: The accessToken of the Gmail account to access the gmail REST API"}
@Param {value:"refreshToken: The refreshToken of the Gmail App to access the gmail REST API"}
@Param {value:"clientId: The clientId of the App to access the gmail REST API"}
@Param {value:"clientSecret: The clientSecret of the App to access the gmail REST API"}
public connector ClientConnector (string userId, string accessToken, string refreshToken, string clientId,
                                  string clientSecret) {
    endpoint<oauth2:ClientConnector> gmailEP {
        create oauth2:ClientConnector("https://www.googleapis.com/gmail", accessToken, clientId, clientSecret, refreshToken,
                                      "https://www.googleapis.com", "/oauth2/v3/token");
    }

    http:HttpConnectorError e;
    Error errorResponse = {};

    @Description {value:"Send a mail"}
    @Param {value:"sendEmail: It is a struct. Which contains all optional parameters (to,subject,from,messageBody,
    cc,bcc,id,threadId)"}
    @Return {value:"response struct"}
    action sendEmail (Message sendEmail) (GmailAPI, Error) {
        http:OutRequest request = {};
        http:InResponse response = {};
        GmailAPI sendEmailResponse = {};
        string concatRequest = "";

        if (sendEmail != null) {
            string to = sendEmail.recipient;
            string subject = sendEmail.subject;
            string messageBody = sendEmail.body;
            string contentType = sendEmail.options.contentType;
            string htmlBody = sendEmail.options.htmlBody;
            string from = sendEmail.options.from;
            string cc = sendEmail.options.cc;
            string bcc = sendEmail.options.bcc;

            if (to != "" || to != null) {
                concatRequest = concatRequest + "to:" + to + "\n";
            }
            if (subject != "" || subject != null) {
                concatRequest = concatRequest + "subject:" + subject + "\n";
            }
            if (from != "" || from != null) {
                concatRequest = concatRequest + "from:" + from + "\n";
            }
            if (cc != "" || cc != null) {
                concatRequest = concatRequest + "cc:" + cc + "\n";
            }
            if (bcc != "" || bcc != null) {
                concatRequest = concatRequest + "bcc:" + bcc + "\n";
            }
            if (contentType != "" || contentType != null) {
                concatRequest = concatRequest + "content-type:" + contentType + "\n";
                concatRequest = concatRequest + "\n" + htmlBody + "\n";
            } else {
                concatRequest = concatRequest + "\n" + messageBody + "\n";
            }
        }
        string encodedRequest = util:base64Encode(concatRequest);
        encodedRequest = encodedRequest.replace("+", "-");
        encodedRequest = encodedRequest.replace("/", "_");
        json sendEmailJSONRequest = {"raw":encodedRequest};
        string sendEmailPath = "/v1/users/" + userId + "/messages/send";
        request.setHeader("Content-Type", "Application/json");
        request.setJsonPayload(sendEmailJSONRequest);
        response, e = gmailEP.post(sendEmailPath, request);
        int statusCode = response.statusCode;
        io:println("\nStatus code: " + statusCode);
        json sendEmailJSONResponse = response.getJsonPayload();

        if (statusCode == 200) {
            io:println(sendEmailJSONResponse);
            sendEmailResponse = <GmailAPI, gmailAPITrans()>sendEmailJSONResponse;
        } else {
            errorResponse.errorMessage = sendEmailJSONResponse.error;
        }
        return sendEmailResponse, errorResponse;
    }

    @Description {value:"Create a draft"}
    @Param {value:"createDraft: It is a struct. Which contains all optional parameters (to,subject,from,messageBody
    ,cc,bcc,id,threadId) to create draft message"}
    @Return {value:"response structs"}
    action createDraft (Message createDraft) (Draft, Error) {
        http:OutRequest request = {};
        http:InResponse response = {};
        Draft createDraftResponse = {};
        string concatRequest = "";

        if (createDraft != null) {
            string to = createDraft.recipient;
            string subject = createDraft.subject;
            string messageBody = createDraft.body;
            string contentType = createDraft.options.contentType;
            string htmlBody = createDraft.options.htmlBody;
            string from = createDraft.options.from;
            string cc = createDraft.options.cc;
            string bcc = createDraft.options.bcc;

            if (to != "" || to != null) {
                concatRequest = concatRequest + "to:" + to + "\n";
            }
            if (subject != "" || subject != null) {
                concatRequest = concatRequest + "subject:" + subject + "\n";
            }
            if (from != "" || from != null) {
                concatRequest = concatRequest + "from:" + from + "\n";
            }
            if (cc != "" || cc != null) {
                concatRequest = concatRequest + "cc:" + cc + "\n";
            }
            if (bcc != "" || bcc != null) {
                concatRequest = concatRequest + "bcc:" + bcc + "\n";
            }
            if (contentType != "" || contentType != null) {
                concatRequest = concatRequest + "content-type:" + contentType + "\n";
                concatRequest = concatRequest + "\n" + htmlBody + "\n";
            } else {
                concatRequest = concatRequest + "\n" + messageBody + "\n";
            }
        }
        string encodedRequest = util:base64Encode(concatRequest);
        encodedRequest = encodedRequest.replace("+", "-");
        encodedRequest = encodedRequest.replace("/", "_");
        json createDraftJSONRequest = {"message":{"raw":encodedRequest}};
        string createDraftPath = "/v1/users/" + userId + "/drafts";
        request.setHeader("Content-Type", "Application/json");
        request.setJsonPayload(createDraftJSONRequest);
        response, e = gmailEP.post(createDraftPath, request);
        int statusCode = response.statusCode;
        io:println("\nStatus code: " + statusCode);
        json createDraftJSONResponse = response.getJsonPayload();

        if (statusCode == 200) {
            io:println(createDraftJSONResponse);
            createDraftResponse = <Draft, draftTrans()>createDraftJSONResponse;
        } else {
            errorResponse.errorMessage = createDraftJSONResponse.error;
        }
        return createDraftResponse, errorResponse;
    }

    @Description {value:"Update a draft"}
    @Param {value:"draftId: Id of the draft to update"}
    @Param {value:"update: It is a struct. Which contains all optional parameters (to,subject,from,messageBody
    ,cc,bcc,id,threadId) to update draft"}
    @Return {value:"response structs"}
    action update (Draft draft, Message update) (Draft, Error) {
        http:OutRequest request = {};
        http:InResponse response = {};
        Draft updateResponse = {};
        string concatRequest = "";

        if (update != null) {
            string to = update.recipient;
            string subject = update.subject;
            string messageBody = update.body;
            string contentType = update.options.contentType;
            string htmlBody = update.options.htmlBody;
            string from = update.options.from;
            string cc = update.options.cc;
            string bcc = update.options.bcc;

            if (to != "" || to != null) {
                concatRequest = concatRequest + "to:" + to + "\n";
            }
            if (subject != "" || subject != null) {
                concatRequest = concatRequest + "subject:" + subject + "\n";
            }
            if (from != "" || from != null) {
                concatRequest = concatRequest + "from:" + from + "\n";
            }
            if (cc != "" || cc != null) {
                concatRequest = concatRequest + "cc:" + cc + "\n";
            }
            if (bcc != "" || bcc != null) {
                concatRequest = concatRequest + "bcc:" + bcc + "\n";
            }
            if (contentType != "" || contentType != null) {
                concatRequest = concatRequest + "content-type:" + contentType + "\n";
                concatRequest = concatRequest + "\n" + htmlBody + "\n";
            } else {
                concatRequest = concatRequest + "\n" + messageBody + "\n";
            }
        }
        string encodedRequest = util:base64Encode(concatRequest);
        encodedRequest = encodedRequest.replace("+", "-");
        encodedRequest = encodedRequest.replace("/", "_");
        json updateJSONRequest = {"message":{"raw":encodedRequest}};
        string updatePath = "/v1/users/" + userId + "/drafts/" + draft.id;
        request.setHeader("Content-Type", "Application/json");
        request.setJsonPayload(updateJSONRequest);
        response, e = gmailEP.put(updatePath, request);
        int statusCode = response.statusCode;
        io:println("\nStatus code: " + statusCode);
        json updateJSONResponse = response.getJsonPayload();

        if (statusCode == 200) {
            io:println(updateJSONResponse);
            updateResponse = <Draft, draftTrans()>updateJSONResponse;
        } else {
            errorResponse.errorMessage = updateJSONResponse.error;
        }
        return updateResponse, errorResponse;
    }

    @Description {value:"Lists the drafts in the user's mailbox"}
    @Param {value:"getDrafts: It is a struct. Which contains all optional parameters (includeSpamTrash,maxResults,
    pageToken,q) to list drafts"}
    @Return {value:"response structs"}
    action getDrafts (DraftsListFilter getDrafts) (Drafts, Error) {
        http:OutRequest request = {};
        http:InResponse response = {};
        Drafts getDraftsResponse = {};
        string uriParams;
        string getDraftsPath = "/v1/users/" + userId + "/drafts";

        if (getDrafts != null) {
            string includeSpamTrash = getDrafts.includeSpamTrash;
            string maxResults = getDrafts.maxResults;
            string pageToken = getDrafts.pageToken;
            string q = getDrafts.q;

            if (maxResults != "") {
                uriParams = uriParams + "&maxResults=" + maxResults;
            }
            if (includeSpamTrash != "") {
                uriParams = uriParams + "&includeSpamTrash=" + includeSpamTrash;
            }
            if (pageToken != "") {
                uriParams = uriParams + "&pageToken=" + pageToken;
            }
            if (q != "") {
                uriParams = uriParams + "&q=" + q;
            }
        }
        if (uriParams != "") {
            getDraftsPath = getDraftsPath + "?" + uriParams.subString(1, uriParams.length());
        }
        response, e = gmailEP.get(getDraftsPath, request);
        int statusCode = response.statusCode;
        io:println("\nStatus code: " + statusCode);
        json getDraftsJSONResponse = response.getJsonPayload();
        if (statusCode == 200) {
            io:println(getDraftsJSONResponse);
            getDraftsResponse = <Drafts, draftsTrans()>getDraftsJSONResponse;
        } else {
            errorResponse.errorMessage = getDraftsJSONResponse.error;
        }
        return getDraftsResponse, errorResponse;
    }

    @Description {value:"Delete a particular draft"}
    @Param {value:"draftId: Id of the draft to delete"}
    @Return {value:"response structs"}
    action deleteDraft (Draft draft) (StatusCode, Error) {
        http:OutRequest request = {};
        http:InResponse response = {};
        StatusCode deleteDraftResponse = {};
        string deleteDraftPath = "/v1/users/" + userId + "/drafts/" + draft.id;
        response, e = gmailEP.delete(deleteDraftPath, request);
        int statusCode = response.statusCode;
        json deleteDraftJSONResponse = {"statusCode":statusCode, "reasonPhrase":response.reasonPhrase};
        if (statusCode == 204) {
            deleteDraftResponse = <StatusCode, statusCodeTrans()>deleteDraftJSONResponse;
        } else {
            errorResponse.errorMessage = deleteDraftJSONResponse.error;
        }
        return deleteDraftResponse, errorResponse;
    }
}
