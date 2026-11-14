<script lang="ts">
  import ArrowLineDownIcon from 'phosphor-svelte/lib/ArrowLineDownIcon';
  import CaretRightIcon from 'phosphor-svelte/lib/CaretRightIcon';
  import EyeIcon from 'phosphor-svelte/lib/EyeIcon';
  import HeartIcon from 'phosphor-svelte/lib/HeartIcon';
  import NavigationArrowIcon from 'phosphor-svelte/lib/NavigationArrowIcon';
  import Empty from '../components/Empty.svelte';
  import PageHeader from '../components/PageHeader.svelte';
  import SearchField from '../components/SearchField.svelte';
  import Tooltip from '../components/Tooltip.svelte';
  import { getAdmin } from '../lib/admin.svelte';
  import { minutesSeconds, nowSeconds } from '../lib/format';
  import { includesText } from '../lib/fuzzy';
  import type { Icon } from '../lib/icons';
  import { t } from '../lib/locale.svelte';
  import { ticker } from '../lib/clock.svelte';
  import type { PlayerRow } from '../lib/types';
  import { focusRing, motion } from '../lib/ui';

  type Filter = 'all' | 'nearby' | 'down' | 'duty' | 'staff';

  const nearbyMeters = 100;

  const filters: { key: Filter; label: string; test: (player: PlayerRow) => boolean }[] = [
    { key: 'all', label: 'ui.players.filters.all', test: () => true },
    { key: 'nearby', label: 'ui.players.filters.nearby', test: (player) => player.distance <= nearbyMeters },
    { key: 'down', label: 'ui.players.filters.down', test: (player) => player.down },
    { key: 'duty', label: 'ui.players.filters.duty', test: (player) => player.onDuty },
    { key: 'staff', label: 'ui.players.filters.staff', test: (player) => player.staff },
  ];

  const quickActions: { name: string; tip: string; icon: Icon }[] = [
    { name: 'goto', tip: 'ui.players.quick.goto', icon: NavigationArrowIcon },
    { name: 'bring', tip: 'ui.players.quick.bring', icon: ArrowLineDownIcon },
    { name: 'revive', tip: 'ui.players.quick.revive', icon: HeartIcon },
    { name: 'spectate', tip: 'ui.players.quick.spectate', icon: EyeIcon },
  ];

  const admin = getAdmin();
  const clock = ticker(1000);

  let query = $state('');
  let filter = $state<Filter>('all');
  let selected = $state<number | null>(null);

  $effect(() => {
    void admin.version;
    admin.refreshPlayers();
    const timer = window.setInterval(admin.refreshPlayers, 5000);
    return () => window.clearInterval(timer);
  });

  const sorted = $derived([...admin.players].sort((a, b) => a.id - b.id));
  const test = $derived(filters.find((entry) => entry.key === filter)?.test ?? (() => true));
  const visible = $derived(sorted.filter((player) => test(player) && includesText(query, player.name, player.id, player.citizenid)));

  function open(id: number): void {
    admin.navigate({ page: 'player', id });
  }

  function onkeydown(event: KeyboardEvent): void {
    if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
      event.preventDefault();
      const index = visible.findIndex((player) => player.id === selected);
      const next = event.key === 'ArrowDown' ? Math.min(visible.length - 1, index + 1) : Math.max(0, index - 1);
      selected = visible[next]?.id ?? null;
    } else if (event.key === 'Enter') {
      const target = visible.find((player) => player.id === selected) ?? (visible.length === 1 ? visible[0] : undefined);
      if (target) open(target.id);
    }
  }
</script>

