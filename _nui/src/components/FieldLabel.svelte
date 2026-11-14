<script lang="ts">
  let { label, aside, for: htmlFor }: { label: string; aside?: string; for?: string } = $props();
</script>

<div class="flex justify-between">
  <label for={htmlFor} class="text-sm/5 font-medium text-foreground">{label}</label>
  {#if aside}<span class="text-xs/5 text-muted-foreground">{aside}</span>{/if}
</div>
