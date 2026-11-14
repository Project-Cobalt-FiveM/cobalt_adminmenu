<script lang="ts">
  import ActionButton from '../components/ActionButton.svelte';
  import ActionTile from '../components/ActionTile.svelte';
  import Button from '../components/Button.svelte';
  import Empty from '../components/Empty.svelte';
  import PageHeader from '../components/PageHeader.svelte';
  import SearchField from '../components/SearchField.svelte';
  import SectionTitle from '../components/SectionTitle.svelte';
  import Select from '../components/Select.svelte';
  import TextInput from '../components/TextInput.svelte';
  import { getAdmin } from '../lib/admin.svelte';
  import { includesText } from '../lib/fuzzy';
  import { escapeLayer } from '../lib/layers.svelte';
  import { t } from '../lib/locale.svelte';
  import type { Option } from '../lib/types';
  import { focusRing, motion } from '../lib/ui';

  const labelKinds = [
    { name: 'labelVehicles', label: 'ui.world.labels.vehicles' },
    { name: 'labelPeds', label: 'ui.world.labels.peds' },
    { name: 'labelObjects', label: 'ui.world.labels.objects' },
  ];

  const copyButtons = [
    { name: 'copyVector2', label: 'ui.world.copy.vector2' },
    { name: 'copyVector3', label: 'ui.world.copy.vector3' },
    { name: 'copyVector4', label: 'ui.world.copy.vector4' },
    { name: 'copyHeading', label: 'ui.world.copy.heading' },
    { name: 'copyEntity', label: 'ui.world.copy.entity' },
  ];

  const admin = getAdmin();
  const allowed = (name: string) => admin.actions.get(name)?.allowed === true;

  let query = $state('');
  let coords = $state('');
  let expanded = $state(false);

  $effect(() => admin.loadLists());
  $effect(() => {
    void admin.version;
    admin.refreshWorld();
  });

  escapeLayer(
    () => (expanded = false),
    () => expanded,
  );

  const pad = (value: number) => String(value).padStart(2, '0');

  const world = $derived(admin.world);
  const presets = $derived(admin.lists?.timePresets ?? []);
  const weatherLabel = $derived(world ? (admin.lists?.weatherTypes.find((option) => option.value === world.weather)?.label ?? world.weather) : null);
  const currentPreset = $derived.by(() => {
    if (!world) return undefined;
    const timed = presets.filter((preset) => typeof preset.value === 'number').sort((a, b) => Number(a.value) - Number(b.value));
    return timed.filter((preset) => Number(preset.value) <= world.hour).pop() ?? timed[timed.length - 1];
  });
  const searching = $derived(query.trim() !== '');
  const listOpen = $derived(expanded || searching);
  const locations = $derived((admin.lists?.locations ?? []).filter((location) => includesText(query, location.label)));

  function goToCoords(event: SubmitEvent): void {
    event.preventDefault();
    const text = coords.trim();
    if (text !== '') void admin.run('teleportCoords', { coords: text });
  }

  function goTo(location: Option): void {
    void admin.run('teleportLocation', { location: location.value });
  }
</script>

