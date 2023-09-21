import middy from "@middy/core";
import httpErrorHandler from "@middy/http-error-handler";
import { APIGatewayProxyEvent, Context } from "aws-lambda";

import { successResponse } from "utils/response.utils";

import { User } from "dynamodb/entities/userEntity";

export const lambdaHandler = async (_event: APIGatewayProxyEvent, _context: Context) => {
  const now = new Date().getTime().toString();
  const { data: user } = await User.create({
    userId: now,
    email: `${now}@test.com`,
  }).go();

  return successResponse({ code: 200, body: { user } });
};

export const handler = middy(lambdaHandler).use([httpErrorHandler()]);
