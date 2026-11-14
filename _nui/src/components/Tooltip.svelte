<script lang="ts">
  import type { Snippet } from 'svelte';

  let { label, side = 'top', children }: { label: string; side?: 'top' | 'right'; children: Snippet } = $props();
</script>

<span class="group/tip relative inline-flex">
  {@render children()}
  <span
    role="tooltip"
    class="pointer-events-none invisible absolute z-30 flex h-6.5 items-center rounded-md bg-foreground px-2 text-xs/4 font-medium whitespace-nowrap text-ink opacity-0 transition-opacity duration-150 ease-cobalt group-hover/tip:visible group-hover/tip:opacity-100 group-has-[:focus-visible]/tip:visible group-has-[:focus-visible]/tip:opacity-100 {side === 'top' ? 'bottom-full left-1/2 mb-2 -translate-x-1/2' : 'top-1/2 left-full ml-2 -translate-y-1/2'}"
  >
    {label}
  </span>
</span>
