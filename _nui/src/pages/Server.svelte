<script lang="ts">
  import ActionButton from '../components/ActionButton.svelte';
  import Button from '../components/Button.svelte';
  import Empty from '../components/Empty.svelte';
  import PageHeader from '../components/PageHeader.svelte';
  import SearchField from '../components/SearchField.svelte';
  import SectionTitle from '../components/SectionTitle.svelte';
  import TextInput from '../components/TextInput.svelte';
  import { getAdmin } from '../lib/admin.svelte';
  import { hoursMinutes, plural } from '../lib/format';
  import { includesText } from '../lib/fuzzy';
  import { ticker } from '../lib/clock.svelte';
  import { t } from '../lib/locale.svelte';
  import { nui } from '../lib/nui';
  import type { Resource, ResourceState } from '../lib/types';

  type ResourceCommand = 'start' | 'stop' | 'restart';

  const pendingLabels: Record<ResourceCommand, string> = { start: 'ui.server.states.starting', stop: 'ui.server.states.stopping', restart: 'ui.server.states.restarting' };

  const stateLook: Record<ResourceState, { label: string; dot: string; text: string }> = {
    started: { label: 'ui.server.states.started', dot: 'bg-success', text: 'text-foreground' },
    starting: { label: 'ui.server.states.starting', dot: 'bg-warning', text: 'text-foreground' },
    stopping: { label: 'ui.server.states.stopping', dot: 'bg-warning', text: 'text-foreground' },
    stopped: { label: 'ui.server.states.stopped', dot: 'bg-muted-foreground', text: 'text-muted-foreground' },
    missing: { label: 'ui.server.states.missing', dot: 'bg-destructive', text: 'text-muted-foreground' },
    uninitialized: { label: 'ui.server.states.uninitialized', dot: 'bg-muted-foreground', text: 'text-muted-foreground' },
    unknown: { label: 'ui.server.states.unknown', dot: 'bg-muted-foreground', text: 'text-muted-foreground' },
  };

  const admin = getAdmin();
  const clock = ticker(30000);
  const announce = admin.actions.get('announce');
  const canControl = admin.actions.get('resource')?.allowed === true;

  let query = $state('');
  let message = $state('');
  let resources = $state.raw<Resource[] | null>(null);
  let pending = $state<Record<string, ResourceCommand>>({});

  const uptime = $derived(admin.boot.uptime + (clock.now - admin.openedAt));
  const list = $derived(resources ?? []);
  const started = $derived(list.filter((resource) => resource.state === 'started').length);
  const stopped = $derived(list.filter((resource) => resource.state === 'stopped').length);
  const shown = $derived(list.filter((resource) => includesText(query, resource.name, resource.description)));

  $effect(() => {
    void admin.version;
    let live = true;
    const load = () =>
      void nui('getResources', {}).then((rows) => {
        if (!live || !rows) return;
        resources = rows;
        pending = {};
      });
    load();
    const follow = window.setTimeout(load, 1500);
    return () => {
      live = false;
      window.clearTimeout(follow);
    };
  });

  function send(name: string, state: ResourceCommand): void {
    pending[name] = state;
    void admin.run('resource', { name, state });
  }

  async function submit(event: SubmitEvent): Promise<void> {
    event.preventDefault();
    const text = message.trim();
    if (text === '' || !announce?.allowed) return;
    const result = await admin.run('announce', { message: text });
    if (result?.ok) message = '';
  }

  function busyLabel(resource: Resource): string | null {
    const command = pending[resource.name];
    if (command) return t(pendingLabels[command]);
    return resource.state === 'starting' || resource.state === 'stopping' ? t(stateLook[resource.state].label) : null;
  }
</script>

