<script lang="ts">
  import type { HTMLTextareaAttributes } from 'svelte/elements';
  import { fieldFocus, motion } from '../lib/ui';

  type Props = Omit<HTMLTextareaAttributes, 'value'> & { value: string };

  let { value = $bindable(), class: extra = '', ...rest }: Props = $props();
</script>

<textarea
  bind:value
  class="h-22 resize-none rounded-md border border-input bg-card px-3 py-2.5 text-sm/5 text-foreground placeholder:text-muted-foreground {fieldFocus} {motion} {extra}"
  {...rest}
></textarea>
