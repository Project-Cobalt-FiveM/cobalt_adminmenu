import { installMock, type MockHandlers } from './nui';
import type { Action, Bootstrap, ChatMessage, NuiMessage, PlayerDetail, PlayerRow, Rank, Report, Resource, WorldState } from './types';

const rankLevels: Record<Rank, number> = { staff: 1, admin: 2, owner: 3 };
const requestedRank = new URLSearchParams(window.location.search).get('rank');
const viewerRank: Rank = requestedRank === 'staff' || requestedRank === 'owner' ? requestedRank : 'admin';

const definitions: Omit<Action, 'allowed'>[] = [
  { name: 'noclip', label: 'Noclip', scope: 'self', rank: 'staff', side: 'client', toggle: true },
  { name: 'godmode', label: 'God mode', scope: 'self', rank: 'admin', side: 'client', toggle: true },
  { name: 'invisible', label: 'Invisible', scope: 'self', rank: 'staff', side: 'client', toggle: true },
  { name: 'names', label: 'Player names', scope: 'self', rank: 'staff', side: 'client', toggle: true },
  { name: 'blips', label: 'Player blips', scope: 'self', rank: 'staff', side: 'client', toggle: true },
  { name: 'infiniteAmmo', label: 'Infinite ammo', scope: 'self', rank: 'admin', side: 'client', toggle: true },
  { name: 'reviveSelf', label: 'Revive yourself', scope: 'self', rank: 'admin', side: 'server' },
  { name: 'teleportMarker', label: 'Teleport to marker', scope: 'self', rank: 'staff', side: 'client' },
  { name: 'teleportBack', label: 'Teleport back', scope: 'self', rank: 'staff', side: 'client' },
  {
    name: 'teleportCoords',
    label: 'Teleport to coords',
    hint: 'x, y, z',
    scope: 'self',
    rank: 'admin',
    side: 'client',
    fields: [{ key: 'coords', label: 'Coords', kind: 'text', placeholder: 'x, y, z e.g. 215.8, -810.1, 30.7' }],
  },
  {
    name: 'teleportLocation',
    label: 'Teleport to location',
    scope: 'self',
    rank: 'admin',
    side: 'client',
    fields: [{ key: 'location', label: 'Location', kind: 'select', list: 'locations' }],
  },
  {
    name: 'setAmmo',
    label: 'Set ammo',
    hint: 'For the weapon in your hands',
    scope: 'self',
    rank: 'admin',
    side: 'server',
    fields: [{ key: 'amount', label: 'Rounds', kind: 'number' }],
  },
  { name: 'coords', label: 'Show coords', scope: 'self', rank: 'admin', side: 'client', toggle: true },
  { name: 'entityLaser', label: 'Entity laser', scope: 'self', rank: 'admin', side: 'client', toggle: true },
  { name: 'entityFreeAim', label: 'Free-aim entity info', scope: 'self', rank: 'admin', side: 'client', toggle: true },
  { name: 'labelVehicles', label: 'Label nearby vehicles', scope: 'self', rank: 'admin', side: 'client', toggle: true },
  { name: 'labelPeds', label: 'Label nearby peds', scope: 'self', rank: 'admin', side: 'client', toggle: true },
  { name: 'labelObjects', label: 'Label nearby objects', scope: 'self', rank: 'admin', side: 'client', toggle: true },
  { name: 'copyVector2', label: 'Copy vector2', scope: 'self', rank: 'admin', side: 'client' },
  { name: 'copyVector3', label: 'Copy vector3', scope: 'self', rank: 'admin', side: 'client' },
  { name: 'copyVector4', label: 'Copy vector4', scope: 'self', rank: 'admin', side: 'client' },
  { name: 'copyHeading', label: 'Copy heading', scope: 'self', rank: 'admin', side: 'client' },
  { name: 'copyEntity', label: 'Copy entity info', hint: 'The entity under free-aim', scope: 'self', rank: 'admin', side: 'client' },
  { name: 'goto', label: 'Go to', scope: 'player', rank: 'staff', side: 'server', fields: [{ key: 'target', label: 'Player', kind: 'number' }] },
  { name: 'bring', label: 'Bring', scope: 'player', rank: 'staff', side: 'server', fields: [{ key: 'target', label: 'Player', kind: 'number' }] },
  { name: 'spectate', label: 'Spectate', scope: 'player', rank: 'staff', side: 'server', fields: [{ key: 'target', label: 'Player', kind: 'number' }] },
  {
    name: 'intoVehicle',
    label: 'Sit in their vehicle',
    scope: 'player',
    rank: 'admin',
    side: 'server',
    fields: [{ key: 'target', label: 'Player', kind: 'number' }],
  },
  {
    name: 'setBucket',
    label: 'Routing bucket',
    scope: 'player',
    rank: 'admin',
    side: 'server',
    fields: [
      { key: 'target', label: 'Player', kind: 'number' },
      { key: 'bucket', label: 'Bucket', kind: 'number' },
    ],
  },
  { name: 'revive', label: 'Revive', scope: 'player', rank: 'admin', side: 'server', fields: [{ key: 'target', label: 'Player', kind: 'number' }] },
  {
    name: 'heal',
    label: 'Heal',
    hint: 'Health, armour, food and water',
    scope: 'player',
    rank: 'admin',
    side: 'server',
    fields: [{ key: 'target', label: 'Player', kind: 'number' }],
  },
  { name: 'freeze', label: 'Freeze', scope: 'player', rank: 'staff', side: 'server', fields: [{ key: 'target', label: 'Player', kind: 'number' }] },
  { name: 'cuff', label: 'Cuff', scope: 'player', rank: 'admin', side: 'server', fields: [{ key: 'target', label: 'Player', kind: 'number' }] },
  {
    name: 'removeStress',
    label: 'Remove stress',
    scope: 'player',
    rank: 'admin',
    side: 'server',
    fields: [{ key: 'target', label: 'Player', kind: 'number' }],
  },
  { name: 'mute', label: 'Mute voice', scope: 'player', rank: 'staff', side: 'server', fields: [{ key: 'target', label: 'Player', kind: 'number' }] },
  { name: 'kill', label: 'Kill', scope: 'player', rank: 'admin', side: 'server', danger: true, fields: [{ key: 'target', label: 'Player', kind: 'number' }] },
  {
    name: 'setJob',
    label: 'Set job',
    scope: 'player',
    rank: 'admin',
    side: 'server',
    fields: [
      { key: 'target', label: 'Player', kind: 'number' },
      { key: 'job', label: 'Job', kind: 'select', list: 'jobs' },
      { key: 'grade', label: 'Grade', kind: 'select', list: 'grades', dependsOn: 'job' },
    ],
  },
  {
    name: 'setGang',
    label: 'Set gang',
    scope: 'player',
    rank: 'admin',
    side: 'server',
    fields: [
      { key: 'target', label: 'Player', kind: 'number' },
      { key: 'gang', label: 'Gang', kind: 'select', list: 'gangs' },
      { key: 'grade', label: 'Grade', kind: 'select', list: 'grades', dependsOn: 'gang' },
    ],
  },
  {
    name: 'setDuty',
    label: 'Switch duty',
    hint: 'Clocks the player on or off for their job',
    scope: 'player',
    rank: 'admin',
    side: 'server',
    fields: [{ key: 'target', label: 'Player', kind: 'number' }],
  },
  {
    name: 'setPed',
    label: 'Set ped',
    scope: 'player',
    rank: 'admin',
    side: 'server',
    fields: [
      { key: 'target', label: 'Player', kind: 'number' },
      { key: 'model', label: 'Ped model', kind: 'select', list: 'peds' },
    ],
  },
  {
    name: 'clothing',
    label: 'Clothing menu',
    hint: 'Opens the wardrobe for them',
    scope: 'player',
    rank: 'admin',
    side: 'server',
    fields: [{ key: 'target', label: 'Player', kind: 'number' }],
  },
  {
    name: 'openInventory',
    label: 'Open inventory',
    scope: 'player',
    rank: 'admin',
    side: 'server',
    fields: [{ key: 'target', label: 'Player', kind: 'number' }],
  },
  {
    name: 'giveItem',
    label: 'Give item',
    hint: 'Player, item, amount',
    scope: 'player',
    rank: 'admin',
    side: 'server',
    fields: [
      { key: 'target', label: 'Player', kind: 'number' },
      { key: 'item', label: 'Item', kind: 'select', list: 'items' },
      { key: 'amount', label: 'Amount', kind: 'number' },
    ],
  },
  {
    name: 'clearInventory',
    label: 'Clear inventory',
    scope: 'player',
    rank: 'admin',
    side: 'server',
    danger: true,
    fields: [{ key: 'target', label: 'Player', kind: 'number' }],
  },
  {
    name: 'giveMoney',
    label: 'Give money',
    hint: 'Cash, bank or crypto',
    scope: 'player',
    rank: 'owner',
    side: 'server',
    fields: [
      { key: 'target', label: 'Player', kind: 'number' },
      { key: 'account', label: 'Account', kind: 'select', list: 'accounts' },
      { key: 'amount', label: 'Amount', kind: 'number' },
    ],
  },
  {
    name: 'removeMoney',
    label: 'Remove money',
    hint: 'Cash, bank or crypto',
    scope: 'player',
    rank: 'owner',
    side: 'server',
    fields: [
      { key: 'target', label: 'Player', kind: 'number' },
      { key: 'account', label: 'Account', kind: 'select', list: 'accounts' },
      { key: 'amount', label: 'Amount', kind: 'number' },
    ],
  },
  {
    name: 'giveCar',
    label: 'Give car',
    hint: 'Adds it to their garage',
    scope: 'player',
    rank: 'owner',
    side: 'server',
    fields: [
      { key: 'target', label: 'Player', kind: 'number' },
      { key: 'model', label: 'Vehicle', kind: 'select', list: 'vehicles' },
      { key: 'plate', label: 'Plate', kind: 'text', optional: true },
      { key: 'garage', label: 'Garage', kind: 'text', optional: true },
    ],
  },
  {
    name: 'spawnTheirVehicle',
    label: 'Spawn their vehicle',
    scope: 'player',
    rank: 'admin',
    side: 'server',
    fields: [
      { key: 'target', label: 'Player', kind: 'number' },
      { key: 'plate', label: 'Vehicle', kind: 'select', list: 'playerVehicles' },
    ],
  },
  {
    name: 'fixTheirVehicle',
    label: 'Fix their vehicle',
    scope: 'player',
    rank: 'admin',
    side: 'server',
    fields: [{ key: 'target', label: 'Player', kind: 'number' }],
  },
  { name: 'drunk', label: 'Make drunk', scope: 'player', rank: 'admin', side: 'server', fields: [{ key: 'target', label: 'Player', kind: 'number' }] },
  {
    name: 'playSound',
    label: 'Play sound',
    scope: 'player',
    rank: 'admin',
    side: 'server',
    fields: [
      { key: 'target', label: 'Player', kind: 'number' },
      { key: 'sound', label: 'Sound', kind: 'select', list: 'sounds' },
    ],
  },
  {
    name: 'setOnFire',
    label: 'Set on fire',
    scope: 'player',
    rank: 'admin',
    side: 'server',
    danger: true,
    fields: [{ key: 'target', label: 'Player', kind: 'number' }],
  },
  {
    name: 'explode',
    label: 'Explode',
    scope: 'player',
    rank: 'admin',
    side: 'server',
    danger: true,
    fields: [{ key: 'target', label: 'Player', kind: 'number' }],
  },
  {
    name: 'warn',
    label: 'Warn',
    scope: 'player',
    rank: 'staff',
    side: 'server',
    fields: [
      { key: 'target', label: 'Player', kind: 'number' },
      { key: 'reason', label: 'Reason', kind: 'textarea' },
    ],
  },
  {
    name: 'setPermission',
    label: 'Set permissions',
    scope: 'player',
    rank: 'owner',
    side: 'server',
    fields: [
      { key: 'target', label: 'Player', kind: 'number' },
      { key: 'rank', label: 'Rank', kind: 'select', list: 'ranks' },
    ],
  },
  {
    name: 'kick',
    label: 'Kick',
    scope: 'player',
    rank: 'staff',
    side: 'server',
    danger: true,
    fields: [
      { key: 'target', label: 'Player', kind: 'number' },
      { key: 'reason', label: 'Reason', kind: 'textarea' },
    ],
  },
  { name: 'ban', label: 'Ban', scope: 'player', rank: 'admin', side: 'server', danger: true, fields: [{ key: 'target', label: 'Player', kind: 'number' }] },
  {
    name: 'spawnVehicle',
    label: 'Spawn vehicle',
    hint: 'You get the keys',
    scope: 'vehicle',
    rank: 'admin',
    side: 'server',
    fields: [{ key: 'model', label: 'Vehicle', kind: 'select', list: 'vehicles' }],
  },
  { name: 'fixVehicle', label: 'Fix vehicle', scope: 'vehicle', rank: 'admin', side: 'client' },
  { name: 'refuelVehicle', label: 'Refuel vehicle', scope: 'vehicle', rank: 'admin', side: 'server' },
  { name: 'maxMods', label: 'Max mods', scope: 'vehicle', rank: 'admin', side: 'client' },
  {
    name: 'changePlate',
    label: 'Change plate',
    scope: 'vehicle',
    rank: 'admin',
    side: 'server',
    fields: [{ key: 'plate', label: 'New plate', kind: 'text', placeholder: 'Up to 8 characters' }],
  },
  { name: 'saveVehicle', label: 'Save to my garage', scope: 'vehicle', rank: 'admin', side: 'server' },
  { name: 'deleteVehicle', label: 'Delete vehicle', scope: 'vehicle', rank: 'admin', side: 'client', danger: true },
  {
    name: 'vehicleDev',
    label: 'Vehicle dev overlay',
    hint: 'Entity ID, net ID, hash and health on screen',
    scope: 'vehicle',
    rank: 'admin',
    side: 'client',
    toggle: true,
  },
  { name: 'openTrunk', label: 'Open trunk', scope: 'vehicle', rank: 'admin', side: 'server', fields: [{ key: 'plate', label: 'Plate', kind: 'text' }] },
  {
    name: 'markInGarage',
    label: 'Mark as in garage',
    scope: 'vehicle',
    rank: 'admin',
    side: 'server',
    fields: [{ key: 'plate', label: 'Plate', kind: 'text' }],
  },
  { name: 'markOut', label: 'Mark as out', scope: 'vehicle', rank: 'admin', side: 'server', fields: [{ key: 'plate', label: 'Plate', kind: 'text' }] },
  {
    name: 'setWeather',
    label: 'Change weather',
    scope: 'world',
    rank: 'admin',
    side: 'server',
    fields: [{ key: 'weather', label: 'Weather', kind: 'select', list: 'weatherTypes' }],
  },
  {
    name: 'setTime',
    label: 'Change time',
    scope: 'world',
    rank: 'admin',
    side: 'server',
    fields: [{ key: 'hour', label: 'Time', kind: 'select', list: 'timePresets' }],
  },
  { name: 'freezeTime', label: 'Freeze time', scope: 'world', rank: 'admin', side: 'server', toggle: true },
  { name: 'dynamicWeather', label: 'Dynamic weather', scope: 'world', rank: 'admin', side: 'server', toggle: true },
  { name: 'blackout', label: 'Blackout', scope: 'world', rank: 'admin', side: 'server', toggle: true },
  {
    name: 'announce',
    label: 'Announcement',
    hint: 'Sent to every player in chat',
    scope: 'server',
    rank: 'admin',
    side: 'server',
    fields: [{ key: 'message', label: 'Message', kind: 'textarea' }],
  },
  { name: 'reviveAll', label: 'Revive all', scope: 'server', rank: 'admin', side: 'server' },
  { name: 'reviveRadius', label: 'Revive within radius', hint: '15 m around you', scope: 'server', rank: 'admin', side: 'server' },
  {
    name: 'giveItemAll',
    label: 'Give item to everyone',
    hint: 'Item, amount',
    scope: 'server',
    rank: 'admin',
    side: 'server',
    fields: [
      { key: 'item', label: 'Item', kind: 'select', list: 'items' },
      { key: 'amount', label: 'Amount', kind: 'number' },
    ],
  },
  {
    name: 'giveMoneyAll',
    label: 'Give money to everyone',
    hint: 'Cash, bank or crypto',
    scope: 'server',
    rank: 'owner',
    side: 'server',
    fields: [
      { key: 'account', label: 'Account', kind: 'select', list: 'accounts' },
      { key: 'amount', label: 'Amount', kind: 'number' },
    ],
  },
  {
    name: 'kickAll',
    label: 'Kick everyone',
    scope: 'server',
    rank: 'owner',
    side: 'server',
    danger: true,
    fields: [{ key: 'reason', label: 'Reason', kind: 'textarea' }],
  },
  {
    name: 'unban',
    label: 'Unban',
    hint: 'Ban ID, license or Discord ID',
    scope: 'server',
    rank: 'admin',
    side: 'server',
    fields: [{ key: 'ban', label: 'Ban ID or identifier', kind: 'text' }],
  },
  {
    name: 'clearInventoryOffline',
    label: 'Clear offline inventory',
    hint: 'By citizen ID',
    scope: 'server',
    rank: 'admin',
    side: 'server',
    danger: true,
    fields: [{ key: 'citizenid', label: 'Citizen ID', kind: 'text' }],
  },
  { name: 'openStash', label: 'Open stash', scope: 'server', rank: 'admin', side: 'server', fields: [{ key: 'stash', label: 'Stash ID', kind: 'text' }] },
  { name: 'resource', label: 'Resource state', scope: 'server', rank: 'owner', side: 'server' },
  { name: 'receiveReports', label: 'Receive reports', scope: 'report', rank: 'staff', side: 'server', toggle: true },
  { name: 'reportGoto', label: 'Go to reporter', scope: 'report', rank: 'staff', side: 'server' },
  {
    name: 'reportReply',
    label: 'Reply to report',
    scope: 'report',
    rank: 'staff',
    side: 'server',
    fields: [{ key: 'message', label: 'Reply', kind: 'textarea' }],
  },
  { name: 'reportClose', label: 'Close report', scope: 'report', rank: 'staff', side: 'server' },
];

