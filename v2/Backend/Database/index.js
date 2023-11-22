// Import The Modules
const fs = require('fs');
const http = require('http');
const url = require('url');
const whois = require('node-whois');
const path = require('path');
const fsp = require("fs/promises");

// Acquire the scripts/json files
const gradient = require('./Utils/gradient.js');
require('dotenv').config();

// Path variables
const dbPATH = './Utils/db.json';
const backupsPATH = './Backups';
const moment = require('moment');
const deleteBackupTime = 2 * 24 * 60 * 60 * 1000; // 2 days in milliseconds

// Check if the db is being updated or not
let UpdatingDB = false;

const RATE_LIMIT = parseInt(process.env['RATE_LIMIT']);
const consoleChannelId = process.env['CONSOLECHANNELID']

// Tracks User Requests
const userRequestCounts = {};

// Function to reset user request counts every minute
setInterval(() => {
  for (const userId in userRequestCounts) {
    userRequestCounts[userId] = undefined;
  }
}, 60000); // Reset every minute

// Important hashes

const SuccessHash = "0UQAXPTVHO"
const InvalidHash = "XP9776KLE2"
const FailureHash = "V7PCL9OCCW"

// Function to delete old backups

function deleteOldFiles() {
  fsp.readdir(backupsPATH)
    .then((files) => {
      const currentDate = Date.now();

      files.forEach((file) => {
        const filePath = path.join(backupsPATH, file);

        fsp.stat(filePath)
          .then((stats) => {
            const fileAge = currentDate - stats.mtime.getTime();

            if (fileAge > deleteBackupTime) {
              fsp.unlink(filePath)
                .then(() => {
                  log(`Deleted DB Backup: ${filePath} (Age: ${fileAge} ms)`, 'green');
                })
                .catch((err) => {
                  log(`Failed To Delete DB Backup${filePath}!`, 'red');
                });
            }
          })
          .catch((err) => {
            log(`Error Getting Backup File Info!`, 'red')
          });
      });
    })
    .catch((err) => {
      log(`Error Getting Backups Folder!`, 'red')
    });
}

setInterval(() => {
  deleteOldFiles();
}, (deleteBackupTime));

// Function To Wait till its done updating the database file

function updatingDBwait() {
  return new Promise((resolve) => {
    const checkInterval = 1000;
    const checkFunction = () => {
      if (!UpdatingDB) {
        clearInterval(intervalId);
        resolve();
      }
    };

    const intervalId = setInterval(checkFunction, checkInterval);
    checkFunction(); // Check immediately
  });
}

// Function To Get UserId From PCData

function processPCDataDirectory(directory) {
  // Split the directory string at "_" and keep only the first part
  const parts = directory.split('_');
  if (parts.length > 1) {
    return parts[0];
  }
  // If there is no "_" in the directory, return the original directory
  return undefined;
}

// Function To Get UserId From Codes

async function processCodesDirectory(directory) {
  // Split the directory string at "_" and keep only the first part
  const parts = directory.split('_');
  if (parts.length > 1) {
    return parts[1];
  }
  // If there is no "_" in the directory, return the original directory
  return undefined;
}

// Function To Get IPv4

function extractIPv4FromIPv6MappedAddress(ipv6MappedIPv4) {
  // Check if the provided address is in the IPv6-mapped IPv4 format
  if (ipv6MappedIPv4.startsWith('::ffff:')) {
    return ipv6MappedIPv4.slice(7); // Remove '::ffff:' prefix to get the IPv4 part
  }
  return ipv6MappedIPv4; // Return the original address if it's not in the mapped format
}

// Function To Validate IP Address
function isValidIP(ip) {
  // Regular expressions for IPv4
  const ipv4Regex = /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;
  
  return ipv4Regex.test(ip)
}

// Function To Lookup an IP Address

