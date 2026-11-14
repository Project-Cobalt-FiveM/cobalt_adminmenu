import type { Action } from './types';

export interface PlayerRef {
  id: number;
  name: string;
}

export interface ActionContext {
  target?: PlayerRef;
  report?: number;
  preset?: Record<string, string | number>;
}

export type NavPage = 'home' | 'players' | 'vehicles' | 'world' | 'commands' | 'server' | 'reports';

export type View =
  | { page: NavPage }
  | { page: 'player'; id: number }
  | { page: 'ban'; target: PlayerRef }
  | { page: 'warnings'; target: PlayerRef }
  | { page: 'form'; action: Action; context: ActionContext; back: View };

export function navPageOf(view: View): NavPage {
  switch (view.page) {
    case 'player':
    case 'ban':
    case 'warnings':
      return 'players';
    case 'form':
      return navPageOf(view.back);
    default:
      return view.page;
  }
}

export function viewKey(view: View): string {
  switch (view.page) {
    case 'player':
      return `player:${view.id}`;
    case 'ban':
    case 'warnings':
      return `${view.page}:${view.target.id}`;
    case 'form':
      return `form:${view.action.name}`;
    default:
      return view.page;
  }
}

export const navKeys: Record<NavPage, string> = {
  home: 'ui.nav.home',
  players: 'ui.nav.players',
  vehicles: 'ui.nav.vehicles',
  world: 'ui.nav.world',
  commands: 'ui.nav.commands',
  server: 'ui.nav.server',
  reports: 'ui.nav.reports',
};
