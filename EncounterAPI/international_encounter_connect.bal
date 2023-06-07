// // Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com).

// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
//
// AUTO-GENERATED FILE.
//
// This file is auto-generated by Ballerina Team for implementing source system connections.
// Developers are allowed modify this file as per the requirement.

import ballerina/http;
import ballerinax/health.fhir.r4;

configurable string sourceSystem = "http://localhost:9091";

final string READ = sourceSystem.endsWith("/") ? "read/" : "/read/";
final string SEARCH = sourceSystem.endsWith("/") ? "search" : "/search";
final string CREATE = sourceSystem.endsWith("/") ? "create" : "/create";

final http:Client sourceEp = check new (sourceSystem);

public isolated class InternationalEncounterSourceConnect {

    *EncounterSourceConnect;
    isolated function profile() returns r4:uri {
        return "http://hl7.org/fhir/StructureDefinition/Encounter";
    }

    isolated function read(string id, r4:FHIRContext ctx) returns Encounter|r4:FHIRError {
        return get(id);
    }

    isolated function search(map<r4:RequestSearchParameter[]> params, r4:FHIRContext ctx) returns r4:Bundle|Encounter[]|r4:FHIRError {

        //convert search parameters to map<string[]>
        map<string[]> searchParams = {};

        foreach var [key, requestSearchParamArray] in params.entries() {

            //Extract the each search param values and create an array of values
            string[] values = [];
            foreach var requestSearchParam in requestSearchParamArray {
                values.push(requestSearchParam.value);
            }

            //If the values array is empty no need to create entry in searchParams map 
            if values.length() > 0 {
                searchParams[key] = values;
            }
        }

        return search(searchParams);
    }

    isolated function create(r4:FHIRResourceEntity entity, r4:FHIRContext ctx) returns string|r4:FHIRError {

        //Implement source system connection here and persist FHIR resource.
        //Must respond with ID in order to create Location header

        r4:Encounter|error requestPayload = entity.unwrap().ensureType(r4:Encounter);

        if requestPayload is error {
            return r4:createFHIRError("Could not process the request payload", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
        } else {
            return add(requestPayload);
        }
    }
}
