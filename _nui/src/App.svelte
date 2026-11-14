<script lang="ts">
  import { Admin } from './lib/admin.svelte';
  import { nowSeconds } from './lib/format';
  import { setLocales } from './lib/locale.svelte';
  import { onNuiMessage } from './lib/nui';
  import Panel from './Panel.svelte';

  interface Session {
    admin: Admin;
    id: number;
  }

  let session = $state.raw<Session | null>(null);
  let visible = $state(false);

  $effect(() =>
    onNuiMessage((message) => {
      if (message.action === 'open') {
        setLocales(message.data.locales);
        session = { admin: new Admin(message.data, nowSeconds(), () => (visible = false)), id: (session?.id ?? 0) + 1 };
        visible = true;
      } else if (message.action === 'close') {
        visible = false;
      } else {
        session?.admin.receive(message);
      }
    }),
  );
</script>

{#if visible && session}
  {#key session.id}
    <Panel admin={session.admin} />
  {/key}
{/if}
