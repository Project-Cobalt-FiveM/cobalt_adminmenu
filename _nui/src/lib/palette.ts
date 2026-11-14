import { fuzzyFilter } from './fuzzy';
import { t } from './locale.svelte';
import { rankKeys, type Action, type Command, type PlayerRow } from './types';

export type PaletteEntry =
  | { kind: 'action'; key: string; action: Action }
  | { kind: 'player'; key: string; player: PlayerRow }
  | { kind: 'command'; key: string; command: Command };

export const groupKeys: Record<PaletteEntry['kind'], string> = { action: 'ui.palette.actions', player: 'ui.palette.players', command: 'ui.palette.commands' };

export function paletteEntries(query: string, actions: Action[], players: PlayerRow[], commands: Command[]): PaletteEntry[] {
  const matchedActions = fuzzyFilter(actions, query, (action) => [action.label, action.name, action.hint]).slice(0, 7);
  const matchedPlayers = fuzzyFilter(players, query, (player) => [player.name, String(player.id), player.citizenid]).slice(0, 4);
  const matchedCommands = fuzzyFilter(commands, query.replace(/^\//, ''), (command) => [command.name, command.help]).slice(0, 4);
  return [
    ...matchedActions.map((action): PaletteEntry => ({ kind: 'action', key: `a:${action.name}`, action })),
    ...matchedPlayers.map((player): PaletteEntry => ({ kind: 'player', key: `p:${player.id}`, player })),
    ...matchedCommands.map((command): PaletteEntry => ({ kind: 'command', key: `c:${command.name}`, command })),
  ];
}

interface EntryText {
  label: string;
  hint: string;
  disabled: boolean;
  tag?: string;
}

export function entryText(entry: PaletteEntry): EntryText {
  switch (entry.kind) {
    case 'action':
      return {
        label: entry.action.label,
        hint: entry.action.hint ?? '',
        disabled: !entry.action.allowed,
        tag: entry.action.rank === 'owner' ? t(rankKeys.owner) : undefined,
      };
    case 'player':
      return { label: entry.player.name, hint: t('ui.palette.player_hint', entry.player.id, entry.player.citizenid), disabled: false };
    case 'command':
      return { label: `/${entry.command.name}`, hint: entry.command.help ?? '', disabled: false };
    default: {
      const _exhaustive: never = entry;
      return _exhaustive;
    }
  }
}
