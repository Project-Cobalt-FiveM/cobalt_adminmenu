<script lang="ts">
  import type { Snippet } from 'svelte';
  import { focusRing, motion } from '../lib/ui';

  interface Props {
    label: string;
    on: boolean;
    ontoggle: () => void;
    disabled?: boolean;
    hint?: Snippet;
    aside?: string;
    class?: string;
  }

  let { label, on, ontoggle, disabled = false, hint, aside, class: extra = '' }: Props = $props();
</script>

<button
  type="button"
  role="switch"
  aria-checked={on}
  {disabled}
  onclick={ontoggle}
  class="flex h-11 min-w-0 items-center gap-2.5 rounded-md border border-border px-3 text-left {on ? 'bg-muted' : 'bg-card hover:bg-muted'} {disabled ? 'cursor-not-allowed' : ''} {focusRing} {motion} {extra}"
>
  <span class="min-w-0 grow truncate text-sm/5 font-medium {disabled ? 'text-muted-foreground' : 'text-foreground'}">{label}</span>
  {#if aside}<span class="shrink-0 text-xs/4 text-muted-foreground">{aside}</span>{/if}
  {@render hint?.()}
  <span class="flex h-4.5 w-8 shrink-0 items-center rounded-full p-0.5 {motion} {on ? 'justify-end bg-foreground' : 'bg-secondary'}">
    <span class="size-3.5 shrink-0 rounded-full {on ? 'bg-ink' : 'bg-muted-foreground'}"></span>
  </span>
</button>