async function lookup(IP, timeout = 5000) {
  return new Promise((resolve, reject) => {
    const timeoutId = setTimeout(() => {
      reject(new Error(`WHOIS lookup for ${IP} timed out`));
    }, timeout);

    whois.lookup(IP, (_err, data) => {
      clearTimeout(timeoutId); // Clear the timeout since the request completed

      try {
        if (typeof data === 'string' & isValidIP(IP)) {
          const orgNameRegex = /OrgName:\s+(.*)/;
          const netNameRegex = /NetName:\s+(.*)/;
          
          const orgNameMatch = data.match(orgNameRegex);
          const netNameMatch = data.match(netNameRegex);
          
          if (orgNameMatch && netNameMatch) {
            const orgName = orgNameMatch[1];
            const netName = netNameMatch[1];
            resolve({ orgName, netName });
          } else {
            resolve({ orgName: null, netName: null });
          }
        } else {
          // Handle unexpected WHOIS response format
          reject(new Error(`Unexpected WHOIS response format for ${IP}`));
        }
      } catch (e) {
        reject(e);
      }
    });
  });
}

async function checkIp(ip, organisation){
  const dataF = await lookup(ip)
  if (dataF.orgName === null || dataF.netName === null){ return FailureHash }
  if (dataF.orgName === organisation && dataF.netName === organisation){
    return true;
  }
  return false;
}

async function getNetName(ip){
  const dataF = await lookup(ip)
  if (dataF.orgName === null || dataF.netName === null){ return FailureHash }
  return dataF.netName;
}

// Function to load the latest db.json file

function loadDB() {
  try {
    const rawData = fs.readFileSync(dbPATH);
    return JSON.parse(rawData);
  } catch (error) {
    console.error('Error loading db.json:', error);
    return {};
  }
}

// Function to check if a file/folder exists

function checkFileExists(filePath) {
  return fs.existsSync(filePath, fs.constants.F_OK);
}

// Create the db.json if it does not exist
if (!checkFileExists(dbPATH)) {
  const newFile = fs.createWriteStream(dbPATH);
  let dbTemplate = '{\n  "Codes": {},\n  "Doc": {},\n  "EloMeta_BattleEloV5": {},\n  "PCData": {},\n  "PVPHourBattleHistoryV3": {},\n  "PlayerDataV1": {}\n}\n';
  newFile.write(dbTemplate);
}

// Create the Backups folder if it does not exist
if (!checkFileExists(backupsPATH)) {
  fs.mkdirSync(backupsPATH);
}

// Valid Paths
const validPaths = ['Codes', 'Doc', 'EloMeta_BattleEloV5', 'PCData', 'PVPHourBattleHistoryV3', 'PlayerDataV1']

// Function to check if given path is valid
function isValidPath(path) {
  for (const Tpath in validPaths) {
    if (validPaths[Tpath] == path) return true;
  }
  return false;
}

// Function to check if directory is valid
function isDirectoryValid(path, directory) {
  const key = path[directory]
  if (key === "" || key === null || key == undefined) { return false; }
  return true;
}

// Function to validate JSON
function isValidJson(data) {
  try {
    JSON.parse(data);
    return true;
  } catch (error) {
    return false;
  }
}

// Function to update the db.json file
function updateJson(json) {
  try {
    fs.writeFileSync('./Utils/db.json', JSON.stringify(json, null, 2), 'utf-8');
    return SuccessHash;
  }
  catch (e) {
    return FailureHash;
  }
}

// Set directory function
function setDirectory(path, directory, value) {
  // Validate the path
  if (!isValidPath(path)) { return InvalidHash; }

  // Load the latest DB json file
  const currentDB = loadDB();

  // Check if directory is to be deleted
  if (value === null || value === undefined || value === "" || value === " ") { value = undefined }
  try {

    // Update the directory
    currentDB[path][directory] = value
    return updateJson(currentDB)
  }
  catch (e) {
    return FailureHash;
  }
}

// Get directory function
function getDirectory(path, directory) {
  // Validate the path
  if (!isValidPath(path)) { return FailureHash; }

  // Load The Latest DB Json File
  const currentDB = loadDB();

  // Validate the directory
  if (!isDirectoryValid(currentDB[path], directory)) { return FailureHash; }
  try {

    // Get the value & return it
    const value = currentDB[path][directory]
    return value
  }
  catch (e) {
    return FailureHash;
  }
}

// Function to backup the db
function backupDB() {
  const currentDate = moment().format('DD-MM-YYYY - h.mm.ss a');
  const backupFileName = `${backupsPATH}/DB Backup - ${currentDate}.json`;

  try {
    if (!fs.existsSync(backupsPATH)) {
      fs.mkdirSync(backupsPATH, { recursive: true });
    }

    const currentData = JSON.stringify(loadDB(), null, 2)
    fs.writeFileSync(backupFileName, currentData, 'utf-8');
    log(`DB backup saved as ${backupFileName}`, 'lime');
  }
  catch (error) {
    log(`Failed to create DB backup!`, 'red')
  }
}

