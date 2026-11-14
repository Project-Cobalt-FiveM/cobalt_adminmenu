import { nowSeconds } from './format';

export function ticker(intervalMs: number): { readonly now: number } {
  let now = $state(nowSeconds());
  $effect(() => {
    const timer = window.setInterval(() => (now = nowSeconds()), intervalMs);
    return () => window.clearInterval(timer);
  });
  return {
    get now() {
      return now;
    },
  };
}
