<script lang="ts">
  import ActionButton from '../components/ActionButton.svelte';
  import ActionTile from '../components/ActionTile.svelte';
  import Button from '../components/Button.svelte';
  import Empty from '../components/Empty.svelte';
  import PageHeader from '../components/PageHeader.svelte';
  import SearchField from '../components/SearchField.svelte';
  import SectionTitle from '../components/SectionTitle.svelte';
  import TextInput from '../components/TextInput.svelte';
  import { getAdmin } from '../lib/admin.svelte';
  import { includesText } from '../lib/fuzzy';
  import { t } from '../lib/locale.svelte';
  import { nui } from '../lib/nui';
  import { readStrings, writeStrings } from '../lib/storage';
  import type { CurrentVehicle, VehicleModel } from '../lib/types';
  import { focusRing, motion } from '../lib/ui';

  const recentKey = 'recentVehicles';
  const recentLimit = 12;
  const listLimit = 60;
  const recent = 'Recent';
  const plateActions = ['openTrunk', 'markInGarage', 'markOut'];

  const admin = getAdmin();
  const spawn = admin.actions.get('spawnVehicle');

  let vehicle = $state.raw<CurrentVehicle | null>(null);
  let query = $state('');
  let category = $state(recent);
  let recentModels = $state(readStrings(recentKey) ?? []);
  let plate = $state('');
  let plateInput = $state<HTMLInputElement | null>(null);

  $effect(() => admin.loadLists());

  $effect(() => {
    void admin.version;
    let live = true;
    void nui('getVehicle', {}).then((current) => {
      if (live) vehicle = current;
    });
    return () => {
      live = false;
    };
  });

  const models = $derived(admin.lists?.vehicles ?? []);
  const searching = $derived(query.trim() !== '');
  const categories = $derived([recent, ...new Set(models.map((model) => model.category))]);
  const shown: VehicleModel[] = $derived.by(() => {
    if (searching) return models.filter((model) => includesText(query, model.name, model.model, model.category));
    if (category === recent) return recentModels.map((name) => models.find((model) => model.model === name) ?? { model: name, name, category: '' });
    return models.filter((model) => model.category === category);
  });
  const listed = $derived(shown.slice(0, listLimit));
  const emptyText = $derived(searching ? t('ui.vehicles.no_match', query) : category === recent ? t('ui.vehicles.recent_empty') : t('ui.vehicles.category_empty'));
  const owner = $derived(vehicle?.owner ? t('ui.vehicles.owned_by', vehicle.owner) : t('ui.vehicles.not_owned'));
  const cleanPlate = $derived(plate.trim().toUpperCase());

  function spawnModel(model: string): void {
    recentModels = [model, ...recentModels.filter((entry) => entry !== model)].slice(0, recentLimit);
    writeStrings(recentKey, recentModels);
    void admin.run('spawnVehicle', { model });
  }

  function runPlate(name: string): void {
    if (cleanPlate === '') plateInput?.focus();
    else void admin.run(name, { plate: cleanPlate });
  }
</script>