const actions: Action[] = definitions.map((action) => ({ ...action, allowed: rankLevels[viewerRank] >= rankLevels[action.rank] }));

const now = Math.floor(Date.now() / 1000);

const players: PlayerRow[] = [
  { id: 3, name: 'Marcus Noodles', citizenid: 'KXT40291', job: 'Mechanic', grade: 'Lead tech', onDuty: true, down: false, staff: false, distance: 40 },
  { id: 4, name: 'Deez Nuuts', citizenid: 'PLM88213', job: 'Unemployed', grade: 'Civilian', onDuty: false, down: false, staff: false, distance: 85 },
  {
    id: 7,
    name: 'Poop McGee',
    citizenid: 'QWE10477',
    job: 'EMS',
    grade: 'Paramedic',
    onDuty: true,
    down: true,
    downSince: now - 100,
    staff: false,
    distance: 320,
  },
  { id: 9, name: 'Taleb Mahzuz', citizenid: 'BRT55102', job: 'Police', grade: 'Sergeant', onDuty: true, down: false, staff: true, distance: 12 },
  { id: 12, name: 'Wahad Smeek', citizenid: 'HJD20983', job: 'Taxi', grade: 'Driver', onDuty: true, down: false, staff: false, distance: 900 },
  {
    id: 15,
    name: 'Theodore The 2nd preceeding the 1st',
    citizenid: 'ZPL61740',
    job: 'Unemployed',
    grade: 'Ballas, enforcer',
    onDuty: false,
    down: true,
    downSince: now - 340,
    staff: false,
    distance: 60,
  },
  { id: 18, name: 'Priya Shah', citizenid: 'MKA39915', job: 'Real estate', grade: 'Agent', onDuty: true, down: false, staff: false, distance: 1500 },
  { id: 21, name: 'Cole Mercer', citizenid: 'YTR80056', job: 'Police', grade: 'Cadet', onDuty: true, down: false, staff: false, distance: 95 },
  { id: 24, name: 'Sofia Lund', citizenid: 'FGH42218', job: 'Mechanic', grade: 'Apprentice', onDuty: false, down: false, staff: false, distance: 2400 },
  { id: 27, name: 'Omar Haddad', citizenid: 'LKJ77341', job: 'Unemployed', grade: 'Civilian', onDuty: false, down: false, staff: true, distance: 700 },
  { id: 31, name: 'Nina Volkova', citizenid: 'WER09124', job: 'Burger Shot', grade: 'Cook', onDuty: true, down: false, staff: false, distance: 3100 },
  { id: 33, name: 'Eli Navarro', citizenid: 'CVB55830', job: 'Lawyer', grade: 'Partner', onDuty: false, down: false, staff: true, distance: 450 },
  { id: 36, name: 'June Park', citizenid: 'TYU64402', job: 'Unemployed', grade: 'Civilian', onDuty: false, down: false, staff: true, distance: 30 },
];

