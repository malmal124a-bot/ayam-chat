export function to6Hex(c: string): string {
  if (!c || typeof c !== 'string' || c.length < 4) return '#000000';
  if (c.length === 7) return c;
  if (c.length === 9) return '#' + c.substring(3, 9);
  if (c.length === 5) return '#' + c[1] + c[1] + c[2] + c[2] + c[3] + c[3];
  if (c.length === 4) return '#' + c[1] + c[1] + c[2] + c[2] + c[3] + c[3];
  return c;
}
