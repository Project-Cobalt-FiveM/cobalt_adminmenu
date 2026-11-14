<script lang="ts">
  import { getAdmin } from '../lib/admin.svelte';
  import { ago } from '../lib/format';
  import { ticker } from '../lib/clock.svelte';
  import { t } from '../lib/locale.svelte';
  import type { Report } from '../lib/types';
  import { focusRing } from '../lib/ui';
  import ActionButton from './ActionButton.svelte';
  import Empty from './Empty.svelte';

  let { reports, withClose = false, empty }: { reports: Report[]; withClose?: boolean; empty: string } = $props();

  const admin = getAdmin();
  const clock = ticker(15000);
</script>

<div class="flex flex-col overflow-clip rounded-lg border border-border">
  {#if reports.length === 0}<Empty text={empty} />{/if}
  {#each reports as report, index (report.id)}
    <div class="flex items-center gap-3 p-3 {index === reports.length - 1 ? '' : 'border-b border-border'}">
      <span class="w-10 shrink-0 text-13/4 font-semibold text-muted-foreground tabular-nums">#{report.id}</span>
      <button type="button" onclick={() => admin.navigate({ page: 'player', id: report.source })} class="flex min-w-0 grow flex-col gap-0.5 rounded-sm text-left {focusRing}">
        <span class="truncate text-sm/5 font-medium text-foreground hover:underline">{report.name}</span>
        <span class="line-clamp-1 text-13/4.5 text-muted-foreground">{report.message}</span>
      </button>
      <span class="w-10 shrink-0 text-right text-xs/4 text-muted-foreground tabular-nums">{ago(report.at, clock.now)}</span>
      <div class="flex shrink-0 gap-1.5">
        <ActionButton name="reportGoto" label={t('ui.reports.go_to')} size="row" context={{ preset: { report: report.id } }} />
        <ActionButton name="reportReply" label={t('ui.reports.reply')} size="row" context={{ report: report.id }} />
        {#if withClose}<ActionButton name="reportClose" label={t('ui.common.close')} size="row" context={{ preset: { report: report.id } }} />{/if}
      </div>
    </div>
  {/each}
</div>
