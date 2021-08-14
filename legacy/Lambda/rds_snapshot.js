// establish EBS connection (EC2 service)
const AWS = require("aws-sdk");
const rds = new AWS.RDS();

// max volume size
const maxBackupAndStorageSizeInGB = 20;

// main handler
exports.handler = async (event, context, callback) => {
    // get snapshot ID reference
    var snapshotID = event["SourceIdentifier"];

    // run termination checks
    var terminate = false;
    var terminationCause = "";

    // check available storage
    if (!terminate) {
        var backupAndSnapshotStorageUsed = 0;
        var snapshotStorageUsed = 0;
        var backupStorageUsed = 0;

        // check snapshot storage
        if (!terminate) {
            var snapshotData = await rds.describeDBSnapshots({
                SnapshotType: "manual"
            }).promise();
            var snapshots = snapshotData.DBSnapshots;

            // aggregate snapshot sizes
            for (let index = 0; index < snapshots.length && !terminate; index++) {
                var snapshot = snapshots[index];

                snapshotStorageUsed += snapshot.AllocatedStorage;
                backupAndSnapshotStorageUsed += snapshot.AllocatedStorage;
                terminate = backupAndSnapshotStorageUsed > maxBackupAndStorageSizeInGB;
            }
        }

        // check backup storage
        if (!terminate) {
            var backupData = await rds.describeDBInstanceAutomatedBackups().promise();
            var backups = backupData.DBInstanceAutomatedBackups;

            // aggregate backup sizes
            for (let index = 0; index < backups.length && !terminate; index++) {
                var backup = backups[index];

                backupStorageUsed += backup.AllocatedStorage;
                backupAndSnapshotStorageUsed += backup.AllocatedStorage;
                terminate = backupAndSnapshotStorageUsed > maxBackupAndStorageSizeInGB;
            }
        }

        if (terminate) {
            terminationCause = "Total Backup and Snapshot size will exceed Free Tier: " 
            + backupAndSnapshotStorageUsed + "GB > " 
            + maxBackupAndStorageSizeInGB + "GB";
        }
    }

    // snapshot is marked for deletion
    if (terminate) {
        console.log("Snapshot " + snapshotID + " marked for deletion");

        // attempt to delete snapshot
        try {
            var terminateData = await rds.deleteDBSnapshot({
                DBSnapshotIdentifier: snapshotID
            }).promise();
        }
        catch (error) {
            console.log(error);
            return;
        }

        // TODO: publish SNS message on completion
        console.log("Snapshot " + snapshotID + " deleted" 
        + "\nCause: " + terminationCause);
        console.log("Deletion Data \n" + JSON.stringify(terminateData));
    }
    // keep snapshot
    else {
        console.log("Snapshot " + snapshotID + " complies with Free-Tier")
    }
    return;
};