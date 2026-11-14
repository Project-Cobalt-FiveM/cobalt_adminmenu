<script lang="ts">
  import TerminalIcon from 'phosphor-svelte/lib/TerminalIcon';
  import UserIcon from 'phosphor-svelte/lib/UserIcon';
  import { actionIcon, type Icon } from '../lib/icons';
  import { t } from '../lib/locale.svelte';
  import { entryText, groupKeys, type PaletteEntry } from '../lib/palette';
  import Kbd from './Kbd.svelte';

  interface Props {
    entries: PaletteEntry[];
    active: number;
    pinned: (name: string) => boolean;
    onhover: (index: number) => void;
    onchoose: (entry: PaletteEntry) => void;
  }

  let { entries, active, pinned, onhover, onchoose }: Props = $props();

  const activeEntry = $derived(entries[active]);

  function rowIcon(entry: PaletteEntry): Icon {
    if (entry.kind === 'action') return actionIcon(entry.action);
    return entry.kind === 'player' ? UserIcon : TerminalIcon;
  }
</script>

<div role="listbox" aria-label={t('ui.palette.results')} class="absolute top-[calc(100%-10px)] right-5 left-5 z-30 flex animate-rise flex-col rounded-lg border border-input bg-popover p-1 shadow-lg">
  {#if entries.length === 0}
    <div class="flex h-10 items-center px-2 text-sm/5 text-muted-foreground">{t('ui.palette.empty')}</div>
  {/if}
  {#each entries as entry, index (entry.key)}
    {@const startsGroup = entries[index - 1]?.kind !== entry.kind}
    {@const text = entryText(entry)}
    {@const isActive = index === active}
    {@const RowIcon = rowIcon(entry)}
    {#if startsGroup && index > 0}<div class="-mx-1 h-px shrink-0 bg-border"></div>{/if}
    {#if startsGroup}<div class="px-2 pt-2 pb-1 text-xs/4 font-medium text-muted-foreground">{t(groupKeys[entry.kind])}</div>{/if}
    <!-- svelte-ignore a11y_click_events_have_key_events -->
    <div
      {@attach (node) => {
        if (index === active) node.scrollIntoView({ block: 'nearest' });
      }}
      role="option"
      tabindex="-1"
      aria-selected={isActive}
      aria-disabled={text.disabled}
      onmouseenter={() => onhover(index)}
      onmousedown={(event) => event.preventDefault()}
      onclick={() => onchoose(entry)}
      class="flex h-10 shrink-0 items-center gap-2.5 rounded-md px-2 {isActive ? 'bg-secondary' : ''} {text.disabled ? 'cursor-not-allowed' : 'cursor-default'}"
    >
      <RowIcon size={16} weight="fill" class="shrink-0 {isActive && !text.disabled ? 'text-cobalt' : 'text-muted-foreground'}" />
      <span class="min-w-0 grow truncate text-sm/5 font-medium {text.disabled ? 'text-muted-foreground' : 'text-foreground'}">{text.label}</span>
      <span class="shrink-0 truncate text-xs/4 text-muted-foreground">{text.hint}</span>
      <span class="flex w-13 shrink-0 justify-end">
        {#if isActive && !text.disabled}
          <Kbd size="md">{t('ui.keys.enter')}</Kbd>
        {:else if text.tag}
          <span class="h-5 rounded-sm border border-input bg-secondary px-1.5 text-11/5 font-medium text-foreground">{text.tag}</span>
        {/if}
      </span>
    </div>
  {/each}
  <div class="flex gap-4 border-t border-border px-2 pt-2.5 pb-1.5 text-xs/4 text-muted-foreground">
    <span>{t('ui.palette.hint_move')}</span>
    <span>{t('ui.palette.hint_open')}</span>
    {#if activeEntry?.kind === 'action'}
      <span>{pinned(activeEntry.action.name) ? t('ui.palette.hint_unpin') : t('ui.palette.hint_pin')}</span>
    {/if}
  </div>
</div>
