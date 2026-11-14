<script lang="ts">
  import type { Snippet } from 'svelte';
  import { getAdmin } from '../lib/admin.svelte';
  import ToggleTile from './ToggleTile.svelte';

  interface Props {
    name: string;
    label?: string;
    hint?: Snippet;
    aside?: string;
    class?: string;
  }

  let { name, label, hint, aside, class: extra }: Props = $props();

  const admin = getAdmin();
  const action = $derived(admin.actions.get(name));
  const on = $derived(admin.isOn(name));
</script>

{#if action}
  <ToggleTile label={label ?? action.label} {on} disabled={!action.allowed} {hint} {aside} class={extra} ontoggle={() => admin.setToggle(name, !on)} />
{/if}
