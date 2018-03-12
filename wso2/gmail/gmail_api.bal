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

public struct UserProfile {
    string emailAddress;
    int messagesTotal;
    int threadsTotal;
    string historyId;
}

public struct Message {
    string recipient;
    string subject;
    string body;
    Options options;
}

public struct Options {
    string contentType;
    string htmlBody;
    string from;
    string cc;
    string bcc;
}

public struct Header {
    string name;
    string value;
}

public struct Parts {
    string partId;
    string mimeType;
    string filename;
    Header[] headers;
    Body body;
}

public struct Body {
    string attachmentId;
    int size;
    string data;
}

public struct MessagePayload {
    string partId;
    string mimeType;
    string filename;
    Header[] headers;
    Body body;
    Parts[] parts;
}

public struct GmailAPI {
    string id;
    string threadId;
    string[] labelIds;
    string snippet;
    string historyId;
    string internalDate;
    MessagePayload payload;
    int sizeEstimate;
}

public struct Draft {
    string id;
    GmailAPI message;
}

public struct Drafts {
    Draft[] drafts;
    int resultSizeEstimate;
    string nextPageToken;
}

public struct DraftsListFilter {
    string includeSpamTrash;
    string maxResults;
    string pageToken;
    string q;
}

public struct Error {
    json errorMessage;
}

