import health.fhir.r4;
import ballerina/task;
import ballerina/io;
import ballerina/time;
import ballerina/log;

// Creates a job to be executed by the scheduler.
class Job {

    *task:Job;
    string jobIdentifier;

    // Executes this function when the scheduled trigger fires.
    public function execute() {
        r4:Organization[] organizations = getAll();

        r4:Organization[] result = from r4:Organization entry in organizations
            where entry["meta"]["lastUpdated"] != "2001-07-15T05:30:29.575+00:00" && self.calcDifference(<string>entry["meta"]["lastUpdated"]) >= CLEANUP_TIME_DURATION
            select entry;

        io:println(result.forEach(function(r4:Organization p) {
            delete(<string>p.id);
            io:println(p);
        }));

    }

    isolated function calcDifference(string lastUpdated) returns decimal {

        time:Utc|error utc = time:utcFromString(lastUpdated);

        if utc is error {
            return CLEANUP_RECUR_FREQUENCY;
        } else {
            time:Utc now = time:utcNow();
            io:println("Now: " + time:utcToString(now));
            time:Seconds seconds = time:utcDiffSeconds(now, utc);
            io:println("Seconds: " + seconds.toBalString());
            return seconds;
        }
    }

    isolated function init(string jobIdentifier) {
        self.jobIdentifier = jobIdentifier;
    }
}

function init() returns error? {

    _ = check task:scheduleJobRecurByFrequency(new Job("Data clean up job"), CLEANUP_RECUR_FREQUENCY);

    // This init method will read some initial organization resource from a file and initialise the internal map

    log:printDebug("Reading the organization data from resources/data.json and initialising the in memory organizations map");

    json[]|error organizationsArray = <json[]>check io:fileReadJson("resources/data.json");

    if organizationsArray is error {
        log:printError("Something went wrong", organizationsArray);

    } else {
        foreach json res in organizationsArray {
            _ = check addJson(res);
        }
    }
}
