// // Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.

// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein is strictly forbidden, unless permitted by WSO2 in accordance with
// the WSO2 Software License available at: https://wso2.com/licenses/eula/3.2
// For specific language governing the permissions and limitations under
// this license, please see the license as well as any agreement you’ve
// entered into with WSO2 governing the purchase of this software and any
// associated services.

import ballerinax/health.fhir.r4;
import ballerina/random;
// import ballerina/log;
// import ballerina/io;
import ballerina/http;

// import ballerina/io;

// Initializes an `isolated` variable using
// an `isolated` expression.

isolated map<r4:Patient> data = {};

isolated function addJson(json patient) returns r4:FHIRError|string {
    lock {
        r4:Patient|error parsedResource = r4:parse(patient.clone(), r4:Patient).ensureType();

        if parsedResource is error {
            return r4:createFHIRError("Can't parse the resource", r4:CODE_SEVERITY_ERROR,
            r4:PROCESSING_NOT_FOUND,
            httpStatusCode = http:STATUS_BAD_REQUEST);
        } else {
            return add(parsedResource);
        }

    }
}

isolated function add(r4:Patient patient) returns r4:FHIRError|string {
    lock {
        string? id = patient.id ?: "";
        if id is "" {
            int|random:Error randomInteger = random:createIntInRange(100000, 1000000);

            if randomInteger is random:Error {
                return r4:createFHIRError("Something went wrong while processing the request",
                r4:ERROR,
                r4:PROCESSING);
            }

            string randomId = randomInteger.toBalString();
            patient.id = randomId;
            data[randomId] = patient.clone();
        } else {
            data[<string>patient.id] = patient.clone();
        }
        return <string>patient.id;
    }
}

isolated function get(string id) returns r4:FHIRError|r4:Patient {
    r4:Patient clone = {};
    lock {

        if (data.hasKey(id)) {
            clone = data.get(id).clone();
        } else {
            return r4:createFHIRError("No resource found for the privided id", r4:CODE_SEVERITY_ERROR,
            r4:PROCESSING_NOT_FOUND,
            diagnostic = "No resource found for the privided id: " + id,
            httpStatusCode = http:STATUS_BAD_REQUEST
            );
        }

    }
    return clone;
}

public isolated function search(map<string[]> searchParameters) returns r4:FHIRError|r4:Patient[] {

    // Define the search params here supported by Sandbox
    string[] supportedParams = ["_id", "gender", "active"];

    //Create cloned copy of the in-memory patients map to an array 
    r4:Patient[] patients = [];
    lock {
        patients = data.clone().toArray();
    }

    //Check whether there any search parameters in the requested search parameter list,
    //other than _count & _offset
    string[] filteredParams = searchParameters.keys().filter(k => k != "_count").filter(k => k != "_offset");

    // If no search parameters other than _count & _offset skip the search process
    if filteredParams.length() == 0 {
        // Apply offset and count here
        return patients;
    }

    foreach var searchParam in filteredParams {

        // If In-memory patients map is empty skip the search process
        if patients.length() == 0 {
            break;
        }

        // Check whether the current(loop) search param is in the supported search param list
        string[] allowedsearchParam = supportedParams.filter(s => s == searchParam);

        if allowedsearchParam.length() != 1 {
            // return error saying currently, the particular search param is not supported 
            return r4:createFHIRError("Request search parameter is not implemented",
            r4:ERROR,
            r4:PROCESSING_NOT_SUPPORTED,
            diagnostic = "Request search parameter is not implemented: " + searchParam,
            httpStatusCode = http:STATUS_BAD_REQUEST);
        }

        // Retrieve the current(loop) search param values
        string[]? valuelist = searchParameters[allowedsearchParam[0]];
        string[] value = valuelist ?: [];

        if value.length() != 0 {
            r4:Patient[] filteredList = [];

            if searchParam == "_id" {
                string param = "id";

                foreach var queriedValue in value {
                    r4:Patient[] result = from r4:Patient entry in patients
                        where entry[param] == queriedValue
                        select entry;
                    filteredList.push(...result);
                }
            }

            if searchParam == "gender" {

                foreach var queriedValue in value {
                    r4:Patient[] result = from r4:Patient entry in patients
                        where entry["gender"] == queriedValue
                        select entry;
                    filteredList.push(...result);
                }
            }

            if searchParam == "active" {

                foreach var queriedValue in value {
                    boolean|error boolValue = boolean:fromString(queriedValue);

                    if boolValue is error {
                        return r4:createFHIRError("Value provided for the active search parameter is not supported",
                                        r4:ERROR,
                                        r4:INVALID,
                                        diagnostic = "Request search parameter value for the search parameter \"active\" is invalid: " + searchParam,
                                        httpStatusCode = http:STATUS_BAD_REQUEST);
                    }

                    r4:Patient[] result = from r4:Patient entry in patients
                        where entry["active"] == boolValue
                        select entry;
                    filteredList.push(...result);
                }
            }
            patients = filteredList;
        }
    }
    return patients;
}

// This init method will read some initial patient resource from a file and initialise the internal map
// function init() returns error? {
//     io:print("Reading the patient data from resources/data.json and initialising the in memory patients map");

//     json[]|error patientsArray = <json[]>check io:fileReadJson("resources/data.json");

//     if patientsArray is error {
//         log:printError("Something went wrong", patientsArray);

//     } else {
//         foreach json res in patientsArray {
//             _ = check addJson(res);
//         }
//     }
// }