let reports: Report[] = [
  { id: 14, source: 3, name: 'Marcus Noodles', message: 'Car fell through the map at Legion Square garage', at: now - 120 },
  { id: 33, source: 4, name: 'Deez Nuuts', message: 'Someone is ramming cars outside Pillbox', at: now - 360 },
  { id: 7, source: 7, name: 'Poop McGee', message: "Lost my phone after a crash, can't call EMS", at: now - 660 },
];

let staffChat: ChatMessage[] = [
  { name: 'Rook', message: 'Restarting cobalt_garages in 5 minutes, warn anyone parking or not', at: now - 540 },
  { name: 'Nova', message: 'Taking #33, heading to Pillbox now', at: now - 360 },
];

let world: WorldState = { weather: 'EXTRASUNNY', hour: 21, minute: 48, freezeTime: false, dynamicWeather: true, blackout: false };

const resources: Resource[] = [
  { name: 'cobalt_core', version: '1.0.0', description: 'Player state, money, jobs and gangs', state: 'started' },
  { name: 'cobalt_inventory', version: '1.0.0', description: 'Items, stashes and items n stuff', state: 'started' },
  { name: 'cobalt_garages', version: '1.0.0', description: 'Parking, impound and keys', state: 'starting' },
  { name: 'ox_fuel', version: '1.5.0', description: 'Fuel and pumps', state: 'started' },
  { name: 'cobalt_dealership', version: '1.0.0', description: 'Showroom, test drives and finance', state: 'stopped' },
  { name: 'cobalt_housing', version: '1.0.0', description: 'Properties and starter apartments', state: 'started' },
  { name: 'npwd', version: '1.8.6', description: 'Phone', state: 'started' },
];

