import type { NuiCallbacks, NuiMessage } from './types';

export type CallbackName = keyof NuiCallbacks;
export type CallbackArgs<K extends CallbackName> = NuiCallbacks[K]['args'];
export type CallbackResult<K extends CallbackName> = NuiCallbacks[K]['result'];

export type MockHandlers = { [K in CallbackName]: (args: CallbackArgs<K>) => CallbackResult<K> };

let mockHandlers: MockHandlers | null = null;

export const inGame = 'GetParentResourceName' in window;

export function installMock(handlers: MockHandlers): void {
  mockHandlers = handlers;
}

export async function nui<K extends CallbackName>(name: K, args: CallbackArgs<K>): Promise<CallbackResult<K> | null> {
  if (mockHandlers) return mockHandlers[name](args);
  try {
    const response = await fetch(`https://cobalt_adminmenu/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(args),
    });
    const body: CallbackResult<K> | null = await response.json();
    return body ?? null;
  } catch {
    return null;
  }
}

const messageActions = new Set<string>(['open', 'close', 'toggles', 'reports', 'staffChat', 'world']);

function isNuiMessage(value: unknown): value is NuiMessage {
  if (typeof value !== 'object' || value === null || !('action' in value)) return false;
  const { action } = value;
  if (typeof action !== 'string' || !messageActions.has(action)) return false;
  return action === 'close' || ('data' in value && typeof value.data === 'object' && value.data !== null);
}

export function onNuiMessage(handler: (message: NuiMessage) => void): () => void {
  const listener = (event: MessageEvent<unknown>) => {
    if (isNuiMessage(event.data)) handler(event.data);
  };
  window.addEventListener('message', listener);
  return () => window.removeEventListener('message', listener);
}
