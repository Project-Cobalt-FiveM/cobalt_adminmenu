<script lang="ts">
  import ShieldIcon from 'phosphor-svelte/lib/ShieldIcon';
  import type { Snippet } from 'svelte';
  import { getAdmin } from '../lib/admin.svelte';
  import { t } from '../lib/locale.svelte';
  import { rankKeys } from '../lib/types';
  import CloseButton from './CloseButton.svelte';

  let { title, subtitle, search }: { title: string; subtitle: string; search?: Snippet } = $props();

  const admin = getAdmin();
</script>

<header class="relative z-20 flex shrink-0 flex-col gap-4 border-b border-border px-5 pt-5 pb-4">
  <div class="flex items-center gap-3">
    <div class="flex min-w-0 grow flex-col gap-0.5">
      <h1 class="truncate text-2xl/8 font-semibold tracking-[-0.02em] text-foreground">{title}</h1>
      <p class="text-xs/4 text-muted-foreground tabular-nums">{subtitle}</p>
    </div>
    <div class="flex h-6 shrink-0 items-center gap-1.5 rounded-sm bg-secondary px-2">
      <ShieldIcon size={14} weight="fill" class="text-muted-foreground" />
      <span class="text-xs/4 font-medium text-foreground">{t(rankKeys[admin.boot.rank])}</span>
    </div>
    <CloseButton />
  </div>
  {@render search?.()}
</header>
