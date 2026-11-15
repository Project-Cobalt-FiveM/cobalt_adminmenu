<script lang="ts">
  import ActionTile from '../components/ActionTile.svelte';
  import Button from '../components/Button.svelte';
  import CommandPalette from '../components/CommandPalette.svelte';
  import Kbd from '../components/Kbd.svelte';
  import PageHeader from '../components/PageHeader.svelte';
  import ReportList from '../components/ReportList.svelte';
  import SearchField from '../components/SearchField.svelte';
  import SectionTitle from '../components/SectionTitle.svelte';
  import { getAdmin } from '../lib/admin.svelte';
  import { clock, plural } from '../lib/format';
  import { actionIcon } from '../lib/icons';
  import { escapeLayer } from '../lib/layers.svelte';
  import { t } from '../lib/locale.svelte';
  import { nui } from '../lib/nui';
  import { paletteEntries, type PaletteEntry } from '../lib/palette';
  import { readStrings, writeStrings } from '../lib/storage';
  import { fieldFocus, focusRing, motion } from '../lib/ui';

  const defaultPins = ['reviveSelf', 'teleportMarker', 'teleportBack', 'copyVector4', 'fixVehicle', 'refuelVehicle'];
  const characterToggles = ['noclip', 'godmode', 'invisible', 'names', 'blips', 'infiniteAmmo'];

  const admin = getAdmin();

  let query = $state('');
  let focused = $state(false);
  let active = $state(0);
  let pins = $state(readStrings('pins') ?? defaultPins);
  let draft = $state('');
  let sending = $state(false);

  const paletteOpen = $derived(focused && query.trim() !== '');
  const entries = $derived(paletteOpen ? paletteEntries(query, admin.boot.actions, admin.players, admin.commands ?? []) : []);
  const pinned = $derived(pins.flatMap((name) => admin.actions.get(name) ?? []));
  const recentChat = $derived(admin.staffChat.slice(-4).reverse());

  $effect(() => {
    admin.refreshPlayers();
    admin.loadCommands();
  });

  function setQuery(value: string): void {
    query = value;
    active = 0;
  }

  function dismiss(): void {
    setQuery('');
    admin.searchInput?.blur();
  }

  escapeLayer(dismiss, () => paletteOpen);

  function togglePin(name: string): void {
    pins = pins.includes(name) ? pins.filter((pin) => pin !== name) : [...pins, name];
    writeStrings('pins', pins);
  }

  function choose(entry: PaletteEntry | undefined): void {
    if (!entry) return;
    switch (entry.kind) {
      case 'action':
        if (!entry.action.allowed) return;
        dismiss();
        admin.openAction(entry.action, {});
        break;
      case 'player': {
        dismiss();
        const goto = admin.actions.get('goto');
        if (admin.isStaff) admin.navigate({ page: 'player', id: entry.player.id });
        else if (goto) admin.openAction(goto, { target: entry.player });
        break;
      }
      case 'command':
        dismiss();
        void nui('runCommand', { name: entry.command.name });
        break;
      default: {
        const _exhaustive: never = entry;
        return _exhaustive;
      }
    }
  }

  function onkeydown(event: KeyboardEvent): void {
    if (!paletteOpen) return;
    const current = entries[active];
    if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
      event.preventDefault();
      const step = event.key === 'ArrowDown' ? 1 : -1;
      active = Math.min(entries.length - 1, Math.max(0, active + step));
    } else if (event.key === 'Enter') {
      event.preventDefault();
      choose(current);
    } else if (event.key.toLowerCase() === 'p' && event.ctrlKey) {
      event.preventDefault();
      if (current?.kind === 'action') togglePin(current.action.name);
    }
  }

  async function sendChat(event: SubmitEvent): Promise<void> {
    event.preventDefault();
    const message = draft.trim();
    if (message === '' || sending) return;
    sending = true;
    const sent = await nui('sendStaffChat', { message });
    sending = false;
    if (sent) draft = '';
  }
</script>

