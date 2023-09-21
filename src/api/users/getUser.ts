import middy from "@middy/core";
import httpErrorHandler from "@middy/http-error-handler";
import { APIGatewayProxyEvent, Context } from "aws-lambda";

import { getPathParam } from "utils/api.utils";
import { successResponse } from "utils/response.utils";

import { cors } from "middlewares/corsMiddleware";

import { User } from "dynamodb/entities/userEntity";

export const lambdaHandler = async (event: APIGatewayProxyEvent, _: Context) => {
  const userId = getPathParam(event, "userId") || "";
  const user = await User.query.user({ userId }).go();
  console.log("aaa");
  return successResponse({ code: 200, body: { user } });
};

export const handler = middy(lambdaHandler).use([cors(), httpErrorHandler()]);