const worldToggleNames = ['freezeTime', 'dynamicWeather', 'blackout'] as const;

function post(message: NuiMessage): void {
  window.postMessage(message, '*');
}

function detail(id: number): PlayerDetail | null {
  const row = players.find((player) => player.id === id);
  if (!row) return null;
  return {
    ...row,
    cash: 1240,
    bank: 18560,
    phone: '555-0193',
    warnings: { count: 2, last: now - 5 * 86400 },
    onlineSeconds: 2 * 3600 + 14 * 60,
    bucket: 0,
    frozen: false,
    identifiers: { license: 'license:3f9a81b0d2e47c55a1c21e', discord: 'discord:412093377128835' },
    vehicles: [
      { label: 'Sultan RS (58KRT221)', value: '58KRT221' },
      { label: 'Bati 801 (21BTI801)', value: '21BTI801' },
    ],
  };
}

function runAction(name: string, args: Record<string, unknown> | undefined): void {
  const worldToggle = worldToggleNames.find((toggle) => toggle === name);
  if (worldToggle) {
    world = { ...world, [worldToggle]: args?.enabled === true };
    post({ action: 'world', data: world });
  } else if (name === 'setWeather' && typeof args?.weather === 'string') {
    world = { ...world, weather: args.weather };
    post({ action: 'world', data: world });
  } else if (name === 'setTime' && typeof args?.hour === 'number') {
    world = { ...world, hour: args.hour, minute: 0 };
    post({ action: 'world', data: world });
  } else if (name === 'reportClose') {
    reports = reports.filter((report) => report.id !== args?.report);
    post({ action: 'reports', data: reports });
  } else if (args && typeof args.enabled === 'boolean') {
    post({ action: 'toggles', data: { [name]: args.enabled } });
  } else if (name === 'resource' && typeof args?.name === 'string') {
    const resource = resources.find((entry) => entry.name === args.name);
    if (resource) resource.state = args.state === 'stop' ? 'stopped' : 'started';
  }
}

