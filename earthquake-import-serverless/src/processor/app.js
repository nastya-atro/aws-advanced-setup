const { S3Client, GetObjectCommand } = require("@aws-sdk/client-s3");
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  BatchWriteCommand,
  ScanCommand,
} = require("@aws-sdk/lib-dynamodb");
const CovJSONReader = require("covjson-reader");
const turf = require("@turf/turf");
const moment = require("moment");
const axios = require("axios");

const s3Client = new S3Client({});
const dynamoDbClient = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(dynamoDbClient);

const TABLE_NAME = process.env.TABLE_NAME;

const streamToString = (stream) =>
  new Promise((resolve, reject) => {
    const chunks = [];
    stream.on("data", (chunk) => chunks.push(chunk));
    stream.on("error", reject);
    stream.on("end", () => resolve(Buffer.concat(chunks).toString("utf-8")));
  });

const definePolygonForCovJson = (data) => {
  const { domain } = data._covjson;
  const xStart = domain.axes.x.start;
  const xStop = domain.axes.x.stop;
  const yStart = domain.axes.y.start;
  const yStop = domain.axes.y.stop;

  const bbox = [xStart, yStart, xStop, yStop];

  return {
    polygon: turf.bboxPolygon(bbox).geometry,
    x_axis: domain.axes.x,
    y_axis: domain.axes.y,
  };
};

const processGeoJSON = async (data) => {
  const toSecUnixTimestamp = (timestamp) => Math.floor(timestamp / 1000);
  const toUnixTimestamp = (dateString, format) =>
    moment(dateString, format).unix();
  const dateFormat = "YYYY-MM-DDTHH:mm:ss.SSSZ";
  const received_at = Math.floor(new Date().getTime() / 1000);

  const processDetails = async (shakemapData) =>
    await Promise.all(
      shakemapData?.map(async (el) => {
        const coverage_mmi_high_url =
          el.contents["download/coverage_mmi_high_res.covjson"]?.url;
        if (!coverage_mmi_high_url) return null;

        const { data: coverage_mmi_high_result } = await axios.get(
          coverage_mmi_high_url
        );
        if (!coverage_mmi_high_result) return null;

        const coverage_mmi_high_parsed = await CovJSONReader.read(
          coverage_mmi_high_result
        );
        const polygonData = definePolygonForCovJson(coverage_mmi_high_parsed);

        return {
          id: el.id,
          start: toUnixTimestamp(el.properties.eventtime, dateFormat),
          update_time: toSecUnixTimestamp(el.updateTime),
          ...polygonData,
        };
      })
    );

  const features = data?.features
    .filter(
      (feature) =>
        feature?.properties?.types?.includes("shakemap") &&
        feature?.properties?.mmi
    )
    .map(async (feature) => {
      const detailsUrl = feature.properties.detail;
      const { data: data_details } = await axios.get(detailsUrl);
      const shakemapData = data_details?.properties?.products?.shakemap || null;
      const shakemapDetails = shakemapData
        ? await processDetails(shakemapData)
        : null;

      if (
        !shakemapDetails ||
        shakemapDetails.every((detail) => detail === null)
      )
        return null;

      return shakemapDetails
        .filter((shakemapDetail) => shakemapDetail !== null)
        .map((shakemapDetail) => ({
          ...shakemapDetail,
          // A more robust unique ID should be created, e.g., combining feature_id and shakemap_id
          id: `${feature.id}-${shakemapDetail.id}`,
          feature_id: feature.id,
          received_at,
          source: "USGS Earthquake Hazards Program",
          data_type: "Earthquake MMI Shakemaps",
          country: "NULL",
          state: "NULL",
          place: feature.properties.place,
          title: feature.properties.title,
          net: feature.properties.net,
          issue_time: toSecUnixTimestamp(feature.properties.time),
          update_time:
            shakemapDetail.update_time ||
            toSecUnixTimestamp(
              feature.properties.updated || feature.properties.time
            ),
          mag: feature.properties.mag,
          mmi: feature.properties.mmi,
          cdi: feature.properties.cdi,
          rms: feature.properties.rms,
          gap: feature.properties.gap,
          point: feature.geometry,
        }));
    });

  const result = await Promise.all(features);
  return result.flat().filter((item) => item !== null);
};

