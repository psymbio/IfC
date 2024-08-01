import * as AWS from 'aws-sdk';
import * as express from 'express';

const s3 = new AWS.S3();
const sns = new AWS.SNS();

const app = express();
const bucketName = process.env.BUCKET_NAME;
const topicArn = process.env.TOPIC_ARN;

app.get('/url', async (req, res) => {
  try {
    const params = {
      Bucket: bucketName,
      Key: 'profile.png',
      Expires: 60,
    };
    const url = await s3.getSignedUrlPromise('putObject', params);
    res.json({ url });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

app.get('/hello/:name', async (req, res) => {
  try {
    const { name } = req.params;
    res.send(`Hello ${name}`);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

// S3 event handler
exports.s3Handler = async (event) => {
  for (const record of event.Records) {
    const { key } = record.s3.object;
    const params = {
      Message: JSON.stringify({
        status: 'updated',
        name: key,
      }),
      TopicArn: topicArn,
    };
    await sns.publish(params).promise();
  }
};

// SNS subscription handler
exports.snsHandler = async (event) => {
  for (const record of event.Records) {
    const message = JSON.parse(record.Sns.Message);
    console.log(`File was written or updated: ${message.name}`);
  }
};

export default app;