const lists = {
  items: [
    { label: 'Bandage', value: 'bandage' },
    { label: 'Phone', value: 'phone' },
    { label: 'Water bottle', value: 'water_bottle' },
    { label: 'Sandwich', value: 'sandwich' },
    { label: 'Lockpick', value: 'lockpick' },
    { label: 'Repair kit', value: 'repairkit' },
    { label: 'Radio', value: 'radio' },
    { label: 'Pistol ammo', value: 'pistol_ammo' },
    { label: 'Pistol', value: 'weapon_pistol' },
    { label: 'Cash roll', value: 'cashroll' },
  ],
  jobs: [
    { label: 'Unemployed', value: 'unemployed', grades: [{ label: 'Civilian', value: 0 }] },
    {
      label: 'Police',
      value: 'police',
      grades: [
        { label: 'Cadet', value: 0 },
        { label: 'Officer', value: 1 },
        { label: 'Sergeant', value: 2 },
      ],
    },
    {
      label: 'EMS',
      value: 'ambulance',
      grades: [
        { label: 'Paramedic', value: 0 },
        { label: 'Doctor', value: 1 },
      ],
    },
    {
      label: 'Mechanic',
      value: 'mechanic',
      grades: [
        { label: 'Apprentice', value: 0 },
        { label: 'Lead tech', value: 1 },
      ],
    },
  ],
  gangs: [
    { label: 'None', value: 'none', grades: [{ label: 'Unaffiliated', value: 0 }] },
    {
      label: 'Ballas',
      value: 'ballas',
      grades: [
        { label: 'Recruit', value: 0 },
        { label: 'Enforcer', value: 1 },
      ],
    },
  ],
  vehicles: [
    { model: 'police3', name: 'Police Interceptor', category: 'Emergency' },
    { model: 'ambulance', name: 'Ambulance', category: 'Emergency' },
    { model: 'zentorno', name: 'Zentorno', category: 'Super' },
    { model: 'sultanrs', name: 'Sultan RS', category: 'Sports' },
    { model: 'elegy', name: 'Elegy Retro', category: 'Sports' },
    { model: 'flatbed', name: 'Flatbed', category: 'Industrial' },
    { model: 'bati', name: 'Bati 801', category: 'Motorcycles' },
    { model: 'sanchez', name: 'Sanchez', category: 'Motorcycles' },
    { model: 'maverick', name: 'Maverick', category: 'Air' },
  ],
  peds: [
    { label: 'Freemode male', value: 'mp_m_freemode_01' },
    { label: 'Freemode female', value: 'mp_f_freemode_01' },
    { label: 'Chimp', value: 'a_c_chimp' },
  ],
  locations: [
    { label: 'Legion Square', value: 'legion' },
    { label: 'Mission Row PD', value: 'mrpd' },
    { label: 'Pillbox Hospital', value: 'pillbox' },
    { label: 'Sandy Shores', value: 'sandy' },
    { label: 'Paleto Bay', value: 'paleto' },
    { label: 'Del Perro Pier', value: 'pier' },
    { label: 'Mount Chiliad', value: 'chiliad' },
    { label: 'Fort Zancudo', value: 'zancudo' },
    { label: 'Vinewood Sign', value: 'vinewood' },
    { label: 'LSIA', value: 'airport' },
  ],
  accounts: [
    { label: 'Cash', value: 'cash' },
    { label: 'Bank', value: 'bank' },
    { label: 'Crypto', value: 'crypto' },
  ],
  sounds: [
    { label: 'Air horn', value: 'airhorn' },
    { label: 'Phone ring', value: 'phone' },
  ],
  ranks: [
    { label: 'Staff', value: 'staff' },
    { label: 'Admin', value: 'admin' },
    { label: 'Owner', value: 'owner' },
  ],
  weatherTypes: [
    { label: 'Extra sunny', value: 'EXTRASUNNY' },
    { label: 'Clear', value: 'CLEAR' },
    { label: 'Clouds', value: 'CLOUDS' },
    { label: 'Overcast', value: 'OVERCAST' },
    { label: 'Rain', value: 'RAIN' },
    { label: 'Thunder', value: 'THUNDER' },
    { label: 'Foggy', value: 'FOGGY' },
    { label: 'Snow', value: 'SNOW' },
    { label: 'Xmas', value: 'XMAS' },
    { label: 'Halloween', value: 'HALLOWEEN' },
  ],
  timePresets: [
    { label: 'Sunrise', value: 6 },
    { label: 'Morning', value: 9 },
    { label: 'Noon', value: 12 },
    { label: 'Sunset', value: 18 },
    { label: 'Evening', value: 20 },
    { label: 'Night', value: 23 },
  ],
  banLengths: [
    { label: '10 minutes', value: 600 },
    { label: '1 hour', value: 3600 },
    { label: '6 hours', value: 21600 },
    { label: '1 day', value: 86400 },
    { label: '3 days', value: 259200 },
    { label: '1 week', value: 604800 },
    { label: '3 weeks', value: 1814400 },
    { label: '1 month', value: 2592000 },
    { label: '3 months', value: 7776000 },
    { label: '1 year', value: 31536000 },
  ],
};

