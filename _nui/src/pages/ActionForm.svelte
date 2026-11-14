<script lang="ts">
  import { untrack } from 'svelte';
  import Button from '../components/Button.svelte';
  import FieldLabel from '../components/FieldLabel.svelte';
  import PlayerIdentity from '../components/PlayerIdentity.svelte';
  import Select from '../components/Select.svelte';
  import SubHeader from '../components/SubHeader.svelte';
  import TextArea from '../components/TextArea.svelte';
  import TextInput from '../components/TextInput.svelte';
  import { contextArgs, getAdmin, playerDetail } from '../lib/admin.svelte';
  import { escapeLayer } from '../lib/layers.svelte';
  import { t } from '../lib/locale.svelte';
  import type { Action, Field, Option } from '../lib/types';
  import { navKeys, navPageOf, type ActionContext, type View } from '../lib/view';

  type Values = Record<string, string | number>;

  let { action, context, back }: { action: Action; context: ActionContext; back: View } = $props();

  const admin = getAdmin();
  const detail = playerDetail(admin, () => context.target?.id);

  let values = $state<Values>(untrack(() => ({ ...context.preset })));
  let sending = $state(false);

  const goBack = () => admin.navigate(back);
  escapeLayer(goBack);

  const fields = $derived((action.fields ?? []).filter((field) => !(field.key === 'target' && context.target)));
  const needsLists = $derived(fields.some((field) => field.list != null && field.list !== 'playerVehicles'));
  const needsPlayers = $derived(fields.some((field) => field.key === 'target'));
  const ready = $derived(fields.every((field) => field.optional || isFilled(field, values[field.key])));
  const backLabel = $derived(context.target && (back.page === 'player' || back.page === 'warnings') ? context.target.name : t(navKeys[navPageOf(back)]));

  $effect(() => {
    if (needsLists) admin.loadLists();
    if (needsPlayers) admin.refreshPlayers();
  });

  function optionsFor(field: Field): Option[] {
    if (field.key === 'target') return admin.players.map((row) => ({ label: t('ui.form.player_option', row.name, row.id), value: row.id }));
    if (!field.list) return [];
    const lists = admin.lists;
    switch (field.list) {
      case 'playerVehicles':
        return detail.current?.vehicles ?? [];
      case 'grades': {
        const parent = field.dependsOn;
        const source = parent === 'gang' ? lists?.gangs : lists?.jobs;
        const chosen = parent != null ? values[parent] : undefined;
        return source?.find((option) => option.value === chosen)?.grades ?? [];
      }
      case 'vehicles':
        return (lists?.vehicles ?? []).map((vehicle) => ({ label: vehicle.name, value: vehicle.model }));
      case 'items':
      case 'jobs':
      case 'gangs':
      case 'peds':
      case 'locations':
      case 'accounts':
      case 'sounds':
      case 'ranks':
      case 'weatherTypes':
      case 'timePresets':
        return lists?.[field.list] ?? [];
      default: {
        const _exhaustive: never = field.list;
        return _exhaustive;
      }
    }
  }

  function isFilled(field: Field, value: string | number | undefined): boolean {
    if (value == null || String(value).trim() === '') return false;
    return field.kind !== 'number' || Number.isFinite(Number(value));
  }

  function toArgs(): Record<string, unknown> {
    const args: Record<string, unknown> = {};
    for (const field of fields) {
      const value = values[field.key];
      if (value == null || String(value).trim() === '') continue;
      args[field.key] = field.kind === 'number' ? Number(value) : typeof value === 'string' ? value.trim() : value;
    }
    return args;
  }

  function setValue(key: string, value: string | number): void {
    values[key] = value;
    for (const field of fields) if (field.dependsOn === key) delete values[field.key];
  }

  function text(key: string): string {
    const value = values[key];
    return value == null ? '' : String(value);
  }

  function selectPlaceholder(field: Field, options: Option[]): string {
    if (field.key === 'target') return t('ui.form.choose_player');
    return field.dependsOn && options.length === 0 ? t('ui.form.choose_parent_first', field.dependsOn) : t('ui.form.choose_field', field.label.toLowerCase());
  }

  async function submit(event: SubmitEvent): Promise<void> {
    event.preventDefault();
    if (!ready || sending) return;
    const args = { ...contextArgs(context), ...toArgs() };
    if (action.name === 'ban') {
      const id = Number(args.target);
      const row = admin.players.find((entry) => entry.id === id);
      admin.navigate({ page: 'ban', target: { id, name: row?.name ?? t('ui.players.fallback_name', id) } });
      return;
    }
    sending = true;
    const result = await admin.run(action.name, args);
    sending = false;
    if (result?.ok) goBack();
  }
</script>

<SubHeader {backLabel} onback={goBack}>
  {#if context.target}
    <PlayerIdentity player={detail.current} name={context.target.name} id={context.target.id} />
  {/if}
</SubHeader>

<form onsubmit={submit} class="scroll-none flex grow flex-col gap-5 overflow-y-auto p-5">
  <div class="flex flex-col gap-1">
    <h2 class="text-base/6 font-semibold text-foreground">{action.label}</h2>
    {#if action.hint}<p class="text-13/4.5 text-muted-foreground">{action.hint}</p>{/if}
  </div>
  {#each fields as field, index (field.key)}
    {@const id = `field-${field.key}`}
    {@const autofocus = index === 0}
    <div class="flex flex-col gap-1.5">
      <FieldLabel label={field.key === 'target' ? t('ui.players.columns.player') : field.label} aside={field.optional ? t('ui.common.optional') : t('ui.common.required')} for={id} />
      {#if field.key === 'target' || field.kind === 'select'}
        {@const options = optionsFor(field)}
        <Select {id} value={values[field.key] ?? null} {options} placeholder={selectPlaceholder(field, options)} onchange={(value) => setValue(field.key, value)} />
      {:else if field.kind === 'textarea'}
        <!-- svelte-ignore a11y_autofocus -->
        <TextArea {id} {autofocus} maxlength={250} placeholder={field.placeholder} bind:value={() => text(field.key), (value) => setValue(field.key, value)} />
      {:else if field.kind === 'number'}
        <!-- svelte-ignore a11y_autofocus -->
        <TextInput
          {id}
          {autofocus}
          inputmode="decimal"
          class="tabular-nums"
          placeholder={field.placeholder}
          bind:value={() => text(field.key), (value) => setValue(field.key, value.replace(/[^\d.-]/g, ''))}
        />
      {:else}
        <!-- svelte-ignore a11y_autofocus -->
        <TextInput {id} {autofocus} placeholder={field.placeholder} bind:value={() => text(field.key), (value) => setValue(field.key, value)} />
      {/if}
    </div>
  {/each}
  <div class="grow"></div>
  <div class="flex items-center justify-end gap-2 border-t border-border pt-4">
    <Button size="lg" onclick={goBack}>{t('ui.common.cancel')}</Button>
    <Button type="submit" size="lg" tone={action.danger ? 'danger' : 'primary'} disabled={!ready || sending}>{action.label}</Button>
  </div>
</form>
