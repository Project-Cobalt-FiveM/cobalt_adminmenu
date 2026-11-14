<script lang="ts">
  import CaretLeftIcon from 'phosphor-svelte/lib/CaretLeftIcon';
  import type { Snippet } from 'svelte';
  import { focusRing, motion } from '../lib/ui';
  import CloseButton from './CloseButton.svelte';

  let { backLabel, onback, children }: { backLabel: string; onback: () => void; children?: Snippet } = $props();
</script>

<header class="flex shrink-0 flex-col gap-3.5 border-b border-border px-5 py-4">
  <div class="flex items-center gap-2">
    <button
      type="button"
      onclick={onback}
      class="flex h-7 items-center gap-1 rounded-md pr-2 pl-1 text-muted-foreground hover:bg-muted hover:text-foreground {focusRing} {motion}"
    >
      <CaretLeftIcon size={16} weight="fill" />
      <span class="text-13/4 font-medium">{backLabel}</span>
    </button>
    <div class="grow"></div>
    <CloseButton />
  </div>
  {@render children?.()}
</header>
