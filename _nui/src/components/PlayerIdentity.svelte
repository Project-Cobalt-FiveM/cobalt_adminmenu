<script lang="ts">
  import { hoursMinutes, initials, lowerFirst } from '../lib/format';
  import { t } from '../lib/locale.svelte';
  import type { PlayerDetail } from '../lib/types';

  let { player, name, id }: { player: PlayerDetail | null; name: string; id: number } = $props();
</script>

<div class="flex items-center gap-3.5">
  <div class="flex size-12 shrink-0 items-center justify-center rounded-full bg-secondary">
    <span class="text-base/5 font-semibold text-foreground">{initials(name)}</span>
  </div>
  <div class="flex min-w-0 grow flex-col gap-0.5">
    <div class="flex items-center gap-2">
      <h1 class="truncate text-2xl/8 font-semibold tracking-[-0.02em] text-foreground">{name}</h1>
      <span class="h-5.5 shrink-0 rounded-sm bg-secondary px-2 text-xs/5.5 font-medium text-foreground tabular-nums">{t('ui.common.id', id)}</span>
    </div>
    <p class="h-4.5 text-13/4.5 text-muted-foreground tabular-nums">
      {#if player}{t('ui.players.identity', player.job, lowerFirst(player.grade), hoursMinutes(player.onlineSeconds))}{/if}
    </p>
  </div>
</div>