<PageHeader title={t('ui.nav.vehicles')} subtitle={vehicle ? t('ui.vehicles.driving', vehicle.label) : t('ui.vehicles.on_foot')}>
  {#snippet search()}
    <SearchField bind:value={query} placeholder={t('ui.vehicles.search')} />
  {/snippet}
</PageHeader>

<div class="scroll-none flex grow flex-col gap-6 overflow-y-auto p-5">
  {#if vehicle}
    <div class="flex flex-col rounded-lg border border-border">
      <div class="flex items-center gap-3 border-b border-border px-4 py-3.5">
        <div class="flex min-w-0 grow flex-col gap-0.5">
          <span class="truncate text-base/6 font-semibold text-foreground">{vehicle.label}</span>
          <span class="truncate text-xs/4 text-muted-foreground tabular-nums">{t('ui.vehicles.details', owner, vehicle.model, vehicle.netId)}</span>
        </div>
        <span class="flex h-7 shrink-0 items-center rounded-sm border border-input bg-card px-2.5 text-13/4 font-semibold tracking-[0.04em] text-foreground tabular-nums">{vehicle.plate}</span>
      </div>
      <div class="flex gap-6 px-4 py-3.5">
        {@render meter(t('ui.vehicles.engine'), vehicle.engine / 10, String(Math.round(vehicle.engine)), false)}
        {@render meter(t('ui.vehicles.body'), vehicle.body / 10, String(Math.round(vehicle.body)), false)}
        {@render meter(t('ui.vehicles.fuel'), vehicle.fuel, `${Math.round(vehicle.fuel)}%`, vehicle.fuel < 20)}
      </div>
      <div class="flex flex-wrap gap-1.5 px-4 pb-4">
        <ActionButton name="fixVehicle" label={t('ui.vehicles.fix')} />
        <ActionButton name="refuelVehicle" label={t('ui.vehicles.refuel')} />
        <ActionButton name="maxMods" />
        <ActionButton name="changePlate" />
        <ActionButton name="saveVehicle" />
        <div class="grow"></div>
        <ActionButton name="deleteVehicle" label={t('ui.common.delete')} />
      </div>
    </div>
  {/if}

  <section class="flex flex-col gap-2.5">
    <SectionTitle title={t('ui.vehicles.spawn_title')} aside={t('ui.vehicles.spawn_hint')} />
    <div class="flex flex-wrap gap-1.5" role="tablist" aria-label={t('ui.vehicles.categories')}>
      {#each categories as name (name)}
        {@const selected = !searching && name === category}
        <button
          type="button"
          role="tab"
          aria-selected={selected}
          onclick={() => (category = name)}
          class="flex h-7.5 items-center rounded-md border px-2.5 text-13/4 font-medium text-foreground {focusRing} {motion} {selected ? 'border-cobalt bg-cobalt' : 'border-input bg-secondary hover:bg-input'}"
        >
          {name === recent ? t('ui.vehicles.recent') : name}
        </button>
      {/each}
    </div>
    <div class="flex flex-col rounded-lg border border-border">
      {#if shown.length === 0}<Empty text={emptyText} />{/if}
      {#each listed as model, index (model.model)}
        <div class="flex h-12 shrink-0 items-center gap-3 px-3 {index === listed.length - 1 ? '' : 'border-b border-border'}">
          <span class="min-w-0 grow truncate text-sm/4.5 font-medium text-foreground">{model.name}</span>
          <span class="w-30 shrink-0 truncate text-xs/4 text-muted-foreground">{model.model}</span>
          <span class="w-22.5 shrink-0 truncate text-xs/4 text-muted-foreground">{model.category}</span>
          <Button size="sm" disabled={!spawn?.allowed} onclick={() => spawnModel(model.model)}>{t('ui.vehicles.spawn')}</Button>
        </div>
      {/each}
    </div>
  </section>

  <section class="flex flex-col gap-2.5">
    <SectionTitle title={t('ui.vehicles.plate_title')} />
    <div class="flex gap-2">
      <TextInput bind:ref={plateInput} bind:value={() => plate, (value) => (plate = value.toUpperCase())} maxlength={8} placeholder={t('ui.vehicles.plate')} aria-label={t('ui.vehicles.plate')} class="w-45 shrink-0 tabular-nums" />
      {#each plateActions as name (name)}
        {@const action = admin.actions.get(name)}
        {#if action}
          <Button size="field" disabled={!action.allowed} onclick={() => runPlate(name)}>{action.label}</Button>
        {/if}
      {/each}
    </div>
  </section>

  <ActionTile name="vehicleDev" aside={t('ui.vehicles.dev_hint')} />
</div>

{#snippet meter(label: string, value: number, display: string, warn: boolean)}
  <div class="flex grow basis-0 flex-col gap-1.5">
    <div class="flex justify-between text-xs/4">
      <span class="text-muted-foreground">{label}</span>
      <span class="tabular-nums {warn ? 'text-warning' : 'text-foreground'}">{display}</span>
    </div>
    <div class="flex h-1.5 shrink-0 rounded-full bg-secondary">
      <div class="h-1.5 rounded-full transition-[width] duration-300 ease-cobalt {warn ? 'bg-warning' : 'bg-foreground'}" style:width="{Math.min(100, Math.max(0, value))}%"></div>
    </div>
  </div>
{/snippet}
