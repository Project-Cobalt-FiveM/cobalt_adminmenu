<script lang="ts">
  import type { Snippet } from 'svelte';
  import { getAdmin } from '../lib/admin.svelte';
  import { t } from '../lib/locale.svelte';
  import { rankKeys } from '../lib/types';
  import type { ActionContext } from '../lib/view';
  import Button, { type ButtonSize } from './Button.svelte';

  interface Props {
    name: string;
    context?: ActionContext;
    label?: string;
    size?: ButtonSize;
    children?: Snippet;
  }

  let { name, context = {}, label, size = 'md', children }: Props = $props();

  const admin = getAdmin();
  const action = $derived(admin.actions.get(name));
</script>

{#if action}
  <Button
    {size}
    tone={action.danger ? 'danger' : 'secondary'}
    disabled={!action.allowed}
    tag={action.rank === 'owner' ? t(rankKeys.owner) : undefined}
    onclick={() => admin.openAction(action, context)}
  >
    {label ?? action.label}
    {@render children?.()}
  </Button>
{/if}