<PageHeader title={t('ui.nav.players')} subtitle={t('ui.players.subtitle', admin.players.length)}>
  {#snippet search()}
    <SearchField bind:value={query} placeholder={t('ui.players.search')} {onkeydown} />
  {/snippet}
</PageHeader>

<div class="scroll-none flex grow flex-col gap-3 overflow-y-auto px-5 pt-4 pb-5">
  <div class="flex items-center gap-1.5" role="tablist" aria-label={t('ui.players.filter_label')}>
    {#each filters as entry (entry.key)}
      {@const isSelected = filter === entry.key}
      <button
        type="button"
        role="tab"
        aria-selected={isSelected}
        onclick={() => (filter = entry.key)}
        class="flex h-8 items-center gap-1.5 rounded-md border px-3 text-13/4 font-medium {focusRing} {motion} {isSelected ? 'border-cobalt bg-cobalt text-foreground' : 'border-input bg-secondary text-foreground hover:bg-input'}"
      >
        {t(entry.label)}
        <span class="tabular-nums {isSelected ? 'text-foreground' : 'text-muted-foreground'}">{sorted.filter(entry.test).length}</span>
      </button>
    {/each}
  </div>
  <div class="flex flex-col rounded-lg border border-border">
    <div class="flex h-9 shrink-0 items-center gap-3 rounded-t-lg border-b border-border bg-muted px-3 text-xs/4 font-medium text-muted-foreground">
      <span class="w-9 shrink-0">{t('ui.players.columns.id')}</span>
      <span class="grow">{t('ui.players.columns.player')}</span>
      <span class="w-33 shrink-0">{t('ui.players.columns.job')}</span>
      <span class="w-44 shrink-0 text-right">{t('ui.home.quick_actions')}</span>
    </div>
    {#if visible.length === 0}
      <Empty text={query ? t('ui.players.no_match', query) : t('ui.players.empty')} />
    {/if}
    {#each visible as player, index (player.id)}
      {@const isSelected = player.id === selected}
      {@const sub = isSelected ? 'text-foreground' : 'text-muted-foreground'}
      {@const target = { id: player.id, name: player.name }}
      <!-- svelte-ignore a11y_click_events_have_key_events, a11y_no_static_element_interactions -->
      <div
        onclick={() => (selected = player.id)}
        ondblclick={() => open(player.id)}
        class="flex h-14 shrink-0 items-center gap-3 px-3 {index === visible.length - 1 ? 'rounded-b-lg' : 'border-b border-border'} {motion} {isSelected ? 'bg-cobalt' : 'hover:bg-muted'}"
      >
        <span class="w-9 shrink-0 text-13/4 font-semibold tabular-nums {sub}">{player.id}</span>
        <div class="flex min-w-0 grow flex-col gap-0.5">
          <span class="truncate text-sm/5 font-medium text-foreground">{player.name}</span>
          <span class="text-xs/4 {sub}">{player.citizenid}</span>
        </div>
        <div class="flex w-33 shrink-0 flex-col gap-0.5">
          <span class="truncate text-13/4.5 text-foreground">{player.job}</span>
          <span class="truncate text-xs/4 tabular-nums {sub}">
            {#if player.down}
              <span class="text-destructive">●</span> {t('ui.players.down_for', minutesSeconds(clock.now - (player.downSince ?? nowSeconds())))}
            {:else}
              {player.grade}
            {/if}
          </span>
        </div>
        <div class="flex w-44 shrink-0 justify-end gap-1">
          {#each quickActions as { name, tip, icon } (name)}
            {@const action = admin.actions.get(name)}
            {@render rowButton(t(tip), icon, isSelected, !action?.allowed, () => action && admin.openAction(action, { target }))}
          {/each}
          {@render rowButton(t('ui.players.quick.details'), CaretRightIcon, isSelected, false, () => open(player.id))}
        </div>
      </div>
    {/each}
  </div>
</div>

{#snippet rowButton(tip: string, ButtonIcon: Icon, rowSelected: boolean, disabled: boolean, run: () => void)}
  <Tooltip label={tip}>
    <button
      type="button"
      aria-label={tip}
      {disabled}
      onclick={(event) => {
        event.stopPropagation();
        run();
      }}
      class="flex size-8 shrink-0 items-center justify-center rounded-md {focusRing} {motion} {disabled
        ? 'cursor-not-allowed bg-muted text-input'
        : rowSelected
          ? 'bg-cobalt-hover text-foreground hover:bg-secondary'
          : 'bg-muted text-muted-foreground hover:bg-secondary hover:text-foreground'}"
    >
      <ButtonIcon size={16} weight="fill" />
    </button>
  </Tooltip>
{/snippet}