<PageHeader title={t('ui.nav.world')} subtitle={t('ui.world.subtitle')}>
  {#snippet search()}
    <SearchField bind:value={query} placeholder={t('ui.world.search')} />
  {/snippet}
</PageHeader>

<div class="scroll-none flex grow flex-col gap-6 overflow-y-auto p-5">
  <section class="flex flex-col gap-2.5">
    <SectionTitle title={t('ui.world.weather_time')} aside={world && weatherLabel ? t('ui.world.now', weatherLabel, `${pad(world.hour)}:${pad(world.minute)}`) : undefined} />
    <div class="flex gap-2">
      <div class="flex w-50 shrink-0 flex-col gap-1.5">
        <label for="world-weather" class="text-sm/4.5 font-medium text-foreground">{t('ui.world.weather')}</label>
        <Select
          id="world-weather"
          value={world?.weather ?? null}
          options={admin.lists?.weatherTypes ?? []}
          placeholder={t('ui.common.loading')}
          onchange={(weather) => allowed('setWeather') && void admin.run('setWeather', { weather })}
        />
      </div>
      <div class="flex min-w-0 grow flex-col gap-1.5">
        <span class="text-sm/4.5 font-medium text-foreground">{t('ui.world.time')}</span>
        <div role="radiogroup" aria-label={t('ui.world.time_of_day')} class="flex h-9 shrink-0 gap-0.5 rounded-md border border-input bg-card p-0.5">
          {#each presets as preset (preset.value)}
            {@const selected = preset.value === currentPreset?.value}
            <button
              type="button"
              role="radio"
              aria-checked={selected}
              disabled={!allowed('setTime')}
              onclick={() => void admin.run('setTime', { hour: preset.value })}
              class="flex min-w-0 grow items-center justify-center rounded-sm px-1 text-13/4 {focusRing} {motion} {selected ? 'bg-cobalt font-medium text-foreground' : 'text-muted-foreground hover:bg-muted hover:text-foreground'}"
            >
              {preset.label}
            </button>
          {/each}
        </div>
      </div>
    </div>
    <div class="flex gap-2">
      <ActionTile name="freezeTime" class="grow" />
      <ActionTile name="dynamicWeather" class="grow" />
      <ActionTile name="blackout" class="grow" />
    </div>
  </section>

  <section class="flex flex-col gap-2.5">
    <SectionTitle title={t('ui.world.teleport')} />
    <form onsubmit={goToCoords} class="flex gap-2">
      <TextInput bind:value={coords} placeholder={t('ui.world.coords_placeholder')} aria-label={t('ui.world.coords')} class="grow tabular-nums" />
      <Button type="submit" size="field" disabled={!allowed('teleportCoords')}>{t('ui.world.go_to_coords')}</Button>
    </form>
    {#if listOpen}
      <div class="flex animate-rise flex-col rounded-lg border border-border">
        <div class="flex h-9 shrink-0 items-center justify-between rounded-t-lg border-b border-border bg-muted px-3 text-xs/4 font-medium text-muted-foreground">
          <span>{searching ? t('ui.world.locations_matching', query.trim()) : t('ui.world.all_locations')}</span>
          {#if expanded && !searching}
            <button type="button" onclick={() => (expanded = false)} class="rounded-sm px-1 hover:text-foreground {focusRing}">{t('ui.world.show_fewer')}</button>
          {/if}
        </div>
        <div class="scroll-none flex max-h-72 flex-col overflow-y-auto">
          {#if locations.length === 0}<Empty text={t('ui.world.no_location')} />{/if}
          {#each locations as location (location.value)}
            <button
              type="button"
              disabled={!allowed('teleportLocation')}
              onclick={() => goTo(location)}
              class="flex h-10 shrink-0 items-center px-3 text-left text-sm/5 text-foreground hover:bg-muted {focusRing} {motion}"
            >
              {location.label}
            </button>
          {/each}
        </div>
      </div>
    {:else}
      <div class="flex flex-wrap gap-1.5">
        {#each admin.boot.quickLocations as location (location.value)}
          <Button disabled={!allowed('teleportLocation')} onclick={() => goTo(location)}>{location.label}</Button>
        {/each}
        <Button tone="quiet" onclick={() => (expanded = true)}>{t('ui.world.all_locations')}</Button>
      </div>
    {/if}
  </section>

  <section class="flex flex-col gap-2.5 border-t border-border pt-5">
    <SectionTitle title={t('ui.world.dev_tools')} aside={t('ui.world.dev_tools_hint')} />
    <div class="grid grid-cols-2 gap-2">
      <ActionTile name="coords" />
      <ActionTile name="entityLaser" />
      <ActionTile name="entityFreeAim" />
      <div class="flex h-11 items-center gap-2.5 rounded-md border border-border px-3">
        <span class="grow text-sm/4.5 font-medium text-foreground">{t('ui.world.label_nearby')}</span>
        <div class="flex gap-0.5">
          {#each labelKinds as { name, label } (name)}
            {@const on = admin.isOn(name)}
            <button
              type="button"
              role="switch"
              aria-checked={on}
              disabled={!allowed(name)}
              onclick={() => admin.setToggle(name, !on)}
              class="flex h-6 items-center rounded-sm px-2 text-xs/4 font-medium {focusRing} {motion} {on ? 'bg-cobalt text-foreground' : 'text-muted-foreground hover:bg-muted hover:text-foreground'}"
            >
              {t(label)}
            </button>
          {/each}
        </div>
      </div>
    </div>
    <div class="flex items-center gap-1.5">
      <span class="grow text-13/4 text-muted-foreground">{t('ui.world.copy_title')}</span>
      {#each copyButtons as { name, label } (name)}
        <ActionButton {name} label={t(label)} />
      {/each}
    </div>
  </section>
</div>
