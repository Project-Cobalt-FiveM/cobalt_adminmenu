<script lang="ts" module>
  export interface SelectOption {
    label: string;
    value: string | number;
    tag?: string;
    danger?: boolean;
    disabled?: boolean;
    separated?: boolean;
  }
</script>

<script lang="ts">
  import CaretDownIcon from 'phosphor-svelte/lib/CaretDownIcon';
  import CaretUpIcon from 'phosphor-svelte/lib/CaretUpIcon';
  import CheckSquareIcon from 'phosphor-svelte/lib/CheckSquareIcon';
  import { includesText } from '../lib/fuzzy';
  import { escapeLayer } from '../lib/layers.svelte';
  import { t } from '../lib/locale.svelte';
  import { motion } from '../lib/ui';

  interface Props {
    value: string | number | null;
    options: SelectOption[];
    onchange: (value: string | number) => void;
    placeholder?: string;
    menuWidth?: string;
    id?: string;
  }

  let { value, options, onchange, placeholder = t('ui.common.choose_one'), menuWidth = 'w-full', id }: Props = $props();

  const searchableFrom = 13;
  const listId = $props.id();

  let open = $state(false);
  let query = $state('');
  let active = $state(0);
  let root = $state<HTMLDivElement | undefined>();
  let trigger = $state<HTMLButtonElement | undefined>();

  const searchable = $derived(options.length >= searchableFrom);
  const selected = $derived(options.find((option) => option.value === value));
  const visible = $derived(options.filter((option) => includesText(query, option.label, option.value)));

  function close(): void {
    open = false;
    query = '';
    trigger?.focus();
  }

  function show(): void {
    open = true;
    active = visible.findIndex((option) => option.value === value);
  }

  escapeLayer(close, () => open);

  $effect(() => {
    if (!open) return;
    const onPointer = (event: MouseEvent) => {
      if (event.target instanceof Node && !root?.contains(event.target)) {
        open = false;
        query = '';
      }
    };
    document.addEventListener('mousedown', onPointer);
    return () => document.removeEventListener('mousedown', onPointer);
  });

  function choose(option: SelectOption | undefined): void {
    if (!option || option.disabled) return;
    onchange(option.value);
    close();
  }

  function onkeydown(event: KeyboardEvent): void {
    if (!open) {
      if (event.key === 'ArrowDown' || event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        show();
      }
      return;
    }
    if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
      event.preventDefault();
      const step = event.key === 'ArrowDown' ? 1 : -1;
      active = Math.min(visible.length - 1, Math.max(0, active + step));
    } else if (event.key === 'Enter') {
      event.preventDefault();
      choose(visible[active]);
    }
  }

  function filter(event: Event & { currentTarget: HTMLInputElement }): void {
    query = event.currentTarget.value;
    active = 0;
  }
</script>

<div bind:this={root} class="relative" role="presentation" {onkeydown}>
  <button
    bind:this={trigger}
    {id}
    type="button"
    aria-haspopup="listbox"
    aria-expanded={open}
    aria-controls={listId}
    onclick={() => (open ? close() : show())}
    class="flex h-9 w-full items-center justify-between gap-2 rounded-md border bg-card px-3 text-left outline-none {motion} {open
      ? 'border-cobalt shadow-[0_0_0_1px_#5078D7]'
      : 'border-input hover:bg-muted focus-visible:border-cobalt focus-visible:shadow-[0_0_0_1px_#5078D7]'}"
  >
    <span class="truncate text-sm/4.5 {selected ? 'text-foreground' : 'text-muted-foreground'}">{selected?.label ?? placeholder}</span>
    {#if open}
      <CaretUpIcon size={16} weight="fill" class="shrink-0 text-muted-foreground" />
    {:else}
      <CaretDownIcon size={16} weight="fill" class="shrink-0 text-muted-foreground" />
    {/if}
  </button>
  {#if open}
    <div class="absolute top-full left-0 z-40 mt-1.5 flex animate-rise flex-col rounded-lg border border-input bg-popover p-1 shadow-lg {menuWidth}">
      {#if searchable}
        <!-- svelte-ignore a11y_autofocus -->
        <input
          autofocus
          value={query}
          oninput={filter}
          placeholder={t('ui.select.filter')}
          aria-label={t('ui.select.filter_label')}
          class="mb-1 h-8 rounded-sm border border-input bg-card px-2 text-sm/4.5 text-foreground outline-none placeholder:text-muted-foreground focus-visible:border-cobalt"
        />
      {/if}
      <div id={listId} role="listbox" class="scroll-none flex max-h-96 flex-col overflow-y-auto">
        {#if visible.length === 0}
          <div class="flex h-8 items-center px-2 text-sm/4.5 text-muted-foreground">{t('ui.select.empty')}</div>
        {/if}
        {#each visible as option, index (option.value)}
          {@const isSelected = option.value === value}
          {#if option.separated}<div class="-mx-1 my-1 h-px shrink-0 bg-border"></div>{/if}
          <!-- svelte-ignore a11y_click_events_have_key_events -->
          <div
            role="option"
            tabindex="-1"
            aria-selected={isSelected}
            aria-disabled={option.disabled}
            onmouseenter={() => (active = index)}
            onmousedown={(event) => event.preventDefault()}
            onclick={() => choose(option)}
            class="flex h-8 shrink-0 items-center justify-between gap-2 rounded-sm px-2 {option.disabled ? 'cursor-not-allowed' : 'cursor-default'} {index === active || isSelected
              ? 'bg-secondary'
              : ''}"
          >
            <span class="truncate text-sm/4.5 {option.disabled ? 'text-muted-foreground' : option.danger ? 'text-destructive' : 'text-foreground'}">{option.label}</span>
            {#if isSelected}
              <CheckSquareIcon size={16} weight="fill" class="shrink-0 text-foreground" />
            {:else if option.tag}
              <span class="shrink-0 text-xs/4 text-muted-foreground">{option.tag}</span>
            {/if}
          </div>
        {/each}
      </div>
    </div>
  {/if}
</div>
