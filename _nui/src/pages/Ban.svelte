<script lang="ts">
  import CheckSquareIcon from 'phosphor-svelte/lib/CheckSquareIcon';
  import ProhibitIcon from 'phosphor-svelte/lib/ProhibitIcon';
  import Button from '../components/Button.svelte';
  import FieldLabel from '../components/FieldLabel.svelte';
  import PlayerIdentity from '../components/PlayerIdentity.svelte';
  import Select, { type SelectOption } from '../components/Select.svelte';
  import SubHeader from '../components/SubHeader.svelte';
  import TextArea from '../components/TextArea.svelte';
  import { getAdmin, playerDetail } from '../lib/admin.svelte';
  import { clock, dayMonth, listJoin, nowSeconds, shortIdentifier } from '../lib/format';
  import { escapeLayer } from '../lib/layers.svelte';
  import { t } from '../lib/locale.svelte';
  import { rankKeys, type BanArgs } from '../lib/types';
  import { focusRing, motion } from '../lib/ui';
  import type { PlayerRef } from '../lib/view';

  type IdentifierKey = 'license' | 'discord' | 'steam';
  type Duration = number | 'permanent';

  const identifierRows: { key: IdentifierKey; label: string; inSentence: string }[] = [
    { key: 'license', label: 'ui.ban.identifiers.license', inSentence: 'ui.ban.identifiers.license_inline' },
    { key: 'discord', label: 'ui.ban.identifiers.discord', inSentence: 'ui.ban.identifiers.discord_inline' },
    { key: 'steam', label: 'ui.ban.identifiers.steam', inSentence: 'ui.ban.identifiers.steam_inline' },
  ];

  const rowShape = ['rounded-t-md border-b border-border', 'border-b border-border', 'rounded-b-md'];

  let { target }: { target: PlayerRef } = $props();

  const admin = getAdmin();
  const detail = playerDetail(admin, () => target.id);

  let reason = $state('');
  let duration = $state<Duration | null>(null);
  let by = $state<Record<IdentifierKey, boolean>>({ license: true, discord: true, steam: false });
  let confirming = $state(false);
  let sending = $state(false);

  const back = () => admin.navigate({ page: 'player', id: target.id });
  escapeLayer(back);
  escapeLayer(
    () => (confirming = false),
    () => confirming,
  );

  $effect(() => admin.loadLists());

  const identifiers = $derived(detail.current?.identifiers ?? {});
  const linked = (key: IdentifierKey) => identifiers[key] != null;
  const chosen = $derived(identifierRows.filter(({ key }) => by[key] && linked(key)));
  const durationOptions: SelectOption[] = $derived([
    ...(admin.lists?.banLengths ?? []).map((option) => ({ label: option.label, value: option.value })),
    { label: t('ui.ban.permanent'), value: 'permanent', danger: true, tag: t(rankKeys.owner), disabled: admin.boot.rank !== 'owner', separated: true },
  ]);
  const durationLabel = $derived(durationOptions.find((option) => option.value === duration)?.label ?? '');
  const ready = $derived(reason.trim() !== '' && duration != null && chosen.length > 0);

  const until = $derived(typeof duration === 'number' ? nowSeconds() + duration : null);
  const lengthText = $derived(until == null ? t('ui.ban.length_permanent') : t('ui.ban.length_for', durationLabel));
  const names = $derived(chosen.map(({ inSentence }) => t(inSentence)));
  const banned = $derived(
    names.length === 1 ? t('ui.ban.banned_one', names[0] ?? '') : t(names.length === 2 ? 'ui.ban.banned_both' : 'ui.ban.banned_all', listJoin(names)),
  );
  const kicked = $derived(until == null ? t('ui.ban.kicked_permanent', banned) : t('ui.ban.kicked_until', dayMonth(until), clock(until), banned));

  async function confirm(): Promise<void> {
    if (duration == null || sending) return;
    const args: BanArgs = {
      target: target.id,
      reason: reason.trim(),
      duration,
      license: by.license && linked('license'),
      discord: by.discord && linked('discord'),
      steam: by.steam && linked('steam'),
    };
    sending = true;
    const result = await admin.run('ban', { ...args });
    sending = false;
    if (result?.ok) admin.navigate({ page: 'players' });
    else confirming = false;
  }
</script>

<SubHeader backLabel={target.name} onback={back}>
  <PlayerIdentity player={detail.current} name={target.name} id={target.id} />
</SubHeader>

