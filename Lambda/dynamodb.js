// establish EBS connection (EC2 service)
const AWS = require("aws-sdk");
const dynamodb = new AWS.DynamoDB();

// max WCUs/RCUs
const maxWCUs = 25;
const maxRCUs = 25;

// aggregate table WCUs/RCUs
function getTableWCUs(table) {
    var units = 0
    // provisioned units
    units += table.ProvisionedThroughput.WriteCapacityUnits;

    // provisioned global secondary index units
    if (table.GlobalSecondaryIndexes) {
        for (let index = 0; index < table.GlobalSecondaryIndexes.length; index++) {
            units += table.GlobalSecondaryIndexes[index].WriteCapacityUnits;
        }
    }
    return units;
}
function getTableRCUs(table) {
    var units = 0
    // provisioned units
    units += table.ProvisionedThroughput.ReadCapacityUnits;

    // provisioned global secondary index units
    if (table.GlobalSecondaryIndexes) {
        for (let index = 0; index < table.GlobalSecondaryIndexes.length; index++) {
            units += table.GlobalSecondaryIndexes[index].ReadCapacityUnits;
        }
    }
    return units;
}

// main handler
exports.handler = async (event, context, callback) => {
    // get table reference
    var tableName = event.tableDescription.tableName;

    // run termination checks
    var terminate = false;
    var terminationCause = "";

    // check WCUs and RCUs of all tables
    if (!terminate) {
        var totalWCUs = 0;
        var totalRCUs = 0;

        var allTableData = await dynamodb.listTables({}).promise();
        var lastEvaluatedTableName = allTableData.LastEvaluatedTableName;

        for (let index = 0; index < allTableData.TableNames.length && !terminate; index ++){
            var tableData = await dynamodb.describeTable({
                TableName: allTableData.TableNames[index]
            }).promise();
            totalWCUs += getTableWCUs(tableData.Table);
            totalRCUs += getTableRCUs(tableData.Table);
            terminate = (totalWCUs > maxWCUs || totalRCUs > maxRCUs);
        }

        // loop while there are still tables to be checked
        while (lastEvaluatedTableName && !terminate) {
            allTableData = await dynamodb.listTables({
                ExclusiveStartTableName: lastEvaluatedTableName
            }).promise();
            lastEvaluatedTableName = allTableData.LastEvaluatedTableName;

            for (let index = 0; index < allTableData.TableNames.length && !terminate; index ++){
                var tableData = await dynamodb.describeTable({
                    TableName: allTableData.TableNames[index]
                }).promise();
                totalWCUs += getTableWCUs(tableData.Table);
                totalRCUs += getTableRCUs(tableData.Table);
                terminate = (totalWCUs > maxWCUs || totalRCUs > maxRCUs);
            }
        }

        if (terminate) {
            if (totalWCUs > maxWCUs) {
                terminationCause = "Total WCUs will exceed Free Tier: "
                + totalWCUs + " > " + maxWCUs;
            }
            else {
                terminationCause = "Total RCUs will exceed Free Tier: "
                + totalRCUs + " > " + maxRCUs;
            }
        }
    }

    // table is marked for deletion
    if (terminate) {
        console.log("DynamdoDB table " + tableName + " marked for deletion");

        // attempt to delete table
        try {
            var terminateData = await dynamodb.deleteTable({
                TableName: tableName
            }).promise();
        }
        catch (error) {
            console.log(error);
            return;
        }

        // TODO: publish SNS message on completion
        console.log("DynamoDB table " + tableName + " deleted" 
        + "\nCause: " + terminationCause);
        console.log("Deletion Data \n" + JSON.stringify(terminateData));
    }
    // keep table
    else {
        console.log("DynamoDB table " + tableName + " complies with Free-Tier")
    }
    return;
};