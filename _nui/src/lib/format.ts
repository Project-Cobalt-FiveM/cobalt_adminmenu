import { t } from './locale.svelte';

const monthKeys = [
  'ui.time.months.jan',
  'ui.time.months.feb',
  'ui.time.months.mar',
  'ui.time.months.apr',
  'ui.time.months.may',
  'ui.time.months.jun',
  'ui.time.months.jul',
  'ui.time.months.aug',
  'ui.time.months.sep',
  'ui.time.months.oct',
  'ui.time.months.nov',
  'ui.time.months.dec',
];

export const nowSeconds = (): number => Math.floor(Date.now() / 1000);

export function money(amount: number): string {
  return `$${Math.round(amount).toLocaleString('en-US')}`;
}

export function plural(count: number, oneKey: string, manyKey: string): string {
  return t(count === 1 ? oneKey : manyKey, count);
}

export function hoursMinutes(seconds: number): string {
  const total = Math.max(0, Math.floor(seconds / 60));
  const hours = Math.floor(total / 60);
  return hours > 0 ? t('ui.time.hours_minutes', hours, total % 60) : t('ui.time.minutes_short', total);
}

export function minutesSeconds(seconds: number): string {
  const total = Math.max(0, Math.floor(seconds));
  const minutes = Math.floor(total / 60);
  return minutes > 0 ? t('ui.time.minutes_seconds', minutes, total % 60) : t('ui.time.seconds_short', total);
}

export function ago(at: number, now: number): string {
  const seconds = Math.max(0, now - at);
  if (seconds < 60) return t('ui.time.now');
  if (seconds < 3600) return t('ui.time.minutes_short', Math.floor(seconds / 60));
  if (seconds < 86400) return t('ui.time.hours_short', Math.floor(seconds / 3600));
  return t('ui.time.days_short', Math.floor(seconds / 86400));
}

const pad = (value: number): string => String(value).padStart(2, '0');

export function clock(at: number): string {
  const date = new Date(at * 1000);
  return `${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

export function dayMonth(at: number): string {
  const date = new Date(at * 1000);
  return t('ui.time.day_month', date.getDate(), t(monthKeys[date.getMonth()] ?? ''));
}

export function initials(name: string): string {
  const parts = name.trim().split(/\s+/);
  const first = parts[0]?.[0] ?? '';
  const last = parts.length > 1 ? (parts[parts.length - 1]?.[0] ?? '') : '';
  return (first + last).toUpperCase();
}

export function lowerFirst(text: string): string {
  return text.charAt(0).toLowerCase() + text.slice(1);
}

export function shortIdentifier(identifier: string): string {
  const colon = identifier.indexOf(':');
  const prefix = colon >= 0 ? identifier.slice(0, colon + 1) : '';
  const body = colon >= 0 ? identifier.slice(colon + 1) : identifier;
  return body.length > 10 ? `${prefix}${body.slice(0, 4)}…${body.slice(-4)}` : identifier;
}

export function listJoin(items: string[]): string {
  if (items.length <= 1) return items.join('');
  return t('ui.common.list_and', items.slice(0, -1).join(', '), items[items.length - 1] ?? '');
}