<div class="flex grow flex-col gap-5 p-5">
  <div class="flex flex-col gap-1">
    <h2 class="text-base/6 font-semibold text-foreground">{t('ui.ban.title')}</h2>
    <p class="text-13/4.5 text-muted-foreground">{t('ui.ban.description')}</p>
  </div>
  <div class="flex flex-col gap-1.5">
    <FieldLabel label={t('ui.ban.reason')} aside={t('ui.common.required')} for="ban-reason" />
    <!-- svelte-ignore a11y_autofocus -->
    <TextArea id="ban-reason" autofocus maxlength={250} bind:value={reason} placeholder={t('ui.ban.reason_placeholder')} />
  </div>
  <div class="flex flex-col gap-1.5">
    <FieldLabel label={t('ui.ban.duration')} for="ban-duration" />
    <Select
      id="ban-duration"
      value={duration}
      options={durationOptions}
      placeholder={t('ui.ban.duration_placeholder')}
      menuWidth="w-65"
      onchange={(value) => (duration = value === 'permanent' ? 'permanent' : Number(value))}
    />
  </div>
  <div class="flex flex-col gap-1.5">
    <span class="text-sm/5 font-medium text-foreground">{t('ui.ban.ban_by')}</span>
    <div class="flex flex-col rounded-md border border-border">
      {#each identifierRows as { key, label }, index (key)}
        {@const identifier = identifiers[key]}
        {@const checked = by[key] && identifier != null}
        <button
          type="button"
          role="checkbox"
          aria-checked={checked}
          disabled={identifier == null}
          onclick={() => (by[key] = !by[key])}
          class="flex h-10 shrink-0 items-center gap-2.5 px-3 text-left {rowShape[index]} {identifier == null ? 'cursor-not-allowed' : 'hover:bg-muted'} {focusRing} {motion}"
        >
          {#if checked}
            <CheckSquareIcon size={16} weight="fill" class="shrink-0 text-cobalt" />
          {:else}
            <span class="size-4 shrink-0 rounded-sm border border-input {identifier == null ? 'bg-muted' : 'bg-card'}"></span>
          {/if}
          <span class="grow text-sm/4.5 {identifier == null ? 'text-muted-foreground' : 'text-foreground'}">{t(label)}</span>
          <span class="text-xs/4 text-muted-foreground tabular-nums">{identifier ? shortIdentifier(identifier) : t('ui.ban.not_linked')}</span>
        </button>
      {/each}
    </div>
  </div>
  <div class="grow"></div>
  <div class="flex items-center gap-2 border-t border-border pt-4">
    <span class="grow text-xs/4 text-muted-foreground">{t('ui.ban.confirm_next')}</span>
    <Button size="lg" onclick={back}>{t('ui.common.cancel')}</Button>
    <Button size="lg" tone="primary" disabled={!ready} onclick={() => (confirming = true)}>{t('ui.ban.review')}</Button>
  </div>
</div>

{#if confirming}
  <div
    role="alertdialog"
    aria-modal="true"
    aria-labelledby="ban-confirm-title"
    class="absolute top-[30%] left-[calc(50%-24px)] z-50 flex w-115 -translate-x-1/2 animate-pop flex-col gap-5 rounded-lg border border-input bg-popover p-6 shadow-lg"
  >
    <div class="flex gap-3.5">
      <div class="flex size-10 shrink-0 items-center justify-center rounded-lg bg-destructive-solid">
        <ProhibitIcon size={20} weight="fill" class="text-foreground" />
      </div>
      <div class="flex flex-col gap-1.5">
        <h2 id="ban-confirm-title" class="text-base/6 font-semibold text-foreground">{t('ui.ban.confirm_title', target.name, lengthText)}</h2>
        <p class="text-sm/5 text-muted-foreground tabular-nums">{kicked}</p>
      </div>
    </div>
    <div class="flex flex-col gap-1 rounded-md border border-border bg-muted p-3">
      <span class="text-xs/4 text-muted-foreground">{t('ui.ban.reason_shown')}</span>
      <span class="text-sm/5 break-words text-foreground">{reason.trim()}</span>
    </div>
    <div class="flex justify-end gap-2">
      <Button size="lg" onclick={() => (confirming = false)}>{t('ui.common.go_back')}</Button>
      <Button size="lg" tone="danger" autofocus disabled={sending} onclick={confirm} class="focus-visible:ring-offset-popover">{t('ui.ban.confirm_button', lengthText)}</Button>
    </div>
  </div>
{/if}
