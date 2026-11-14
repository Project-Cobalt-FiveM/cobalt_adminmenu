<script lang="ts">
  import ActionTile from '../components/ActionTile.svelte';
  import PageHeader from '../components/PageHeader.svelte';
  import ReportList from '../components/ReportList.svelte';
  import SearchField from '../components/SearchField.svelte';
  import SectionTitle from '../components/SectionTitle.svelte';
  import { getAdmin } from '../lib/admin.svelte';
  import { includesText } from '../lib/fuzzy';
  import { t } from '../lib/locale.svelte';

  const admin = getAdmin();

  let query = $state('');

  const shown = $derived(admin.reports.filter((report) => includesText(query, report.id, report.name, report.message, report.source)));
</script>

<PageHeader title={t('ui.reports.title')} subtitle={admin.reports.length === 0 ? t('ui.reports.none_open') : t('ui.reports.open_count', admin.reports.length)}>
  {#snippet search()}
    <SearchField bind:value={query} placeholder={t('ui.reports.search')} />
  {/snippet}
</PageHeader>

<div class="scroll-none flex grow flex-col gap-6 overflow-y-auto p-5">
  <ActionTile name="receiveReports" aside={admin.receivingReports ? t('ui.reports.receiving') : t('ui.reports.not_receiving')} />
  <section class="flex flex-col gap-2.5">
    <SectionTitle title={t('ui.reports.open_reports')} aside={query ? t('ui.common.filtered_count', shown.length, admin.reports.length) : undefined} />
    <ReportList reports={shown} withClose empty={query ? t('ui.reports.no_match', query) : t('ui.reports.empty')} />
  </section>
</div>