const handlers: MockHandlers = {
  close: () => true,
  action: ({ name, args }) => {
    runAction(name, args);
    return { ok: true };
  },
  getPlayers: () => players,
  getPlayer: ({ id }) => detail(id),
  getWarnings: () => [
    { id: 2, reason: 'Ramming cars outside Pillbox', by: 'Nova', at: now - 5 * 86400 },
    { id: 1, reason: 'Failing to roleplay a traffic stop', by: 'Rook', at: now - 21 * 86400 },
  ],
  getLists: () => lists,
  getVehicle: () => ({ label: 'Sultan RS', model: 'sultanrs', plate: '58KRT221', netId: 4211, owner: 'Marcus Noodles', engine: 742, body: 880, fuel: 14 }),
  getResources: () => resources.map((resource) => ({ ...resource })),
  getWorld: () => world,
  getCommands: () => [
    { name: 'givemoney', help: 'id, type, amount' },
    { name: 'giveitem', help: 'id, item, amount' },
    { name: 'car', help: 'Spawn a vehicle by model' },
    { name: 'dv', help: 'Delete the vehicle you are in or near' },
    { name: 'tpm', help: 'Teleport to your map marker' },
    { name: 'setjob', help: 'id, job, grade' },
  ],
  sendStaffChat: ({ message }) => {
    staffChat = [...staffChat, { name: 'You', message, at: Math.floor(Date.now() / 1000) }];
    post({ action: 'staffChat', data: staffChat });
    return true;
  },
  runCommand: () => true,
};

