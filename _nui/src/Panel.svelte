<script lang="ts">
  import { untrack } from 'svelte';
  import Rail from './components/Rail.svelte';
  import { setAdmin, type Admin } from './lib/admin.svelte';
  import { escapeTopLayer } from './lib/layers.svelte';
  import { viewKey } from './lib/view';
  import ActionForm from './pages/ActionForm.svelte';
  import Ban from './pages/Ban.svelte';
  import Commands from './pages/Commands.svelte';
  import Home from './pages/Home.svelte';
  import PlayerDetail from './pages/PlayerDetail.svelte';
  import Players from './pages/Players.svelte';
  import Reports from './pages/Reports.svelte';
  import Server from './pages/Server.svelte';
  import Vehicles from './pages/Vehicles.svelte';
  import Warnings from './pages/Warnings.svelte';
  import World from './pages/World.svelte';

  let { admin }: { admin: Admin } = $props();

  setAdmin(untrack(() => admin));

  function isTyping(target: EventTarget | null): boolean {
    return target instanceof HTMLElement && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable);
  }

  function onkeydown(event: KeyboardEvent): void {
    if (event.key === 'Escape') {
      event.preventDefault();
      if (!escapeTopLayer()) admin.close();
    } else if (event.key === '/' && !isTyping(event.target) && admin.searchInput) {
      event.preventDefault();
      admin.searchInput.focus();
    }
  }

  const view = $derived(admin.view);
</script>

<svelte:window {onkeydown} />

<main class="fixed top-6 bottom-6 left-6 flex w-180 animate-enter overflow-clip rounded-lg border border-border bg-card text-xs/4 text-foreground">
  <Rail />
  {#key viewKey(view)}
    <div class="relative flex min-w-0 grow animate-fade flex-col">
      {#if view.page === 'home'}
        <Home />
      {:else if view.page === 'players'}
        <Players />
      {:else if view.page === 'player'}
        <PlayerDetail id={view.id} />
      {:else if view.page === 'ban'}
        <Ban target={view.target} />
      {:else if view.page === 'warnings'}
        <Warnings target={view.target} />
      {:else if view.page === 'form'}
        <ActionForm action={view.action} context={view.context} back={view.back} />
      {:else if view.page === 'vehicles'}
        <Vehicles />
      {:else if view.page === 'world'}
        <World />
      {:else if view.page === 'commands'}
        <Commands />
      {:else if view.page === 'server'}
        <Server />
      {:else if view.page === 'reports'}
        <Reports />
      {/if}
    </div>
  {/key}
</main>
