// establish ES connection
const AWS = require("aws-sdk");
const es = new AWS.ES();

// check cache node types
const freeTierInstanceTypes = [
    "t2.small.elasticsearch",
    "t3.small.elasticsearch"
];
function isFreeTierInstanceType(esDomainData) {
    return freeTierInstanceTypes.indexOf(esDomainData.ElasticsearchClusterConfig.InstanceType) > -1;
}

// check es domain hours
function areFreeTierHoursLeft(esDomainData) {
    // TODO: calculate used and remaining free-tier hours left
    return true;
}

// main handler
exports.handler = async (event, context, callback) => {
    // get es domain reference
    var domainName = event["domainName"];
    var params = {
        DomainName: domainName
    };

    // run termination checks
    var terminate = false;
    var terminationCause = "";

    // get ES domain data
    try {
        var describeData = await es.describeElasticsearchDomain(params).promise();
        var esDomainData = describeData.DomainStatus;
    }
    catch (error) {
        console.log(error);
        return;
    }

    // check cache node type
    if (!terminate){
        terminate = !isFreeTierInstanceType(esDomainData);

        if (terminate) {
            terminationCause = "Non-compliant instance type: " + esDomainData.ElasticsearchClusterConfig.InstanceType;
        }
    }

    if (!terminate && !areFreeTierHoursLeft(esDomainData)) {
        terminate = true;
        terminationCause = "No more ES Free-Tier hours for the rest of the month"
    }

    // ES domain is marked for termination
    if (terminate) {
        console.log("Domain " + domainName + " marked for termination");

        // attempt to delete ES domain
        try {
            var terminateData = await es.deleteElasticsearchDomain(params).promise();
        }
        catch (error) {
            console.log(error);
            return;
        }

        // TODO: publish SNS message on completion
        console.log("ES domain " + domainName + " terminated" 
        + "\nCause: " + terminationCause);
        console.log("Termination Data \n" + JSON.stringify(terminateData));
    }
    // keep es domain
    else {
        console.log("ES domain " + domainName + " complies with Free-Tier")
    }
    return;
};