const bootstrap: Bootstrap = {
  rank: viewerRank,
  self: { id: 1, name: 'Sleiman' },
  actions,
  toggles: { noclip: true, names: true, coords: true, labelVehicles: true },
  online: 62,
  staffOnDuty: 4,
  receivingReports: true,
  reports,
  staffChat,
  keys: { noclip: 'PAGEUP' },
  quickLocations: lists.locations.slice(0, 5),
  build: '38004',
  uptime: 6 * 3600 + 12 * 60,
};

const pause = (ms: number) => new Promise((resolve) => window.setTimeout(resolve, ms));

function element(selector: string): HTMLElement | null {
  const found = document.querySelector(selector);
  return found instanceof HTMLElement ? found : null;
}

function clickLabelled(label: string): void {
  element(`[aria-label="${label}"]`)?.click();
}

function clickText(text: string): void {
  const match = [...document.querySelectorAll('button, [role="option"]')].find((node) => node.textContent?.trim() === text);
  if (match instanceof HTMLElement) match.click();
}

function typeInto(field: HTMLInputElement | HTMLTextAreaElement, text: string): void {
  const prototype = field instanceof HTMLTextAreaElement ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
  Object.getOwnPropertyDescriptor(prototype, 'value')?.set?.call(field, text);
  field.dispatchEvent(new Event('input', { bubbles: true }));
}

