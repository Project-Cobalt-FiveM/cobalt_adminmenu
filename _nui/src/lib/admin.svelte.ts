import { createContext } from 'svelte';
import { nui } from './nui';
import type { Action, ActionResult, Bootstrap, ChatMessage, Command, Lists, NuiMessage, PlayerDetail, PlayerRow, Report, WorldState } from './types';
import type { ActionContext, View } from './view';

type WorldToggle = 'freezeTime' | 'dynamicWeather' | 'blackout';

function isWorldToggle(name: string): name is WorldToggle {
  return name === 'freezeTime' || name === 'dynamicWeather' || name === 'blackout';
}

export function contextArgs(context: ActionContext): Record<string, unknown> {
  return {
    ...context.preset,
    ...(context.target ? { target: context.target.id } : {}),
    ...(context.report != null ? { report: context.report } : {}),
  };
}

export class Admin {
  readonly boot: Bootstrap;
  readonly openedAt: number;
  readonly actions: ReadonlyMap<string, Action>;
  readonly #onClose: () => void;
  #listsRequested = false;
  #commandsRequested = false;

  toggles: Record<string, boolean> = $state({});
  reports: Report[] = $state.raw([]);
  staffChat: ChatMessage[] = $state.raw([]);
  receivingReports = $state(false);
  world: WorldState | null = $state.raw(null);
  players: PlayerRow[] = $state.raw([]);
  lists: Lists | null = $state.raw(null);
  commands: Command[] | null = $state.raw(null);
  version = $state(0);
  view: View = $state.raw({ page: 'home' });
  searchInput: HTMLInputElement | null = $state(null);

  constructor(boot: Bootstrap, openedAt: number, onClose: () => void) {
    this.boot = boot;
    this.openedAt = openedAt;
    this.#onClose = onClose;
    this.actions = new Map(boot.actions.map((action) => [action.name, action]));
    this.toggles = { ...boot.toggles };
    this.reports = boot.reports;
    this.staffChat = boot.staffChat;
    this.receivingReports = boot.receivingReports;
  }

  receive(message: NuiMessage): void {
    switch (message.action) {
      case 'toggles':
        Object.assign(this.toggles, message.data);
        break;
      case 'reports':
        this.reports = message.data;
        break;
      case 'staffChat':
        this.staffChat = message.data;
        break;
      case 'world':
        this.world = message.data;
        break;
      case 'open':
      case 'close':
        break;
      default: {
        const _exhaustive: never = message;
        return _exhaustive;
      }
    }
  }

  navigate = (view: View): void => {
    this.view = view;
  };

  refreshPlayers = (): void => {
    void nui('getPlayers', {}).then((rows) => {
      if (rows) this.players = rows;
    });
  };

  refreshWorld = (): void => {
    void nui('getWorld', {}).then((state) => {
      if (state) this.world = state;
    });
  };

  loadLists = (): void => {
    if (this.#listsRequested) return;
    this.#listsRequested = true;
    void nui('getLists', {}).then((result) => {
      if (result) this.lists = result;
      else this.#listsRequested = false;
    });
  };

  loadCommands = (): void => {
    if (this.#commandsRequested) return;
    this.#commandsRequested = true;
    void nui('getCommands', {}).then((result) => {
      if (result) this.commands = result;
      else this.#commandsRequested = false;
    });
  };

  run = async (name: string, args?: Record<string, unknown>): Promise<ActionResult | null> => {
    const result = await nui('action', args ? { name, args } : { name });
    this.version += 1;
    return result;
  };

  isOn = (name: string): boolean => {
    if (isWorldToggle(name)) return this.world?.[name] === true;
    if (name === 'receiveReports') return this.receivingReports;
    return this.toggles[name] === true;
  };

  #showToggle(name: string, enabled: boolean): void {
    if (name === 'receiveReports') this.receivingReports = enabled;
    else if (!isWorldToggle(name)) this.toggles[name] = enabled;
  }

  setToggle = (name: string, enabled: boolean): void => {
    this.#showToggle(name, enabled);
    void this.run(name, { enabled }).then((result) => {
      if (!result?.ok) this.#showToggle(name, !enabled);
      if (isWorldToggle(name)) this.refreshWorld();
    });
  };

  openAction = (action: Action, context: ActionContext): void => {
    if (!action.allowed) return;
    if (action.toggle) {
      this.setToggle(action.name, !this.isOn(action.name));
      return;
    }
    if (action.name === 'ban') {
      this.view = context.target ? { page: 'ban', target: context.target } : { page: 'players' };
      return;
    }
    const fields = (action.fields ?? []).filter((field) => !(field.key === 'target' && context.target));
    const preset = context.preset ?? {};
    if (fields.every((field) => preset[field.key] != null)) {
      void this.run(action.name, contextArgs(context));
      return;
    }
    this.view = { page: 'form', action, context, back: this.view };
  };

  close = (): void => {
    void nui('close', {});
    this.#onClose();
  };
}

export const [getAdmin, setAdmin] = createContext<Admin>();

export function playerDetail(admin: Admin, id: () => number | undefined): { readonly current: PlayerDetail | null } {
  let player = $state.raw<PlayerDetail | null>(null);
  $effect(() => {
    const target = id();
    void admin.version;
    if (target == null) return;
    let live = true;
    void nui('getPlayer', { id: target }).then((detail) => {
      if (live) player = detail;
    });
    return () => {
      live = false;
    };
  });
  return {
    get current() {
      return player;
    },
  };
}
