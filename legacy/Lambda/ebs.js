// establish EBS connection (EC2 service)
const AWS = require("aws-sdk");
const ec2 = new AWS.EC2();

// check volume type
const freeTierVolumeTypes = [
    "gp2",
    "gp3",
    "standard"
];
function isFreeTierVolumeType(volumeData) {
    return freeTierVolumeTypes.indexOf(volumeData.VolumeType) > -1;
}

// max volume size
const maxVolumeSizeInGB = 30;

// main handler
exports.handler = async (event, context, callback) => {
    // get volume ID reference
    var volumeID = event["volumeId"];
    var volumeSize = parseInt(event["size"]);
    var params = {
        VolumeIds: [
            volumeID
        ]
    };
    
    // get volume data
    try {
        var describeData = await ec2.describeVolumes(params).promise();
        var volumeData = describeData.Volumes[0];
    }
    catch (error) {
        console.log(error);
        return;
    }

    // don't try to delete if already being deleted
    if (volumeData.State == "deleting" || volumeData.State == "deleted") {
        console.log("Volume " + volumeID + " is already being deleted");
        return;
    }

    // try to detach volume if attached
    if (volumeData.Attachments.length > 0) {
        // TODO: handle root device cases
        var attachedInstanceID = volumeData.Attachments[0].InstanceId;
        try {
            var detachData = await ec2.detachVolume({
                VolumeId: volumeID
            }).promise();
        }
        catch (error) {
            console.log(error);
            return;
        }
    }

    // run termination checks
    var terminate = false;
    var terminationCause = "";

    if (!terminate && !isFreeTierVolumeType(volumeData)){
        terminate = true;
        terminationCause = "Non-compliant volume type: " + volumeData.VolumeType;
    }

    // check available storage
    if (!terminate) {
        var volumeSizeUsed = volumeSize;

        var volumes = await ec2.describeVolumes().promise();
        for (let index = 0; index < volumes.length; index++) {
            volumeSizeUsed += volumes[index].Size;
        }

        terminate = volumeSizeUsed > maxVolumeSizeInGB;
        if (terminate) {
            terminationCause = "Total Storage size will exceed Free Tier: " + volumeSizeUsed + "GB > " 
            + maxVolumeSizeInGB + "GB";
        }
    }

    // volume is marked for deletion
    if (terminate) {
        console.log("Volume " + volumeID + " marked for deletion");

        // attempt to delete volume
        try {
            var terminateData = await ec2.deleteVolume({
                VolumeId: volumeID
            }).promise();
        }
        catch (error) {
            console.log(error);
            return;
        }

        // TODO: publish SNS message on completion
        console.log("Volume " + volumeID + " deleted" 
        + "\nCause: " + terminationCause);
        console.log("Deletion Data \n" + JSON.stringify(terminateData));
    }
    // keep instance
    else {
        console.log("Volume " + volumeID + " complies with Free-Tier")
    }
    return;
};