const requestDart = (requestName, args) => window.flutter_inappwebview.callHandler(requestName, args);

/**
 * Provider Events
 */

const disconnected = async (event) => {
  console.log(`disconnected ${JSON.stringify(event)}`);
};

const transactionsFound = async (event) => {
  console.log(`transactionsFound ${JSON.stringify(event)}`);
};

const contractStateChanged = async (event) => {
  console.log(`contractStateChanged ${JSON.stringify(event)}`);
};

const networkChanged = async (event) => {
  console.log(`networkChanged ${JSON.stringify(event)}`);
};

const permissionsChanged = async (event) => {
  console.log(`permissionsChanged ${JSON.stringify(event)}`);
};

const loggedOut = async () => {
  console.log('loggedOut');
};

/**
 * Provider Api
 */

const requestPermissions = async (req) => {
  const res = await requestDart('requestPermissions', req);
  return res;
};

const disconnect = async () => {
  await requestDart('disconnect');
};

const subscribe = async (req) => {
  const res = await requestDart('subscribe', req);
  return res;
};

const unsubscribe = async (req) => {
  await requestDart('unsubscribe', req);
};

const unsubscribeAll = async () => {
  await requestDart('unsubscribeAll');
};

const getProviderState = async () => {
  const res = await requestDart('getProviderState');
  return res;
};

const getFullContractState = async (req) => {
  const res = await requestDart('getFullContractState', req);
  return res;
};

const getTransactions = async (req) => {
  const res = await requestDart('getTransactions', req);
  return res;
};

const runLocal = async (req) => {
  const res = await requestDart('runLocal', req);
  return res;
};

const getExpectedAddress = async (req) => {
  const res = await requestDart('getExpectedAddress', req);
  return res;
};

const packIntoCell = async (req) => {
  const res = await requestDart('packIntoCell', req);
  return res;
};

const unpackFromCell = async (req) => {
  const res = await requestDart('unpackFromCell', req);
  return res;
};

const extractPublicKey = async (req) => {
  const res = await requestDart('extractPublicKey', req);
  return res;
};

const codeToTvc = async (req) => {
  const res = await requestDart('codeToTvc', req);
  return res;
};

const splitTvc = async (req) => {
  const res = await requestDart('splitTvc', req);
  return res;
};

const encodeInternalInput = async (req) => {
  const res = await requestDart('encodeInternalInput', req);
  return res;
};

const decodeInput = async (req) => {
  const res = await requestDart('decodeInput', req);
  return res;
};

const decodeEvent = async (req) => {
  const res = await requestDart('decodeEvent', req);
  return res;
};

const decodeOutput = async (req) => {
  const res = await requestDart('decodeOutput', req);
  return res;
};

const decodeTransaction = async (req) => {
  const res = await requestDart('decodeTransaction', req);
  return res;
};

const decodeTransactionEvents = async (req) => {
  const res = await requestDart('decodeTransactionEvents', req);
  return res;
};

const estimateFees = async (req) => {
  const res = await requestDart('estimateFees', req);
  return res;
};

const sendMessage = async (req) => {
  const res = await requestDart('sendMessage', req);
  return res;
};

const sendExternalMessage = async (req) => {
  const res = await requestDart('sendExternalMessage', req);
  return res;
};
