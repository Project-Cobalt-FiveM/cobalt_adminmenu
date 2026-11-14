<script lang="ts" module>
  export type ButtonTone = 'secondary' | 'quiet' | 'primary' | 'danger';
  export type ButtonSize = 'xs' | 'sm' | 'row' | 'md' | 'field' | 'lg';
</script>

<script lang="ts">
  import type { Snippet } from 'svelte';
  import { focusRing, motion } from '../lib/ui';

  interface Props {
    tone?: ButtonTone;
    size?: ButtonSize;
    tag?: string;
    type?: 'button' | 'submit';
    disabled?: boolean;
    autofocus?: boolean;
    class?: string;
    onclick?: () => void;
    children: Snippet;
  }

  let { tone = 'secondary', size = 'md', tag, type = 'button', disabled = false, autofocus = false, class: extra = '', onclick, children }: Props = $props();

  const tones: Record<ButtonTone, string> = {
    secondary: 'bg-secondary border-input text-foreground hover:bg-input',
    quiet: 'bg-secondary border-input text-muted-foreground hover:bg-input hover:text-foreground',
    primary: 'bg-cobalt border-cobalt text-foreground hover:bg-cobalt-hover hover:border-cobalt-hover',
    danger: 'bg-destructive-solid border-destructive-solid text-foreground hover:bg-destructive-hover hover:border-destructive-hover',
  };

  const sizes: Record<ButtonSize, string> = {
    xs: 'h-7 px-2.5 text-xs/4',
    sm: 'h-7.5 px-3 text-xs/4',
    row: 'h-8 px-3 text-xs/4',
    md: 'h-8 px-3 text-13/4',
    field: 'h-9 px-3.5 text-13/4',
    lg: 'h-9 px-4 text-sm/4.5',
  };

  const look = $derived(disabled ? 'bg-muted border-muted text-muted-foreground cursor-not-allowed' : tones[tone]);
  const tagText = $derived(tone === 'secondary' || tone === 'quiet' || disabled ? 'text-muted-foreground' : 'text-foreground');
</script>

<!-- svelte-ignore a11y_autofocus --> 
<button
  {type}
  {disabled}
  {autofocus}
  {onclick}
  class="inline-flex shrink-0 items-center gap-2 rounded-md border font-medium whitespace-nowrap {sizes[size]} {look} {focusRing} {motion} {extra}"
>
  {@render children()}
  {#if tag}<span class="text-11/3.5 font-medium {tagText}">{tag}</span>{/if}
</button>
