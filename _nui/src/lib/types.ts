export type Rank = 'staff' | 'admin' | 'owner';

export const rankKeys: Record<Rank, string> = { staff: 'ui.ranks.staff', admin: 'ui.ranks.admin', owner: 'ui.ranks.owner' };

export type Scope = 'self' | 'player' | 'vehicle' | 'world' | 'server' | 'report';

export type FieldKind = 'text' | 'textarea' | 'number' | 'select';

export type ListName =
  | 'items'
  | 'jobs'
  | 'gangs'
  | 'grades'
  | 'vehicles'
  | 'peds'
  | 'locations'
  | 'accounts'
  | 'sounds'
  | 'ranks'
  | 'weatherTypes'
  | 'timePresets'
  | 'playerVehicles';

export interface Field {
  key: string;
  label: string;
  kind: FieldKind;
  list?: ListName;
  dependsOn?: string;
  optional?: boolean;
  placeholder?: string;
}

export interface Action {
  name: string;
  label: string;
  hint?: string;
  scope: Scope;
  rank: Rank;
  side: 'server' | 'client';
  toggle?: boolean;
  danger?: boolean;
  fields?: Field[];
  allowed: boolean;
}

export interface Option {
  label: string;
  value: string | number;
}

export interface GradedOption extends Option {
  grades: Option[];
}

export interface VehicleModel {
  model: string;
  name: string;
  category: string;
}

export interface Lists {
  items: Option[];
  jobs: GradedOption[];
  gangs: GradedOption[];
  vehicles: VehicleModel[];
  peds: Option[];
  locations: Option[];
  accounts: Option[];
  sounds: Option[];
  ranks: Option[];
  weatherTypes: Option[];
  timePresets: Option[];
  banLengths: Option[];
}

export interface Report {
  id: number;
  source: number;
  name: string;
  message: string;
  at: number;
}

export interface ChatMessage {
  name: string;
  message: string;
  at: number;
}

export interface Bootstrap {
  rank: Rank;
  self: { id: number; name: string };
  actions: Action[];
  toggles: Record<string, boolean>;
  online: number;
  staffOnDuty: number;
  receivingReports: boolean;
  reports: Report[];
  staffChat: ChatMessage[];
  keys: { noclip: string };
  quickLocations: Option[];
  build: string;
  uptime: number;
  locales?: Record<string, string>;
}

export interface PlayerRow {
  id: number;
  name: string;
  citizenid: string;
  job: string;
  grade: string;
  onDuty: boolean;
  down: boolean;
  downSince?: number;
  staff: boolean;
  distance: number;
}

export interface PlayerDetail extends PlayerRow {
  cash: number;
  bank: number;
  phone?: string;
  gang?: string;
  gangGrade?: string;
  warnings: { count: number; last?: number };
  onlineSeconds: number;
  bucket: number;
  frozen: boolean;
  identifiers: { license?: string; discord?: string; steam?: string };
  vehicles: Option[];
}

export interface Warning {
  id: number;
  reason: string;
  by: string;
  at: number;
}

export interface CurrentVehicle {
  label: string;
  model: string;
  plate: string;
  netId: number;
  owner?: string;
  engine: number;
  body: number;
  fuel: number;
}

export type ResourceState = 'started' | 'starting' | 'stopped' | 'stopping' | 'missing' | 'uninitialized' | 'unknown';

export interface Resource {
  name: string;
  version?: string;
  description?: string;
  state: ResourceState;
}

export interface WorldState {
  weather: string;
  hour: number;
  minute: number;
  freezeTime: boolean;
  dynamicWeather: boolean;
  blackout: boolean;
}

export interface Command {
  name: string;
  help?: string;
}

export interface ActionResult {
  ok: boolean;
  message?: string;
}

export interface BanArgs {
  target: number;
  reason: string;
  duration: number | 'permanent';
  license: boolean;
  discord: boolean;
  steam: boolean;
}

type NoArgs = Record<string, never>;

export interface NuiCallbacks {
  close: { args: NoArgs; result: boolean };
  action: { args: { name: string; args?: Record<string, unknown> }; result: ActionResult };
  getPlayers: { args: NoArgs; result: PlayerRow[] };
  getPlayer: { args: { id: number }; result: PlayerDetail | null };
  getWarnings: { args: { id: number }; result: Warning[] };
  getLists: { args: NoArgs; result: Lists };
  getVehicle: { args: NoArgs; result: CurrentVehicle | null };
  getResources: { args: NoArgs; result: Resource[] };
  getWorld: { args: NoArgs; result: WorldState };
  getCommands: { args: NoArgs; result: Command[] };
  sendStaffChat: { args: { message: string }; result: boolean };
  runCommand: { args: { name: string }; result: boolean };
}

export type NuiMessage =
  | { action: 'open'; data: Bootstrap }
  | { action: 'close' }
  | { action: 'toggles'; data: Record<string, boolean> }
  | { action: 'reports'; data: Report[] }
  | { action: 'staffChat'; data: ChatMessage[] }
  | { action: 'world'; data: WorldState };
