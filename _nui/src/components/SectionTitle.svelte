<script lang="ts">
  let { title, aside, size = 'base' }: { title: string; aside?: string; size?: 'base' | 'sm' } = $props();
</script>

<div class="flex items-baseline justify-between gap-3">
  <h2 class="font-semibold text-foreground {size === 'base' ? 'text-base/6' : 'text-sm/5'}">{title}</h2>
  {#if aside}<div class="text-right text-xs/4 text-muted-foreground tabular-nums">{aside}</div>{/if}
</div>
