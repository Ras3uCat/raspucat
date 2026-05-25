// Shared slot-generation logic used by get-available-slots and create-booking.
// Times in availability_rules are stored as local owner times (e.g., "09:00:00").
// OWNER_TIMEZONE env var controls interpretation (default: America/Chicago).

import { createClient } from 'jsr:@supabase/supabase-js@2';

export const SLOT_DURATION_MS = 30 * 60 * 1000;
export const BUFFER_MS = 30 * 60 * 1000;

function getOwnerTz(): string {
  return Deno.env.get('OWNER_TIMEZONE') ?? 'America/Chicago';
}

// Returns the UTC offset in minutes for the owner timezone at a given UTC instant.
// e.g., CDT (UTC-5) returns -300.
function utcOffsetMinutes(atUtc: Date, tz: string): number {
  const utcStr = atUtc.toLocaleString('en-US', { timeZone: 'UTC' });
  const localStr = atUtc.toLocaleString('en-US', { timeZone: tz });
  return (new Date(localStr).getTime() - new Date(utcStr).getTime()) / 60000;
}

// Converts an owner-timezone time string ("HH:MM") on a calendar date to a UTC Date.
export function localToUtc(dateStr: string, timeStr: string): Date {
  const tz = getOwnerTz();
  const pretendUtc = new Date(`${dateStr}T${timeStr}:00Z`);
  const offset = utcOffsetMinutes(pretendUtc, tz);
  return new Date(pretendUtc.getTime() - offset * 60000);
}

// Returns 0 (Sun) – 6 (Sat) for the calendar date in the owner's timezone.
export function dayOfWeekInOwnerTz(dateStr: string): number {
  const tz = getOwnerTz();
  const d = new Date(`${dateStr}T12:00:00Z`);
  const label = new Intl.DateTimeFormat('en-US', { timeZone: tz, weekday: 'short' }).format(d);
  return ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].indexOf(label);
}

// Formats a UTC Date as a human-readable string in the owner's timezone.
export function formatInOwnerTz(date: Date): string {
  const tz = getOwnerTz();
  return new Intl.DateTimeFormat('en-US', {
    timeZone: tz,
    weekday: 'long',
    month: 'long',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
    timeZoneName: 'short',
  }).format(date);
}

export interface BusyRange {
  from: number;
  to: number;
}

// Returns available 30-min slot start times (UTC Date objects) for a given calendar date.
export async function getAvailableSlots(
  supabase: ReturnType<typeof createClient>,
  dateStr: string,
): Promise<Date[]> {
  const dow = dayOfWeekInOwnerTz(dateStr);

  const { data: rules } = await supabase
    .from('availability_rules')
    .select('start_time, end_time')
    .eq('day_of_week', dow)
    .eq('is_active', true);

  if (!rules || rules.length === 0) return [];

  // Generate all 30-min slot starts within each rule window
  const allSlots: Date[] = [];
  for (const rule of rules) {
    const ruleStart = localToUtc(dateStr, rule.start_time.slice(0, 5));
    const ruleEnd = localToUtc(dateStr, rule.end_time.slice(0, 5));
    let t = ruleStart.getTime();
    while (t + SLOT_DURATION_MS <= ruleEnd.getTime()) {
      allSlots.push(new Date(t));
      t += SLOT_DURATION_MS;
    }
  }

  if (allSlots.length === 0) return [];

  // Day bounds for range queries
  const dayStart = localToUtc(dateStr, '00:00');
  const dayEnd = localToUtc(dateStr, '23:59');

  const [blocksResult, bookingsResult] = await Promise.all([
    supabase
      .from('availability_blocks')
      .select('blocked_from, blocked_until')
      .lt('blocked_from', dayEnd.toISOString())
      .gt('blocked_until', dayStart.toISOString()),
    supabase
      .from('bookings')
      .select('start_at, end_at')
      .eq('status', 'confirmed')
      .lt('start_at', dayEnd.toISOString())
      .gt('end_at', dayStart.toISOString()),
  ]);

  const busy: BusyRange[] = [];
  for (const b of blocksResult.data ?? []) {
    busy.push({ from: new Date(b.blocked_from).getTime(), to: new Date(b.blocked_until).getTime() });
  }
  for (const b of bookingsResult.data ?? []) {
    // Include 30-min buffer after each confirmed booking
    busy.push({ from: new Date(b.start_at).getTime(), to: new Date(b.end_at).getTime() + BUFFER_MS });
  }

  const now = Date.now();
  return allSlots.filter((slot) => {
    if (slot.getTime() <= now) return false;
    const slotEnd = slot.getTime() + SLOT_DURATION_MS;
    return !busy.some((r) => slot.getTime() < r.to && slotEnd > r.from);
  });
}