// New function to clear the entire DynamoDB table
const clearDynamoDBTable = async () => {
  console.log(`Clearing all items from table ${TABLE_NAME}...`);
  let lastEvaluatedKey = null;
  let totalDeletedCount = 0;

  do {
    const scanParams = {
      TableName: TABLE_NAME,
      ProjectionExpression: "id", // Only fetch the primary key
    };

    if (lastEvaluatedKey) {
      scanParams.ExclusiveStartKey = lastEvaluatedKey;
    }

    const scanResult = await docClient.send(new ScanCommand(scanParams));

    if (scanResult.Items && scanResult.Items.length > 0) {
      const deleteRequests = scanResult.Items.map((item) => ({
        DeleteRequest: {
          Key: { id: item.id },
        },
      }));

      // Batch delete in chunks of 25
      for (let i = 0; i < deleteRequests.length; i += 25) {
        const chunk = deleteRequests.slice(i, i + 25);
        const batchWriteParams = {
          RequestItems: {
            [TABLE_NAME]: chunk,
          },
        };
        await docClient.send(new BatchWriteCommand(batchWriteParams));
        totalDeletedCount += chunk.length;
        console.log(`Deleted a chunk of ${chunk.length} items.`);
      }
    }

    lastEvaluatedKey = scanResult.LastEvaluatedKey;
  } while (lastEvaluatedKey);

  console.log(
    `Finished clearing table. Total items deleted: ${totalDeletedCount}`
  );
};

const batchWriteToDynamoDB = async (items) => {
  const writeRequests = items.map((item) => ({
    PutRequest: {
      Item: item,
    },
  }));

  // DynamoDB BatchWriteItem has a limit of 25 items per request
  for (let i = 0; i < writeRequests.length; i += 25) {
    const chunk = writeRequests.slice(i, i + 25);
    const command = new BatchWriteCommand({
      RequestItems: {
        [TABLE_NAME]: chunk,
      },
    });
    await docClient.send(command);
    console.log(`Wrote chunk of ${chunk.length} items to DynamoDB.`);
  }
};

exports.handler = async (event) => {
  console.log("Processor started. Event:", JSON.stringify(event, null, 2));

  try {
    // Extract the S3 event from the SNS message
    const snsMessage = event.Records[0].Sns.Message;
    const s3Event = JSON.parse(snsMessage);
    const s3Record = s3Event.Records[0].s3;

    const bucket = s3Record.bucket.name;
    const key = decodeURIComponent(s3Record.object.key.replace(/\+/g, " ")); // Handle spaces in filenames

    const getObjectParams = { Bucket: bucket, Key: key };
    const { Body } = await s3Client.send(new GetObjectCommand(getObjectParams));
    const rawDataString = await streamToString(Body);
    console.log("rawDataString:", rawDataString.slice(0, 100) + "...");

    const rawDataJson = JSON.parse(rawDataString);

    console.log(`Successfully read and parsed data from s3://${bucket}/${key}`);

    // Step 1: Clear the entire table
    await clearDynamoDBTable();

    // Step 2: Process the new data
    const documents = await processGeoJSON(rawDataJson);
    if (!documents || documents.length === 0) {
      console.log("No processable earthquake documents found.");
      return { statusCode: 200, body: "No processable documents found." };
    }

    console.log(
      `Processed ${documents.length} documents. Preparing to write to DynamoDB.`
    );
    // Step 3: Write the new documents
    await batchWriteToDynamoDB(documents);

    console.log("Successfully processed and stored all documents.");
    return { statusCode: 200, body: "Data processed and stored successfully!" };
  } catch (error) {
    console.error("Error in processor lambda:", error);
    // Add more detailed error handling/notification
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: "Failed to process data.",
        error: error.message,
      }),
    };
  }
};