<PageHeader title={t('ui.nav.home')} subtitle={t('ui.home.subtitle', plural(admin.boot.online, 'ui.common.players_one', 'ui.common.players_many'), admin.boot.staffOnDuty)}>
  {#snippet search()}
    <SearchField
      bind:value={() => query, setQuery}
      placeholder={t('ui.home.search')}
      active={paletteOpen}
      {onkeydown}
      onfocus={() => (focused = true)}
      onblur={() => (focused = false)}
    />
    {#if paletteOpen}
      <CommandPalette {entries} {active} pinned={(name) => pins.includes(name)} onhover={(index) => (active = index)} onchoose={choose} />
    {/if}
  {/snippet}
</PageHeader>

<div class="scroll-none flex grow flex-col gap-6 overflow-y-auto p-5">
  <section class="flex flex-col gap-2.5">
    <SectionTitle title={t('ui.home.character')} aside={t('ui.home.character_hint')} />
    <div class="grid grid-cols-3 gap-2">
      {#each characterToggles as name (name)}
        {#if name === 'noclip'}
          <ActionTile {name}>
            {#snippet hint()}
              <Kbd size="md">{admin.boot.keys.noclip}</Kbd>
            {/snippet}
          </ActionTile>
        {:else}
          <ActionTile {name} />
        {/if}
      {/each}
    </div>
  </section>

  <section class="flex flex-col gap-2.5">
    <SectionTitle title={t('ui.home.quick_actions')} aside={t('ui.home.quick_actions_hint')} />
    <div class="grid grid-cols-2 gap-2">
      {#each pinned as action (action.name)}
        {@const ActionIcon = actionIcon(action)}
        <button
          type="button"
          disabled={!action.allowed}
          onclick={() => admin.openAction(action, {})}
          class="flex h-10 min-w-0 items-center gap-2.5 rounded-md border px-3 text-left {focusRing} {motion} {action.allowed ? 'border-input bg-secondary hover:bg-input' : 'cursor-not-allowed border-muted bg-muted'}"
        >
          <ActionIcon size={16} weight="fill" class="shrink-0 text-muted-foreground" />
          <span class="min-w-0 grow truncate text-sm/5 font-medium {action.allowed ? 'text-foreground' : 'text-muted-foreground'}">{action.label}</span>
        </button>
      {/each}
    </div>
  </section>

  {#if admin.isStaff}
    <section class="flex flex-col gap-2.5">
      <SectionTitle title={t('ui.reports.open_reports')} aside={admin.receivingReports ? t('ui.home.reports_on') : t('ui.home.reports_off')} />
      <ReportList reports={admin.reports.slice(0, 3)} empty={t('ui.reports.none_open')} />
    </section>

    <section class="flex grow flex-col justify-end gap-2.5">
      <SectionTitle title={t('ui.home.staff_chat')} />
      <div class="flex flex-col gap-2">
        {#if recentChat.length === 0}
          <p class="text-13/4.5 text-muted-foreground">{t('ui.home.chat_empty')}</p>
        {/if}
        {#each recentChat as entry (`${entry.at}:${entry.name}:${entry.message}`)}
          <div class="flex gap-2">
            <span class="w-16 shrink-0 truncate text-13/4.5 font-medium text-foreground">{entry.name}</span>
            <span class="min-w-0 grow text-13/4.5 break-words text-muted-foreground">{entry.message}</span>
            <span class="shrink-0 text-xs/4.5 text-muted-foreground tabular-nums">{clock(entry.at)}</span>
          </div>
        {/each}
      </div>
      <form onsubmit={sendChat} class="flex gap-2">
        <input
          bind:value={draft}
          placeholder={t('ui.home.chat_placeholder')}
          aria-label={t('ui.home.chat_placeholder')}
          maxlength={250}
          class="h-9 min-w-0 grow rounded-md border border-input bg-card px-3 text-sm/4.5 text-foreground placeholder:text-muted-foreground {fieldFocus} {motion}"
        />
        <Button type="submit" size="lg">{t('ui.common.send')}</Button>
      </form>
    </section>
  {/if}
</div>
