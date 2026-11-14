<script lang="ts">
  import { getAdmin } from '../lib/admin.svelte';
  import { t } from '../lib/locale.svelte';
  import { focusRing, motion } from '../lib/ui';
  import Kbd from './Kbd.svelte';

  const admin = getAdmin();
</script>

<button
  type="button"
  onclick={admin.close}
  class="flex h-8 shrink-0 items-center gap-1.5 rounded-md border border-input bg-secondary px-2 hover:bg-input {focusRing} {motion}"
>
  <span class="text-xs/4 text-muted-foreground">{t('ui.common.close')}</span>
  <Kbd>{t('ui.keys.esc')}</Kbd>
</button>