async function openPlayer(): Promise<void> {
  clickLabelled('Players');
  await pause(150);
  const rows = document.querySelectorAll('[aria-label="Open details"]');
  const second = rows[1];
  if (second instanceof HTMLElement) second.click();
  await pause(150);
}

const scenes: Record<string, () => Promise<void>> = {
  search: async () => {
    const search = document.querySelector('input');
    if (!search) return;
    search.focus();
    typeInto(search, 'give');
  },
  players: async () => {
    clickLabelled('Players');
    await pause(150);
    const rows = document.querySelectorAll('[aria-label="Open details"]');
    const row = rows[1]?.closest('.h-14');
    if (row instanceof HTMLElement) row.click();
  },
  player: openPlayer,
  ban: async () => {
    await openPlayer();
    clickText('Ban');
    await pause(150);
    const reason = document.querySelector('textarea');
    if (reason) typeInto(reason, 'Ramming cars outside Pillbox after two warnings (report #33)');
    element('#ban-duration')?.click();
  },
  confirm: async () => {
    await scenes.ban?.();
    await pause(100);
    clickText('3 days');
    await pause(100);
    clickText('Review ban');
  },
  pin: async () => {
    const search = document.querySelector('input');
    if (!search) return;
    search.focus();
    typeInto(search, 'heal');
    await pause(100);
    search.dispatchEvent(new KeyboardEvent('keydown', { key: 'p', ctrlKey: true, bubbles: true }));
    await pause(100);
    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
  },
  form: async () => {
    await openPlayer();
    clickText('Set job');
    await pause(150);
    element('#field-job')?.click();
  },
  warnings: async () => {
    await openPlayer();
    clickText('View warnings');
  },
  palette: async () => {
    const search = document.querySelector('input');
    if (!search) return;
    search.focus();
    typeInto(search, 'give item');
    await pause(100);
    search.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
    await pause(200);
    element('#field-target')?.click();
  },
  vehicles: async () => clickLabelled('Vehicles'),
  server: async () => clickLabelled('Server'),
  world: async () => clickLabelled('World and dev tools'),
  commands: async () => clickLabelled('Commands'),
  reports: async () => clickLabelled('Reports'),
};

document.body.style.background = '#1E2633';
installMock(handlers);
post({ action: 'open', data: bootstrap });

const scene = scenes[new URLSearchParams(window.location.search).get('scene') ?? ''];
if (scene) void pause(300).then(scene);
