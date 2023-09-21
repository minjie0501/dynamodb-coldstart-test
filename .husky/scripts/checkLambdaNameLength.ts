import * as child_process from 'child_process';
import { load } from 'js-yaml';

const MAX_LAMBDA_NAME_LENGTH = 64

type SlsYaml = {
  functions: Record<string, { name: string }>;
}


try {
  const slsPrint = child_process.spawnSync('serverless', ['print'], { encoding: 'utf-8' });
  const slsPrintOutput = slsPrint.stdout.trim();
  const slsYaml = load(slsPrintOutput) as SlsYaml;
  const functions = slsYaml.functions;

  const functionNames: { name: string; lambdaName: string }[] = [];
  for (const [key, value] of Object.entries(functions)) {
    functionNames.push({ name: key, lambdaName: value.name });
  }

  const namesToChange: string[] = [];
  for (const functionName of functionNames) {
    if (functionName.lambdaName.length > MAX_LAMBDA_NAME_LENGTH) {
      namesToChange.push(functionName.name);
    }
  }

  if (namesToChange.length > 0) {
    console.log('\x1b[31m', 'Commit aborted!');
    console.log(
        '\x1b[33m',
        `Please change the name of the following lambda function(s) to a shorter name: ${namesToChange.join(', ')}.`,
        '\nMake sure to run `git add serverless.yml` after you\'ve made the changes.'
    );
    process.exit(1);
  }
} catch (e) {
  console.log(`Skipping lambda function name length check. ${e}`);
}
