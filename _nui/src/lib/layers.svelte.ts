type Layer = { escape: () => void };

const stack: Layer[] = [];

export function escapeLayer(onEscape: () => void, active: () => boolean = () => true): void {
  $effect(() => {
    if (!active()) return;
    const layer: Layer = { escape: onEscape };
    stack.push(layer);
    return () => {
      const index = stack.lastIndexOf(layer);
      if (index >= 0) stack.splice(index, 1);
    };
  });
}

export function escapeTopLayer(): boolean {
  const top = stack[stack.length - 1];
  if (!top) return false;
  top.escape();
  return true;
}
