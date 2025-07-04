const {
  S3Client,
  PutObjectCommand,
  ListObjectsV2Command,
  DeleteObjectsCommand,
} = require("@aws-sdk/client-s3");
const axios = require("axios");
const moment = require("moment");

const s3Client = new S3Client({});
const BUCKET_NAME = process.env.BUCKET_NAME;
// test sts to check github cicd workflow

// New function to clear the directory
const clearRawDataDirectory = async () => {
  console.log(`Clearing raw/ directory in bucket ${BUCKET_NAME}...`);

  const listParams = {
    Bucket: BUCKET_NAME,
    Prefix: "raw/",
  };

  const listedObjects = await s3Client.send(
    new ListObjectsV2Command(listParams)
  );

  if (!listedObjects.Contents || listedObjects.Contents.length === 0) {
    console.log("Directory is already empty. Nothing to delete.");
    return;
  }

  const deleteParams = {
    Bucket: BUCKET_NAME,
    Delete: {
      Objects: listedObjects.Contents.map(({ Key }) => ({ Key })),
    },
  };

  const deleteResult = await s3Client.send(
    new DeleteObjectsCommand(deleteParams)
  );
  console.log(`Successfully deleted ${deleteResult.Deleted.length} objects.`);
};

exports.handler = async (event, context) => {
  console.log("Fetcher started. Event:", JSON.stringify(event, null, 2));

  const url =
    "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson";

  try {
    // Step 1: Clear the directory
    await clearRawDataDirectory();

    // Step 2: Fetch new data
    const { data } = await axios.get(url, { responseType: "text" });
    console.log(`Successfully fetched data from ${url}`);

    // Step 3: Save the new file
    const timestamp = moment().format("YYYY-MM-DD-HH-mm-ss");
    const key = `raw/earthquakes-${timestamp}.json`;

    const putObjectParams = {
      Bucket: BUCKET_NAME,
      Key: key,
      Body: data,
      ContentType: "application/json",
    };

    await s3Client.send(new PutObjectCommand(putObjectParams));
    console.log(
      `Successfully uploaded raw data to S3: s3://${BUCKET_NAME}/${key}`
    );

    return {
      statusCode: 200,
      body: JSON.stringify({
        message:
          "Data directory cleared, new data fetched and stored successfully!",
        s3_key: key,
      }),
    };
  } catch (error) {
    console.error("Error in fetcher lambda:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: "Failed to fetch or store data.",
        error: error.message,
      }),
    };
  }
};
