import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient } from "@aws-sdk/lib-dynamodb";

export const dynamodbClient = DynamoDBDocumentClient.from(new DynamoDBClient({ region: "eu-west-1" }));