function testDB() {
  const response = setDirectory("Codes", "lmao2", true);
  switch (response) {
    case 0:
      log("Invalid Path/Directory!", 'red');
      break;
    case 1:
      log("Modified Directory Successfully!", 'green');
      break;
    case -1:
      log("Failed To Modify Directory")
      break;
  }
  const response2 = getDirectory("Codes", "lmao2");
  switch (response2) {
    case 0:
      log("Invalid Path/Directory!", 'red');
      break;
    case -1:
      log("Failed To Modify Directory")
      break;
    default:
      log(`Obtained Directory Successfully!\nDirectory Name: lmao2\nDirectory Value: ${response2}`, 'purple')
      break;
  }
}

//testDB()

// Backup the database every hour
setInterval(backupDB, 3600000);

// Create http server
const server = http.createServer(async (req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const IP = await extractIPv4FromIPv6MappedAddress(req.socket.remoteAddress)

  if(UpdatingDB){
    await updatingDBwait()
  }

  if (req.method === 'GET' && parsedUrl.pathname === '/GetDirectory') {
    
    // Get the token
    const token = parsedUrl.query.token;

    // Declare the path and directory
    const path = parsedUrl.query.path;
    const directory = parsedUrl.query.directory;
    let userId=undefined

    switch (path){
      case "PCData":
        userId = await processPCDataDirectory(directory);
        break;
      case "PlayerDataV1":
        userId = directory;
        break;
      case "Codes":
        userId = await processCodesDirectory(directory)
        break;  
    }

    if (userId && userRequestCounts[userId] && userRequestCounts[userId] >= RATE_LIMIT) {
      // User has exceeded the rate limit, return an error response
      res.statusCode = 429; // Too Many Requests
      res.end('Rate limit exceeded');
      return;
    }

    try {
      // Validate The Token
      if (isValidToken(token)) {

        // Get the value of the directory
        let value = getDirectory(path, directory);

        // Return empty directory if the directory doesnot exist
        if (value === FailureHash || value === InvalidHash || value === null || value === undefined) {
          value = undefined;
        }

        if (userId) {
          if (!userRequestCounts[userId]) {
            userRequestCounts[userId] = 1;
          } 
          else {
            userRequestCounts[userId]++;
          }
        }

        log(`Get Request For Path: ${path}, Directory: ${directory}, processed value: ${value}, result: Request Processed successfully!`, 'green')
        const responseJson = value;
        res.setHeader('Content-Type', 'text/plain');
        res.statusCode = 200;
        res.end(JSON.stringify(responseJson));
      }
      else {
        res.statusCode = 401;
        res.end('Access Denied');
      }
    }
    catch (e) {
      res.statusCode = 505;
      const responseJson = { message: "Internal Server Error" };
      res.end(JSON.stringify(responseJson));
      log(`Get Request For Path: ${path}, Directory: ${directory}, result: Request Failed!`, 'red')
    }
  }
  else if (req.method === 'GET' && parsedUrl.pathname === '/SetDirectory') {
    try {
      // Get the token
      const token = parsedUrl.query.token;

      // Declare the path and directory
      const path = parsedUrl.query.path;
      const directory = parsedUrl.query.directory;
      let value = parsedUrl.query.value;

      let userId=undefined

      switch (path){
        case "PCData":
          userId = await processPCDataDirectory(directory);
          break;
        case "PlayerDataV1":
          userId = directory;
          break;
        case "Codes":
          userId = await processCodesDirectory(directory)
          break;  
      }
  
      if (userId && userRequestCounts[userId] && userRequestCounts[userId] >= RATE_LIMIT) {
        // User has exceeded the rate limit, return an error response
        res.statusCode = 429; // Too Many Requests
        res.end('Rate limit exceeded');
        return;
      }

      // Validate The Token
      if (isValidToken(token)) {

        try {
          // Check if it's a valid JSON, if not, treat it as a string
          if (isValidJson(value)) {
            value = JSON.parse(value);
          }
          setDirectory(path, directory, value)

          if (userId) {
            if (!userRequestCounts[userId]) {
              userRequestCounts[userId] = 1;
            } 
            else {
              userRequestCounts[userId]++;
            }
          }

          log(`Set Request For Path: ${path}, Directory: ${directory}, value: ${value}, result: Request Processed successfully!`, 'green')
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ message: 'Data received & saved successfully' }));
        }
        catch (e) {
          log(`Set Request For Path: ${path}, Directory: ${directory}, result: Request Failed, Invalid Data Received!`, 'red')
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ message: 'Invalid data' }));
        }

      }
      else {
        log(`Set Request For Path: ${path}, Directory: ${directory}, result: Unauthorized`, 'red')
        res.statusCode = 401;
        res.end('Access Denied');
      }
    }
    catch (error) {
      // Handle JSON parsing or other errors
      console.error('Error:', error);
      res.writeHead(400, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Invalid data' }));
    }
  }
  else {
    res.statusCode = 202;
    res.write("I'm alive");
    res.end();
  }
});

