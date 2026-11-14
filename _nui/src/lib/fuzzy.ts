function subsequenceScore(text: string, query: string): number {
  let position = 0;
  let score = 0;
  let streak = 0;
  for (const char of query) {
    const found = text.indexOf(char, position);
    if (found < 0) return 0;
    streak = found === position ? streak + 1 : 0;
    const wordStart = found === 0 || text[found - 1] === ' ' || text[found - 1] === '_';
    score += 1 + streak + (wordStart ? 2 : 0);
    position = found + 1;
  }
  return score;
}

function fuzzyScore(query: string, ...fields: (string | undefined)[]): number {
  const needle = query.trim().toLowerCase();
  if (needle === '') return 1;
  let best = 0;
  for (const field of fields) {
    if (!field) continue;
    const haystack = field.toLowerCase();
    const index = haystack.indexOf(needle);
    const score = index === 0 ? 1000 : index > 0 ? 500 - index : subsequenceScore(haystack, needle);
    best = Math.max(best, score);
  }
  return best;
}

export function fuzzyFilter<T>(items: T[], query: string, fields: (item: T) => (string | undefined)[]): T[] {
  if (query.trim() === '') return items;
  return items
    .map((item) => ({ item, score: fuzzyScore(query, ...fields(item)) }))
    .filter((entry) => entry.score > 0)
    .sort((a, b) => b.score - a.score)
    .map((entry) => entry.item);
}

export function includesText(query: string, ...fields: (string | number | undefined)[]): boolean {
  const needle = query.trim().toLowerCase();
  if (needle === '') return true;
  return fields.some((field) => field != null && String(field).toLowerCase().includes(needle));
}
