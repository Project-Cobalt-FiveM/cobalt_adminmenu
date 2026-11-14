<script lang="ts">
  import type { Snippet } from 'svelte';

  let { size = 'sm', children }: { size?: 'sm' | 'md'; children: Snippet } = $props();
</script>

<kbd class="inline-block shrink-0 rounded-sm border border-border bg-muted px-1.25 text-center font-sans font-normal text-foreground {size === 'md' ? 'h-5 min-w-5 text-xs/4.5' : 'h-4.5 text-11/4'}">
  {@render children()}
</kbd>
