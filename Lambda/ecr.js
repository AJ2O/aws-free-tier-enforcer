// establish ECR connection
const AWS = require("aws-sdk");
const ecr = new AWS.ECR();

// max image storage
const maxImageStorageInMB = 500;
 
// helper to get total image size
function getAggregatedImageSize(imageDetails) {
    var repositorySize = 0;
    for (let index = 0; index < imageDetails.length; index++) {
        repositorySize += (imageDetails[index].imageSizeInBytes / (1024 * 1024));
    }
    return repositorySize;
}

// main handler
exports.handler = async (event, context, callback) => {
    // get image repository and tag reference
    var repositoryName = event["repository-name"];
    var imageTag = event["image-tag"];
    var repoTag = repositoryName + ":" + imageTag;
    
    // get repository data
    try {
        var describeData = await ecr.describeRepositories().promise();
        var repositories = describeData.repositories;
    }
    catch (error) {
        console.log(error);
        return;
    }

    // run termination checks
    var terminate = false;
    var terminationCause = "";

    // check available storage
    if (!terminate) {
        var imageStorageUsed = 0;

        // get aggregate image size
        for (let index = 0; index < repositories.length && !terminate; index++) {
            var describedImages = await ecr.describeImages({
                repositoryName: repositories[index].repositoryName
            }).promise();
            imageStorageUsed += getAggregatedImageSize(describedImages.imageDetails);
            terminate = imageStorageUsed > maxImageStorageInMB;
        }

        if (terminate) {
            terminationCause = "Total Storage size will exceed Free Tier: " + imageStorageUsed + "MB > " 
            + maxImageStorageInMB + "MB";
        }
    }

    // image is marked for deletion
    if (terminate) {
        console.log("Image " + repoTag + " marked for deletion");

        // attempt to delete image
        try {
            var terminateData = await ecr.batchDeleteImage({
                repositoryName: repositoryName,
                imageIds: [{
                    imageTag: imageTag
                }]
            }).promise();
        }
        catch (error) {
            console.log(error);
            return;
        }

        // TODO: publish SNS message on completion
        console.log("Image " + repoTag + " deleted" 
        + "\nCause: " + terminationCause);
        console.log("Deletion Data \n" + JSON.stringify(terminateData));
    }
    // keep instance
    else {
        console.log("Image " + repoTag + " complies with Free-Tier")
    }
    return;
};