// Function to validate token

function isValidToken(token) {
  return token === process.env['TOKEN'];
}

// Listen On Port
const PORT = parseInt(process.env.PORT) || 3000;
server.listen(PORT, () => {
  log(`Server is running on port ${PORT}`, 'green');
});


// Discord Bot Code

const { Client, IntentsBitField, ActivityType} = require('discord.js');
const { SlashCommandBuilder } = require('@discordjs/builders');
const { REST } = require('@discordjs/rest');
const { Routes } = require('discord-api-types/v9');
const { send } = require('process');

const botToken = process.env['BOTTOKEN'];
const guildId = process.env['GUILDID'];
const clientId = process.env['CLIENTID'];

const commandsData = JSON.parse(fs.readFileSync('./Utils/commands.json', 'utf8'));

const commands = commandsData.map(commandData => {
  const builder = new SlashCommandBuilder()
    .setName(commandData.name)
    .setDescription(commandData.description);

  if (commandData.options) {
    commandData.options.forEach(option => {
      const { type, name, description, required } = option;

      switch (type) {
        case 'string':
          builder.addStringOption(opt =>
            opt.setName(name).setDescription(description).setRequired(required)
          );
          break;
        case 'integer':
          builder.addIntegerOption(opt =>
            opt.setName(name).setDescription(description).setRequired(required)
          );
          break;
        case 'attachment':
          builder.addAttachmentOption(opt =>
            opt.setName(name).setDescription(description).setRequired(required)
          );
          break;
        case 'boolean':
          builder.addBooleanOption(opt =>
            opt.setName(name).setDescription(description).setRequired(required)
          );
          break;
      }
    });
  }

  return builder.toJSON();
});

// Set the bot token in REST
const rest = new REST({ version: '9' }).setToken(botToken);

// Refresh Slash Commands

(async () => {
  try {
    log('Started refreshing application (/) commands.', 'green');
    await rest.put(
      Routes.applicationGuildCommands(clientId, guildId),
      { body: commands },
    );
    log('Successfully reloaded application (/) commands.', 'green');
  } catch (error) {
    log(`Failed to refresh/reload application (/) commands.`, 'red')
  }
})();

// Initialize bot

const client = new Client({ intents: [IntentsBitField.Flags.Guilds, IntentsBitField.Flags.GuildMembers] });

// Login to discord bot

client.on('ready', () => {
  log(`Logged in as ${client.user.tag}!`, 'green');
  client.user.setPresence({
    activities: [{
      name: "/help",
      type: ActivityType.Playing,
    }],
    status: 'dnd'
  });
});

// Function to create the temp folder if it does not exist

if (!fs.existsSync("./Temp")) {
  fs.mkdirSync("./Temp");
}

// Function to load the admin list

async function loadAdminList(){
  try {
    const rawData = fs.readFileSync('./admins.json');
    return JSON.parse(rawData);
  } 
  catch (error) {
    console.error('Error loading botconfig.json:', error);
    return [];
  }
}

// Function to check if a user is an admin

async function checkAdmin(userId){
  const adminList = await loadAdminList();
  for (const adminKey in adminList){
    if (adminList[adminKey] === userId) return true;
  }
  return false;
}

// Function to get file extension