public struct StatusCode {
    int statusCode;
    string reasonPhrase;
}

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

    //string refreshTokenEP = "https://www.googleapis.com";
    //string refreshTokenPath = "/oauth2/v3/token";
    //string baseURL = "https://www.googleapis.com/gmail";

    @Description {value:"Retrieve the user profile information"}
    @Return {value:"response structs"}
    action getUserProfile () (UserProfile, Error) {
        http:OutRequest request = {};
        http:InResponse response = {};
        UserProfile getUserProfileResponse = {};
        string getUserProfilePath = "/v1/users/" + userId + "/profile";

        response, e = gmailEP.get(getUserProfilePath, request);
        int statusCode = response.statusCode;
        io:println("\nStatus code: " + statusCode);
        json gmailJSONResponse = response.getJsonPayload();

        if (statusCode == 200) {
            getUserProfileResponse = <UserProfile, userProfileTrans()>gmailJSONResponse;
        } else {
            errorResponse.errorMessage = gmailJSONResponse.error;
        }
        return getUserProfileResponse, errorResponse;
    }

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

    @Description {value:"Send a particular draft"}
    @Param {value:"draftId: Id of the draft to send"}
    @Return {value:"response structs"}
    action send (string draftId) (GmailAPI, Error) {
        http:OutRequest request = {};
        http:InResponse response = {};
        GmailAPI sendResponse = {};
        json sendJSONRequest = {"id":draftId};
        string sendPath = "/v1/users/" + userId + "/drafts/send";
        request.setHeader("Content-Type", "Application/json");
        request.setJsonPayload(sendJSONRequest);
        response, e = gmailEP.post(sendPath, request);
        int statusCode = response.statusCode;
        io:println("\nStatus code: " + statusCode);
        json sendJSONResponse = response.getJsonPayload();

        if (statusCode == 200) {
            sendResponse = <GmailAPI, gmailAPITrans()>sendJSONResponse;
        } else {
            errorResponse.errorMessage = sendJSONResponse.error;
        }
        return sendResponse, errorResponse;
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

transformer <json jsonUserProfile, UserProfile userProfile> userProfileTrans() {
    userProfile.emailAddress = jsonUserProfile.emailAddress.toString();
    userProfile.messagesTotal, _ = <int>jsonUserProfile.messagesTotal.toString();
    userProfile.threadsTotal, _ = <int>jsonUserProfile.threadsTotal.toString();
    userProfile.historyId = jsonUserProfile.historyId.toString();
}

transformer <json jsonMessage, Message message> messageTrans() {
    message.recipient = jsonMessage.to.toString();
    message.subject = jsonMessage.subject.toString();
    message.body = jsonMessage.messageBody.toString();
    message.options = jsonMessage.options != null?<Options, optionsTrans()>jsonMessage.options:{};
}

transformer <json jsonMessage, Options options> optionsTrans() {
    options.contentType = jsonMessage.contentType.toString();
    options.htmlBody = jsonMessage.htmlBody.toString();
    options.from = jsonMessage.from.toString();
    options.cc = jsonMessage.cc.toString();
    options.bcc = jsonMessage.bcc.toString();
}

transformer <json jsonHeader, Header header> headerTrans() {
    header.name = jsonHeader.name.toString();
    header.value = jsonHeader.value.toString();
}

transformer <json jsonParts, Parts parts> partsTrans() {
    parts.partId = jsonParts.partId.toString();
    parts.mimeType = jsonParts.mimeType.toString();
    parts.filename = jsonParts.filename.toString();
    parts.headers = jsonParts.headers != null?getHeaders(jsonParts.headers):[];
    parts.body = jsonParts.body != null?<Body, bodyTrans()>jsonParts.body:{};
}

transformer <json jsonBody, Body body> bodyTrans() {
    body.attachmentId = jsonBody.attachmentId.toString();
    body.size, _ = <int>jsonBody.size.toString();
    body.data = jsonBody.data.toString();
}

transformer <json jsonMessagePayload, MessagePayload messagePayload> messagePayloadTrans() {
    messagePayload.partId = jsonMessagePayload.partId.toString();
    messagePayload.mimeType = jsonMessagePayload.mimeType.toString();
    messagePayload.filename = jsonMessagePayload.filename.toString();
    messagePayload.headers = jsonMessagePayload.headers != null?getHeaders(jsonMessagePayload.headers):[];
    messagePayload.body = jsonMessagePayload.body != null?<Body, bodyTrans()>jsonMessagePayload.body:{};
    messagePayload.parts = jsonMessagePayload.parts != null?getParts(jsonMessagePayload.parts):[];
}

transformer <json jsonGmailAPI, GmailAPI gmailAPI> gmailAPITrans() {
    gmailAPI.id = jsonGmailAPI.id.toString();
    gmailAPI.threadId = jsonGmailAPI.threadId.toString();
    gmailAPI.labelIds = jsonGmailAPI.labelIds != null?getLabelIds(jsonGmailAPI.labelIds):[];
    gmailAPI.snippet = jsonGmailAPI.snippet != null?jsonGmailAPI.snippet.toString():null;
    gmailAPI.historyId = jsonGmailAPI.historyId != null?jsonGmailAPI.historyId.toString():null;
    gmailAPI.internalDate = jsonGmailAPI.internalDate != null?jsonGmailAPI.internalDate.toString():null;
    gmailAPI.payload = jsonGmailAPI.payload != null?<MessagePayload, messagePayloadTrans()>jsonGmailAPI.payload:{};
    gmailAPI.sizeEstimate = jsonGmailAPI.sizeEstimate != null?<int, convertToInt()>jsonGmailAPI.sizeEstimate:0;
}

transformer <json jsonDraft, Draft draft> draftTrans() {
    draft.id = jsonDraft.id.toString();
    draft.message = jsonDraft.message != null?<GmailAPI, gmailAPITrans()>jsonDraft.message:{};
}

transformer <json jsonDrafts, Drafts drafts> draftsTrans() {
    drafts.drafts = getDrafts(jsonDrafts.drafts);
    drafts.resultSizeEstimate = jsonDrafts.resultSizeEstimate != null?<int, convertToInt()>jsonDrafts.resultSizeEstimate:0;
    drafts.nextPageToken = jsonDrafts.nextPageToken != null?jsonDrafts.nextPageToken.toString():null;
}

transformer <json jsonDraftsListFilter, DraftsListFilter draftsListFilter> draftsListFilterTrans() {
    draftsListFilter.includeSpamTrash = jsonDraftsListFilter.includeSpamTrash != null?jsonDraftsListFilter.includeSpamTrash.toString():null;
    draftsListFilter.maxResults = jsonDraftsListFilter.maxResults != null?jsonDraftsListFilter.maxResults.toString():null;
    draftsListFilter.pageToken = jsonDraftsListFilter.pageToken != null?jsonDraftsListFilter.pageToken.toString():null;
    draftsListFilter.q = jsonDraftsListFilter.q != null?jsonDraftsListFilter.q.toString():null;
}

transformer <json jsonStatusCode, StatusCode statusCode> statusCodeTrans() {
    statusCode.statusCode, _ = <int>jsonStatusCode.statusCode.toString();
    statusCode.reasonPhrase = jsonStatusCode.reasonPhrase.toString();
}

transformer <json jsonVal, int intVal> convertToInt() {
    intVal, _ = (int)jsonVal;
}

function getHeaders (json jsonHeaders) (Header[]) {
    int i = 0;
    Header[] headers = [];
    foreach jsonHeader in jsonHeaders {
        headers[i] = <Header, headerTrans()>jsonHeader;
        i = i + 1;
    }
    return headers;
}

function getParts (json jsonParts) (Parts[]) {
    int i = 0;
    Parts[] parts = [];
    foreach jsonPart in jsonParts {
        parts[i] = <Parts, partsTrans()>jsonPart;
        i = i + 1;
    }
    return parts;
}

function getLabelIds (json allLabelIds) (string[]) {
    int i = 0;
    string[] labelIds = [];
    foreach aLabelId in allLabelIds {
        labelIds[i] = aLabelId.toString();
        i = i + 1;
    }
    return labelIds;
}

function getDrafts (json jsonDrafts) (Draft[]) {
    int i = 0;
    Draft[] drafts = [];
    foreach jsonDraft in jsonDrafts {
        drafts[i] = <Draft, draftTrans()>jsonDraft;
        i = i + 1;
    }
    return drafts;
}