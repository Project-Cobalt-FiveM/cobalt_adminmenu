<script lang="ts">
  import TerminalIcon from 'phosphor-svelte/lib/TerminalIcon';
  import Empty from '../components/Empty.svelte';
  import PageHeader from '../components/PageHeader.svelte';
  import SearchField from '../components/SearchField.svelte';
  import { getAdmin } from '../lib/admin.svelte';
  import { plural } from '../lib/format';
  import { fuzzyFilter } from '../lib/fuzzy';
  import { t } from '../lib/locale.svelte';
  import { nui } from '../lib/nui';
  import { focusRing, motion } from '../lib/ui';

  const admin = getAdmin();

  let query = $state('');
  let active = $state(-1);

  $effect(() => admin.loadCommands());

  const shown = $derived(fuzzyFilter(admin.commands ?? [], query.replace(/^\//, ''), (command) => [command.name, command.help]));

  function setQuery(value: string): void {
    query = value;
    active = -1;
  }

  function runCommand(name: string): void {
    void nui('runCommand', { name });
  }

  function onkeydown(event: KeyboardEvent): void {
    if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
      event.preventDefault();
      const step = event.key === 'ArrowDown' ? 1 : -1;
      active = Math.min(shown.length - 1, Math.max(0, active + step));
    } else if (event.key === 'Enter') {
      const command = shown[Math.max(0, active)];
      if (command) runCommand(command.name);
    }
  }
</script>

<PageHeader title={t('ui.commands.title')} subtitle={admin.commands ? plural(admin.commands.length, 'ui.commands.count_one', 'ui.commands.count_many') : t('ui.commands.loading')}>
  {#snippet search()}
    <SearchField bind:value={() => query, setQuery} placeholder={t('ui.commands.search')} {onkeydown} />
  {/snippet}
</PageHeader>

<div class="scroll-none flex grow flex-col overflow-y-auto p-5">
  <div class="flex flex-col rounded-lg border border-border p-1">
    {#if admin.commands && shown.length === 0}
      <Empty text={query ? t('ui.commands.no_match', query) : t('ui.commands.empty')} />
    {/if}
    {#each shown as command, index (command.name)}
      <button
        type="button"
        onclick={() => runCommand(command.name)}
        onmouseenter={() => (active = index)}
        class="flex h-10 shrink-0 items-center gap-2.5 rounded-md px-2 text-left {focusRing} {motion} {index === active ? 'bg-secondary' : ''}"
      >
        <TerminalIcon size={16} weight="fill" class="shrink-0 {index === active ? 'text-cobalt' : 'text-muted-foreground'}" />
        <span class="shrink-0 text-sm/5 font-medium text-foreground">/{command.name}</span>
        <span class="min-w-0 grow truncate text-right text-xs/4 text-muted-foreground">{command.help ?? ''}</span>
      </button>
    {/each}
  </div>
</div>
