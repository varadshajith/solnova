import admin from 'firebase-admin';
import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';
import fs from 'fs';

const argv = yargs(hideBin(process.argv))
  .option('credentials', {
    alias: 'c',
    type: 'string',
    describe: 'Path to service account JSON (if not using GOOGLE_APPLICATION_CREDENTIALS env)',
  })
  .option('topic', { alias: 't', type: 'string', default: 'critical-alerts', describe: 'FCM topic' })
  .option('title', { alias: 'T', type: 'string', default: 'Test Alert', describe: 'Notification title' })
  .option('body', { alias: 'b', type: 'string', default: 'This is a test push.', describe: 'Notification body' })
  .option('data', { alias: 'd', type: 'array', describe: 'Custom data entries key=value', default: [] })
  .help()
  .argv;

async function main() {
  let credPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!credPath && argv.credentials) credPath = argv.credentials;
  if (!credPath) {
    console.error('Missing credentials. Set GOOGLE_APPLICATION_CREDENTIALS or pass --credentials path');
    process.exit(1);
  }
  const serviceAccount = JSON.parse(fs.readFileSync(credPath, 'utf8'));
  if (!admin.apps.length) {
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  }
  const data = {};
  for (const kv of argv.data) {
    const [k, ...rest] = String(kv).split('=');
    data[k] = rest.join('=');
  }
  const message = {
    topic: argv.topic,
    notification: { title: argv.title, body: argv.body },
    data,
  };
  const id = await admin.messaging().send(message);
  console.log('Sent message ID:', id);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
