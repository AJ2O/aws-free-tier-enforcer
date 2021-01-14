// establish EC2 connection
const AWS = require("aws-sdk");
const ec2 = new AWS.EC2();

// check instance type
function isFreeTierInstanceType(instanceData) {
    return instanceData.InstanceType == "t2.micro";
    // TODO: some regions allow t3.micro in Free-Tier
}

// check instance hours
function areFreeTierHoursLeft(instanceData) {
    // TODO: calculate used and remaining free-tier hours left
    return true;
}

// terminate instance
function terminateInstance(instanceID){
    var params = {
        InstanceIds: [
            instanceID
        ]
    };
}

// main handler
exports.handler = async (event, context, callback) => {
    // get instance ID reference
    var instanceID = event["instance-id"];
    var params = {
        InstanceIds: [
            instanceID
        ]
    };

    // don't try to terminate if already being terminated
    try {
        var statusParams = {
            InstanceIds: [
                instanceID
            ],
            IncludeAllInstances: true
        };
        statusData = await ec2.describeInstanceStatus(statusParams).promise();
        instanceState = statusData.InstanceStatuses[0].InstanceState;

        if (instanceState == "shutting-down" || instanceState == "terminated"){
            console.log("Instance " + instanceID + " is already " + instanceState);
            return;
        }
    }
    catch (error) {
        console.log(error);
        return;
    }
    
    try {
        // get instance data
        var describeData = await ec2.describeInstances(params).promise();
        var instanceData = describeData.Reservations[0].Instances[0];
    }
    catch (error) {
        console.log(error);
        return;
    }

    // run termination checks
    var terminate = false;
    var terminationCause = "";

    if (!terminate && !isFreeTierInstanceType(instanceData)){
        terminate = true;
        terminationCause = "Non-compliant instance type: " + instanceData.InstanceType;
    }

    if (!terminate && !areFreeTierHoursLeft(instanceData)) {
        terminate = true;
        terminationCause = "No more EC2 Free-Tier hours for the rest of the month"
    }

    // instance is marked for termination
    if (terminate) {
        console.log("Instance " + instanceID + " marked for termination");

        // attempt to delete instance
        try {
            var terminateData = await ec2.terminateInstances(params).promise();
        }
        catch (error) {
            console.log(error);
            return;
        }

        // TODO: publish SNS message on completion
        console.log("Instance " + instanceID + " terminated" 
        + "\nCause: " + terminationCause);
        console.log("Termination Data \n" + JSON.stringify(terminateData));
    }
    // keep instance
    else {
        console.log("Instance " + instanceID + " complies with Free-Tier")
    }
    return;
};