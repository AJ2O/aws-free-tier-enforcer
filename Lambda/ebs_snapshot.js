// establish EBS connection (EC2 service)
const AWS = require("aws-sdk");
const ebs = new AWS.EBS();
const ec2 = new AWS.EC2();

// max volume size
const maxSnapshotStorageInGB = 1;

// helper to convert a list of blocks into GB
const bytesInAGB = 1024 * 1024 * 1024;
function convertBlockSizeToGB(blockSize) {
    return blockSize / bytesInAGB;
}
function calculateBlockSizeInGB(blockList) {
    var blockSizeInGB = 0;
    for (let index = 0; index < blockList.length; index++) {
        blockSizeInGB += convertBlockSizeToGB(blockList[index].BlockSize);
    }
    return blockSizeInGB;
}

// main handler
exports.handler = async (event, context, callback) => {
    // get snapshot ID reference
    var snapshotID = event["snapshotId"];

    // run termination checks
    var terminate = false;
    var terminationCause = "";

    // check available storage
    if (!terminate) {
        var snapshotData = await ec2.describeSnapshots({
            OwnerIds: [
                "self"
            ]
        }).promise();
        var snapshots = snapshotData.Snapshots;

        // sort snapshots by volume, then by time ascending
        snapshots.sort((a, b) => 
            (a.VolumeId < b.VolumeId) ? 1 : 
            (a.VolumeId > b.VolumeId) ? -1 : 
            (a.StartTime < b.StartTime) ? -1 : 1);

        // How Incremental Snapshots Work: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSSnapshots.html#how_snapshots_work
        var snapshotStorageUsed = 0;
        var prevSnapshotID = "";
        var prevVolumeID = "";

        // iteratively compare snapshots of the same volume
        for (let index = 0; index < snapshots.length && !terminate; index++) {
            var snapshot = snapshots[index];
            
            // if the volume is different, this is a base snapshot
            if (snapshot.VolumeId != prevVolumeID) {
                snapshotStorageUsed += snapshot.VolumeSize;
                prevVolumeID = snapshot.VolumeId;
            }
            // if the volume is the same, compare the changed blocks
            else {
                try {
                    var changedBlocks = await ebs.listChangedBlocks({
                        FirstSnapshotId: prevSnapshotID,
                        SecondSnapshotId: snapshot.SnapshotId
                    }).promise();
                    var nextToken = changedBlocks.NextToken;
                    snapshotStorageUsed += calculateBlockSizeInGB(changedBlocks);
                    terminate = snapshotStorageUsed > maxSnapshotStorageInGB;

                    // loop while there are still changed blocks to validate
                    while (nextToken && !terminate) {
                        changedBlocks = await ebs.listChangedBlocks({
                            FirstSnapshotId: prevSnapshotID,
                            SecondSnapshotId: snapshot.SnapshotId,
                            NextToken: nextToken
                        }).promise();
                        nextToken = changedBlocks.NextToken;
                        snapshotStorageUsed += calculateBlockSizeInGB(changedBlocks);
                        terminate = snapshotStorageUsed > maxSnapshotStorageInGB;
                    }
                }
                catch (error) {
                    console.log(error);
                    return;
                }
            }
            prevSnapshotID = snapshot.SnapshotId;
        }

        terminate = snapshotStorageUsed > maxSnapshotStorageInGB;
        if (terminate) {
            terminationCause = "Total Storage size will exceed Free Tier: " + snapshotStorageUsed + "GB > " 
            + maxSnapshotStorageInGB + "GB";
        }
    }

    // snapshot is marked for deletion
    if (terminate) {
        console.log("Snapshot " + snapshotID + " marked for deletion");

        // attempt to delete snapshot
        try {
            var terminateData = await ec2.deleteSnapshot({
                SnapshotId: snapshotID
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