// establish rds connection
const AWS = require("aws-sdk");
const rds = new AWS.RDS();

// check DB engine
const freeTierDBEngines = [
    "mariadb",
    "mysql",
    "oracle-se",
    "oracle-se1",
    "postgres",
    "sqlserver-ex"
];
function isFreeTierDBEngine(instanceData) {
    return freeTierDBEngines.indexOf(instanceData.Engine) > -1;
}

// check instance class
function isFreeTierDBInstanceClass(instanceData) {
    return instanceData.DBInstanceClass  == "db.t2.micro";
}

// check DB storage
const maxStorageSizeInGB = 20;

// check instance hours
function areFreeTierHoursLeft(instanceData) {
    // TODO: calculate used and remaining free-tier hours left
    return true;
}

// main handler
exports.handler = async (event, context, callback) => {
    // get instance ID reference
    var instanceID = event["dBInstanceIdentifier"];
    var params = {
        DBInstanceIdentifier: instanceID
    };
    
    try {
        // get instance data
        var describeData = await rds.describeDBInstances(params).promise();
        var instanceData = describeData.DBInstances[0];
    }
    catch (error) {
        console.log(error);
        return;
    }

    // don't try to delete if the DB is already being deleted
    if (instanceData.DBInstanceStatus == "deleting") {
        console.log("Instance " + instanceID + " is already being deleted");
        return;
    }

    // run termination checks
    var terminate = false;
    var terminationCause = "";

    if (!terminate && !isFreeTierDBEngine(instanceData)) {
        terminate = true;
        terminationCause = "Non-compliant DB engine: " + instanceData.Engine;
    }

    if (!terminate && !isFreeTierDBInstanceClass(instanceData)){
        terminate = true;
        terminationCause = "Non-compliant instance class: " + instanceData.DBInstanceClass;
    }

    // check available storage
    if (!terminate) {
        var storageSizeUsed = 0;

        var allInstanceData = await rds.describeDBInstances().promise();
        for (let index = 0; index < allInstanceData.length; index++) {
            storageSizeUsed += allInstanceData.DBInstances[index].AllocatedStorage;
        }

        terminate = storageSizeUsed > maxStorageSizeInGB;
        if (terminate) {
            terminationCause = "Total Storage size will exceed Free Tier: " + storageSizeUsed + "GB > " 
            + maxStorageSizeInGB + "GB";
        }
    }

    if (!terminate && !areFreeTierHoursLeft(instanceData)) {
        terminate = true;
        terminationCause = "No more RDS Free Tier hours for the rest of the month"
    }

    // instance is marked for termination
    if (terminate) {
        console.log("Instance " + instanceID + " marked for termination");

        // attempt to delete instance
        try {
            var deleteParams = {
                DBInstanceIdentifier: instanceID,
                SkipFinalSnapshot: true
            };
            var terminateData = await rds.deleteDBInstance(deleteParams).promise();
        }
        catch (error) {
            console.log(error);
            return;
        }

        // TODO: publish SNS message on completion
        console.log("Database instance " + instanceID + " deleted" 
        + "\nCause: " + terminationCause);
        console.log("Deletion Data \n" + JSON.stringify(terminateData));
    }
    // keep instance
    else {
        console.log("Database instance " + instanceID + " complies with Free Tier")
    }
    return;
};