async function getFileExtension(fileUrl) {
  const parsedPath = path.parse(fileUrl);
  return parsedPath.ext.slice(1);
}

// Color Map

const colorMap = {
  red: 0xFF0000,
  blue: 0x0000FF,
  green: 0x21ff37,
  yellow: 0xfcba03,
  white: 0xffffff,
  black: 0x1c1c1c,
  purple: 0x6038ff,
  cyan: 0x00fbff,
  orange: 0xFF9F00
};

// Interact with slash commands

client.on('interactionCreate', async (interaction) => {
  if (!interaction.isCommand()) return;

  const { commandName, options } = interaction;
  await interaction.deferReply();

  let DiscordUserId = interaction.user.id;

  function sendEmbed(message, colorName){
    const color = colorMap[colorName] || colorMap.white
    const embed = {
        type: "rich",
        title: "Custom DB Manager",
        description: message,
        color: color,
        image: {
          url: "https://cdn.discordapp.com/attachments/1147019639172382740/1152829077275807805/standard_11.gif",
        }
    }
    interaction.editReply({ embeds: [embed] })
  }

  if (!await checkAdmin(DiscordUserId)){ sendEmbed('You are not authorized to use this bot!', 'red') }

  sendEmbed("Processing Request!", 'yellow')

  try{
    if (commandName === 'latency') {
      const ping = Date.now() - interaction.createdTimestamp;
      sendEmbed("DB Latency:\n```"+ping+" ms```", 'white')
    }
    else if(commandName === 'get-db'){
      await (await client.users.fetch(DiscordUserId)).send({ content: "Here Is The DB Json File!", files: [`./Utils/db.json`] })
      sendEmbed("I Have DMed You The Current DB Json File!", 'green')
    }
    else if(commandName === "get-playerdata" || commandName === "get-pc-data"){
      const path = (commandName === "get-playerdata") ? "PlayerDataV1" : "PCData";
      const directory = options.getString('directory');

      const value = getDirectory(path, directory)

      sendEmbed("Here Is Your Requested Data!\n```json\n"+directory+': "'+`${value}`+'"\n```', 'white');
    }
    else if(commandName === "set-playerdata" || commandName === "set-pc-data"){
      const path = (commandName === "set-playerdata") ? "PlayerDataV1" : "PCData";
      const directory = options.getString('directory');
      const value = options.getString('value');

      const response = setDirectory(path, directory, value)
      switch (response){
        case FailureHash:
          sendEmbed(`Failed To Set value for directory ${directory}`)
          break;
        case SuccessHash:
          sendEmbed(`Modified Directory(${directory}) with provided value successfully!`)
          break;
      }
    }
    else if(commandName === "set-db"){
      const attachment = options.getAttachment('db');
      const filePath = `./Temp/TempDB.json`;
      const fileURL = attachment.url;
      const extension = await getFileExtension(fileURL);
      if (extension!="json") { sendEmbed("Please Upload a valid file extension(`.json`)!", 'red'); return; }

      const response = await axios.get(fileURL, { responseType: 'arraybuffer' });
      const FileBuffer = Buffer.from(response.data);
      fs.writeFileSync(filePath, FileBuffer);
      sendEmbed("Downloaded the new `db.json` file!", 'purple')

      UpdatingDB = true;
      var dbFile = fs.readFileSync(filePath);
      fs.writeFileSync(`./Utils/db.json`, dbFile);
      fs.unlinkSync(filePath);
      sendEmbed("Downloaded & Setup the new `db.json` file successfully!", 'green')
    }
    else if(commandName === "help"){
      sendEmbed(`**HELP**\n- **/latency**\nHelps get the latency of the db!\n- **/get-db**\nDM's you the latest db.json file\n- **/set-db**\nLets you upload the db file!\n- **/get-playerdata & /set-playerdata**\nHelps you read & write playerdata respectively!\n- **/get-pc-data & /set-pc-data**\nHelps you read & write PCData respectively!`, 'black')
    }
  }
  catch(e){
    console.log(e)
    sendEmbed('Request Failed', 'red')
  }
  UpdatingDB = false;
});

// Gradient logging function

async function log(message, colorName) {
  gradient.log(message, colorName);
  try{ await client.channels.cache.get(consoleChannelId).send(message) } catch(e) {}
}

// Call the login function

client.login(botToken);