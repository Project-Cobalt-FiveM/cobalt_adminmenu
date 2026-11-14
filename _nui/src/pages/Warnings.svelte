<script lang="ts">
  import ActionButton from '../components/ActionButton.svelte';
  import Empty from '../components/Empty.svelte';
  import PlayerIdentity from '../components/PlayerIdentity.svelte';
  import SectionTitle from '../components/SectionTitle.svelte';
  import SubHeader from '../components/SubHeader.svelte';
  import { getAdmin, playerDetail } from '../lib/admin.svelte';
  import { clock, dayMonth, plural } from '../lib/format';
  import { escapeLayer } from '../lib/layers.svelte';
  import { t } from '../lib/locale.svelte';
  import { nui } from '../lib/nui';
  import type { Warning } from '../lib/types';
  import type { PlayerRef } from '../lib/view';

  let { target }: { target: PlayerRef } = $props();

  const admin = getAdmin();
  const detail = playerDetail(admin, () => target.id);
  let warnings = $state.raw<Warning[] | null>(null);

  const back = () => admin.navigate({ page: 'player', id: target.id });
  escapeLayer(back);

  $effect(() => {
    void admin.version;
    void nui('getWarnings', { id: target.id }).then((list) => (warnings = list ?? []));
  });
</script>

<SubHeader backLabel={target.name} onback={back}>
  <PlayerIdentity player={detail.current} name={target.name} id={target.id} />
</SubHeader>

<div class="scroll-none flex grow flex-col gap-3 overflow-y-auto p-5">
  <SectionTitle title={t('ui.warnings.title')} aside={warnings ? plural(warnings.length, 'ui.warnings.count_one', 'ui.warnings.count_many') : undefined} />
  <div class="flex flex-col rounded-lg border border-border">
    {#if warnings?.length === 0}<Empty text={t('ui.warnings.empty', target.name)} />{/if}
    {#each warnings ?? [] as warning, index (warning.id)}
      <div class="flex flex-col gap-1 px-3 py-2.5 {index === (warnings?.length ?? 0) - 1 ? '' : 'border-b border-border'}">
        <span class="text-sm/5 text-foreground">{warning.reason}</span>
        <span class="text-xs/4 text-muted-foreground tabular-nums">{t('ui.warnings.by', warning.by, dayMonth(warning.at), clock(warning.at))}</span>
      </div>
    {/each}
  </div>
  <div>
    <ActionButton name="warn" label={t('ui.warnings.add')} context={{ target }} />
  </div>
</div>
