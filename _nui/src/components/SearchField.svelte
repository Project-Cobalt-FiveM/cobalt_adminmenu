<script lang="ts">
  import MagnifyingGlassIcon from 'phosphor-svelte/lib/MagnifyingGlassIcon';
  import { getAdmin } from '../lib/admin.svelte';
  import { t } from '../lib/locale.svelte';
  import { motion } from '../lib/ui';
  import Kbd from './Kbd.svelte';

  interface Props {
    value: string;
    placeholder: string;
    active?: boolean;
    onkeydown?: (event: KeyboardEvent) => void;
    onfocus?: () => void;
    onblur?: () => void;
  }

  let { value = $bindable(), placeholder, active = false, onkeydown, onfocus, onblur }: Props = $props();

  const admin = getAdmin();
</script>

<label class="flex h-10 shrink-0 items-center gap-2.5 rounded-md border bg-card px-3 {motion} {active ? 'border-cobalt shadow-[0_0_0_1px_#5078D7]' : 'border-input focus-within:border-cobalt'}">
  <MagnifyingGlassIcon size={16} weight="fill" class="shrink-0 text-muted-foreground" />
  <input
    bind:this={admin.searchInput}
    bind:value
    {onkeydown}
    {onfocus}
    {onblur}
    {placeholder}
    aria-label={placeholder}
    spellcheck={false}
    class="min-w-0 grow bg-transparent text-sm/5 text-foreground outline-none placeholder:text-muted-foreground"
  />
  <Kbd size="md">{active ? t('ui.keys.esc') : '/'}</Kbd>
</label>
