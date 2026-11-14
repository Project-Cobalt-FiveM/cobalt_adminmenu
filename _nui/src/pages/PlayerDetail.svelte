<script lang="ts">
  import CaretRightIcon from 'phosphor-svelte/lib/CaretRightIcon';
  import ActionButton from '../components/ActionButton.svelte';
  import Button from '../components/Button.svelte';
  import PlayerIdentity from '../components/PlayerIdentity.svelte';
  import SectionTitle from '../components/SectionTitle.svelte';
  import SubHeader from '../components/SubHeader.svelte';
  import { getAdmin, playerDetail } from '../lib/admin.svelte';
  import { dayMonth, lowerFirst, money } from '../lib/format';
  import { escapeLayer } from '../lib/layers.svelte';
  import { t } from '../lib/locale.svelte';
  import type { PlayerDetail } from '../lib/types';
  import { focusRing, motion } from '../lib/ui';
  import type { ActionContext } from '../lib/view';

  let { id }: { id: number } = $props();

  const admin = getAdmin();
  const detail = playerDetail(admin, () => id);
  let pranksOpen = $state(false);

  const back = () => admin.navigate({ page: 'players' });
  escapeLayer(back);

  const player = $derived(detail.current);
  const name = $derived(player?.name ?? admin.players.find((row) => row.id === id)?.name ?? t('ui.players.fallback_name', id));
  const context: ActionContext = $derived({ target: { id, name } });

  const groups: { title: string; actions: string[] }[] = [
    { title: 'ui.players.groups.move', actions: ['goto', 'bring', 'spectate', 'intoVehicle', 'setBucket'] },
    { title: 'ui.players.groups.health', actions: ['revive', 'freeze', 'cuff', 'removeStress', 'mute', 'kill'] },
    { title: 'ui.players.groups.character', actions: ['setJob', 'setGang', 'setDuty', 'setPed', 'clothing', 'openInventory', 'giveItem', 'clearInventory'] },
    { title: 'ui.players.groups.money', actions: ['giveMoney', 'removeMoney', 'giveCar', 'spawnTheirVehicle', 'fixTheirVehicle'] },
  ];

  const pranks = ['drunk', 'playSound', 'setOnFire', 'explode'];

  function stats(detail: PlayerDetail): [string, string][] {
    const { count, last } = detail.warnings;
    const warnings = count === 0 ? t('ui.common.none') : last != null ? t('ui.players.warnings_last', count, dayMonth(last)) : String(count);
    const gang = detail.gang ? (detail.gangGrade ? t('ui.players.gang_grade', detail.gang, lowerFirst(detail.gangGrade)) : detail.gang) : t('ui.common.none');
    return [
      [t('ui.players.stats.citizenid'), detail.citizenid],
      [t('ui.players.stats.cash'), money(detail.cash)],
      [t('ui.players.stats.bank'), money(detail.bank)],
      [t('ui.players.stats.phone'), detail.phone ?? t('ui.common.none')],
      [t('ui.players.stats.gang'), gang],
      [t('ui.players.stats.warnings'), warnings],
    ];
  }
</script>

<SubHeader backLabel={t('ui.nav.players')} onback={back}>
  <PlayerIdentity {player} {name} {id} />
</SubHeader>

<div class="scroll-none flex grow flex-col gap-5 overflow-y-auto px-5 pt-4 pb-5">
  {#if player}
    <dl class="grid grid-cols-3 overflow-clip rounded-lg border border-border">
      {#each stats(player) as [label, value], index (label)}
        <div class="flex min-w-0 flex-col gap-0.5 px-3 py-2.5 {index < 3 ? 'border-b border-border' : ''} {index % 3 < 2 ? 'border-r border-border' : ''}">
          <dt class="text-xs/4 text-muted-foreground">{label}</dt>
          <dd class="truncate text-sm/5 font-medium text-foreground tabular-nums">{value}</dd>
        </div>
      {/each}
    </dl>
  {:else}
    <div class="h-30 rounded-lg border border-border"></div>
  {/if}

  {#each groups as group (group.title)}
    <section class="flex flex-col gap-2">
      <SectionTitle size="sm" title={t(group.title)} />
      <div class="flex flex-wrap gap-1.5">
        {#each group.actions as name (name)}
          {#if name === 'setBucket'}
            <ActionButton {name} {context}>
              <span class="text-muted-foreground tabular-nums">{player?.bucket ?? 0}</span>
            </ActionButton>
          {:else if name === 'freeze'}
            <ActionButton {name} {context} label={player?.frozen ? t('ui.players.unfreeze') : t('ui.players.freeze')} />
          {:else}
            <ActionButton {name} {context} />
          {/if}
        {/each}
      </div>
    </section>
  {/each}

  <div class="flex flex-col rounded-md border border-border">
    <button
      type="button"
      aria-expanded={pranksOpen}
      onclick={() => (pranksOpen = !pranksOpen)}
      class="flex h-10 shrink-0 items-center gap-2 rounded-md px-3 text-left hover:bg-muted {focusRing} {motion}"
    >
      <CaretRightIcon size={16} weight="fill" class="shrink-0 text-muted-foreground transition-transform duration-200 ease-cobalt {pranksOpen ? 'rotate-90' : ''}" />
      <span class="grow text-sm/5 font-medium text-foreground">{t('ui.players.pranks')}</span>
      <span class="text-xs/4 text-muted-foreground">{t('ui.players.pranks_hint')}</span>
    </button>
    {#if pranksOpen}
      <div class="flex animate-rise flex-wrap gap-1.5 px-3 pt-1 pb-3">
        {#each pranks as name (name)}
          <ActionButton {name} {context} />
        {/each}
      </div>
    {/if}
  </div>

  <section class="flex flex-col gap-2 border-t border-border pt-4">
    <SectionTitle size="sm" title={t('ui.players.moderation')} aside={t('ui.players.moderation_hint')} />
    <div class="flex flex-wrap gap-1.5">
      <ActionButton name="warn" {context} />
      <Button onclick={() => admin.navigate({ page: 'warnings', target: { id, name } })}>{t('ui.players.view_warnings')}</Button>
      <ActionButton name="setPermission" {context} />
      <div class="grow"></div>
      <ActionButton name="kick" {context} />
      <ActionButton name="ban" {context} />
    </div>
  </section>
</div>
