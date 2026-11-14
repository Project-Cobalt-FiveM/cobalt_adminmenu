<script lang="ts">
  import type { HTMLInputAttributes } from 'svelte/elements';
  import { fieldFocus, motion } from '../lib/ui';

  type Props = Omit<HTMLInputAttributes, 'value'> & { value: string; ref?: HTMLInputElement | null };

  let { value = $bindable(), ref = $bindable(null), class: extra = '', ...rest }: Props = $props();
</script>

<input
  bind:this={ref}
  bind:value
  class="h-9 min-w-0 rounded-md border border-input bg-card px-3 text-sm/4.5 text-foreground placeholder:text-muted-foreground {fieldFocus} {motion} {extra}"
  {...rest}
/>
