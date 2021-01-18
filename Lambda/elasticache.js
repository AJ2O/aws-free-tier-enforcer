// establish ElastiCache connection
const AWS = require("aws-sdk");
const elasticache = new AWS.ElastiCache();

// check cache node types
const freeTierCacheNodeTypes = [
    "cache.t2.micro",
    "cache.t3.micro"
];
function isFreeTierNodeType(cacheClusterData) {
    return freeTierCacheNodeTypes.indexOf(cacheClusterData.CacheNodeType) > -1;
}

// check cache cluster hours
function areFreeTierHoursLeft(cacheClusterData) {
    // TODO: calculate used and remaining free-tier hours left
    return true;
}

// main handler
exports.handler = async (event, context, callback) => {
    // get cache cluster reference
    var cacheClusterId = event["cacheClusterId"];
    var params = {
        CacheClusterId: cacheClusterId
    };

    // run termination checks
    var terminate = false;
    var terminationCause = "";

    // get cluster data
    try {
        var describeData = await elasticache.describeCacheClusters(params).promise();
        var cacheClusterData = describeData.CacheClusters[0];
    }
    catch (error) {
        console.log(error);
        return;
    }

    // check cache node type
    if (!terminate){
        terminate = !isFreeTierNodeType(cacheClusterData);

        if (terminate) {
            terminationCause = "Non-compliant cache cluster type: " + cacheClusterData.CacheNodeType;
        }
    }

    if (!terminate && !areFreeTierHoursLeft(cacheClusterData)) {
        terminate = true;
        terminationCause = "No more ElastiCache Free-Tier hours for the rest of the month"
    }

    // cache cluster is marked for termination
    if (terminate) {
        console.log("Instance " + cacheClusterId + " marked for termination");

        // attempt to delete cache cluster
        try {
            var terminateData = await elasticache.deleteCacheCluster(params).promise();
        }
        catch (error) {
            console.log(error);
            return;
        }

        // TODO: publish SNS message on completion
        console.log("Cache cluster " + cacheClusterId + " terminated" 
        + "\nCause: " + terminationCause);
        console.log("Termination Data \n" + JSON.stringify(terminateData));
    }
    // keep cache cluster
    else {
        console.log("Cache cluster " + cacheClusterId + " complies with Free-Tier")
    }
    return;
};