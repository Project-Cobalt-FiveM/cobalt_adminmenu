const prefix = 'cobalt_adminmenu:';

export function readStrings(key: string): string[] | null {
  try {
    const raw = localStorage.getItem(prefix + key);
    if (raw == null) return null;
    const parsed: unknown = JSON.parse(raw);
    return Array.isArray(parsed) && parsed.every((entry) => typeof entry === 'string') ? parsed : null;
  } catch {
    return null;
  }
}

export function writeStrings(key: string, values: string[]): void {
  try {
    localStorage.setItem(prefix + key, JSON.stringify(values));
  } catch {
    return;
  }
}