<PageHeader title={t('ui.nav.server')} subtitle={t('ui.server.subtitle', admin.boot.build, hoursMinutes(uptime))}>
  {#snippet search()}
    <SearchField bind:value={query} placeholder={t('ui.server.search')} />
  {/snippet}
</PageHeader>

<div class="scroll-none flex grow flex-col gap-6 overflow-y-auto p-5">
  <section class="flex flex-col gap-2.5">
    <SectionTitle title={t('ui.server.announcement')} aside={t('ui.server.announcement_hint', plural(admin.boot.online, 'ui.common.players_one', 'ui.common.players_many'))} />
    <form onsubmit={submit} class="flex gap-2">
      <TextInput bind:value={message} maxlength={200} placeholder={t('ui.server.announcement_placeholder')} aria-label={t('ui.server.announcement')} class="grow" />
      <Button type="submit" size="lg" tone="primary" disabled={!announce?.allowed}>{t('ui.server.announce')}</Button>
    </form>
  </section>

  <section class="flex flex-col gap-2.5">
    <SectionTitle title={t('ui.server.everyone')} />
    <div class="flex flex-wrap gap-1.5">
      <ActionButton name="reviveAll" />
      <ActionButton name="reviveRadius" />
      <ActionButton name="giveItemAll" label={t('ui.server.give_item_all')} />
      <ActionButton name="giveMoneyAll" label={t('ui.server.give_money_all')} />
      <div class="grow"></div>
      <ActionButton name="kickAll" />
    </div>
  </section>

  <section class="flex flex-col gap-2.5">
    <SectionTitle title={t('ui.server.tools')} aside={t('ui.server.tools_hint')} />
    <div class="flex flex-wrap gap-1.5">
      <ActionButton name="unban" />
      <ActionButton name="openStash" />
      <div class="grow"></div>
      <ActionButton name="clearInventoryOffline" />
    </div>
  </section>

  <section class="flex flex-col gap-2.5">
    <SectionTitle title={t('ui.server.resources')} aside={resources ? t('ui.server.resource_counts', started, stopped) : undefined} />
    <div class="flex flex-col rounded-lg border border-border">
      <div class="flex h-9 shrink-0 items-center gap-3 rounded-t-lg border-b border-border bg-muted px-3 text-xs/4 font-medium text-muted-foreground">
        <span class="grow">{t('ui.server.columns.name')}</span>
        <span class="w-16 shrink-0">{t('ui.server.columns.version')}</span>
        <span class="w-24 shrink-0">{t('ui.server.columns.state')}</span>
        <span class="w-40 shrink-0 text-right">{t('ui.palette.actions')}</span>
      </div>
      {#if resources && shown.length === 0}
        <Empty text={query ? t('ui.server.no_match', query) : t('ui.server.empty')} />
      {/if}
      {#each shown as resource, index (resource.name)}
        {@const look = stateLook[resource.state]}
        {@const busy = busyLabel(resource)}
        <div class="flex h-12 shrink-0 items-center gap-3 px-3 {index === shown.length - 1 ? '' : 'border-b border-border'}">
          <div class="flex min-w-0 grow flex-col">
            <span class="truncate text-sm/5 font-medium text-foreground">{resource.name}</span>
            {#if resource.description}<span class="truncate text-xs/4 text-muted-foreground">{resource.description}</span>{/if}
          </div>
          <span class="w-16 shrink-0 truncate text-xs/4 text-muted-foreground tabular-nums">{resource.version ?? ''}</span>
          <span class="flex w-24 shrink-0 items-center gap-1.5">
            <span class="size-1.5 shrink-0 rounded-full {look.dot}"></span>
            <span class="text-13/4 {look.text}">{t(look.label)}</span>
          </span>
          <div class="flex w-40 shrink-0 justify-end gap-1">
            {#if busy}
              <span class="flex h-7 items-center rounded-md bg-muted px-2.5 text-xs/4 font-medium text-muted-foreground">{busy}</span>
            {:else if resource.state === 'started'}
              <Button size="xs" disabled={!canControl} onclick={() => send(resource.name, 'restart')}>{t('ui.server.restart')}</Button>
              <Button size="xs" disabled={!canControl} onclick={() => send(resource.name, 'stop')}>{t('ui.server.stop')}</Button>
            {:else}
              <Button size="xs" disabled={!canControl || resource.state === 'missing'} onclick={() => send(resource.name, 'start')}>{t('ui.server.start')}</Button>
            {/if}
          </div>
        </div>
      {/each}
    </div>
  </section>
</div>
