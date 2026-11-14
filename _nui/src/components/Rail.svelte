<script lang="ts">
  import CarIcon from 'phosphor-svelte/lib/CarIcon';
  import CodeIcon from 'phosphor-svelte/lib/CodeIcon';
  import FlagIcon from 'phosphor-svelte/lib/FlagIcon';
  import HardDrivesIcon from 'phosphor-svelte/lib/HardDrivesIcon';
  import HouseIcon from 'phosphor-svelte/lib/HouseIcon';
  import SunIcon from 'phosphor-svelte/lib/SunIcon';
  import UsersIcon from 'phosphor-svelte/lib/UsersIcon';
  import cobaltLogo from '../assets/cobalt-logo.svg';
  import { getAdmin } from '../lib/admin.svelte';
  import type { Icon } from '../lib/icons';
  import { t } from '../lib/locale.svelte';
  import { focusRing, motion } from '../lib/ui';
  import { navKeys, navPageOf, type NavPage } from '../lib/view';
  import Tooltip from './Tooltip.svelte';

  const navItems: { page: NavPage; icon: Icon }[] = [
    { page: 'home', icon: HouseIcon },
    { page: 'players', icon: UsersIcon },
    { page: 'vehicles', icon: CarIcon },
    { page: 'world', icon: SunIcon },
    { page: 'commands', icon: CodeIcon },
    { page: 'server', icon: HardDrivesIcon },
    { page: 'reports', icon: FlagIcon },
  ];

  const railKeys: Record<NavPage, string> = { ...navKeys, home: 'ui.nav.home_rail' };

  const admin = getAdmin();
  const current = $derived(navPageOf(admin.view));
</script>

<nav aria-label={t('ui.nav.label')} class="flex w-16 shrink-0 flex-col items-center gap-1 border-r border-border bg-background py-4">
  <img src={cobaltLogo} alt={t('ui.nav.logo')} class="size-7 shrink-0" />
  <div class="h-px w-8 shrink-0 bg-border"></div>
  <div class="flex flex-col items-center gap-1 pt-2">
    {#each navItems as { page, icon: NavIcon } (page)}
      {@const active = page === current}
      <Tooltip label={t(railKeys[page])} side="right">
        <button
          type="button"
          aria-label={t(railKeys[page])}
          aria-current={active ? 'page' : undefined}
          onclick={() => admin.navigate({ page })}
          class="group relative flex size-10 shrink-0 items-center justify-center rounded-md border {focusRing} {motion} {active
            ? 'border-cobalt bg-cobalt'
            : 'border-background bg-background hover:border-border hover:bg-muted'}"
        >
          <NavIcon size={20} weight="fill" class={active ? 'text-foreground' : 'text-muted-foreground group-hover:text-foreground'} />
          {#if page === 'reports' && admin.reports.length > 0}
            <span class="absolute top-1 right-1 h-4 min-w-4 rounded-lg bg-foreground px-1 text-center text-10/4 font-semibold text-ink tabular-nums">
              {admin.reports.length}
            </span>
          {/if}
        </button>
      </Tooltip>
    {/each}
  </div>
</nav>
