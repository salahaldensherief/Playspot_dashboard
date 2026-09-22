import { withSupabase } from 'npm:@supabase/server'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

interface LocationPayload {
  latitude: number
  longitude: number
}

interface GeocodeAddress {
  city?: string
  town?: string
  village?: string
  municipality?: string
  county?: string
  state?: string
}

interface GeocodeResponse {
  address?: GeocodeAddress
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

function normalize(value: string) {
  return value
    .trim()
    .toLowerCase()
    .replace(/[ًٌٍَُِّْـ]/g, '')
    .replace(/[أإآ]/g, 'ا')
    .replace(/ة/g, 'ه')
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

// The platform already verified the JWT signature (verify_jwt = true).
// Here we only read the `sub` claim (the user id) from it, so we do not depend on the shape of ctx.userClaims.
function userIdFromAuthHeader(req: Request): string | null {
  const token = (req.headers.get('Authorization') ?? '').replace(/^Bearer\s+/i, '').trim()
  const payloadPart = token.split('.')[1]
  if (!payloadPart) return null
  try {
    const b64 = payloadPart.replace(/-/g, '+').replace(/_/g, '/')
    const padded = b64 + '='.repeat((4 - (b64.length % 4)) % 4)
    const bytes = Uint8Array.from(atob(padded), (c) => c.charCodeAt(0))
    const payload = JSON.parse(new TextDecoder().decode(bytes))
    const sub = payload?.sub
    return typeof sub === 'string' && UUID_RE.test(sub) ? sub : null
  } catch {
    return null
  }
}

Deno.serve(
  withSupabase({ auth: 'user' }, async (req, ctx) => {
    if (req.method === 'OPTIONS') {
      return new Response('ok', { headers: corsHeaders })
    }

    if (req.method !== 'POST') {
      return json({ error: 'Method not allowed' }, 405)
    }

    try {
      // Resolve the caller's user id first (was: ctx.userClaims.sub, which came back undefined and made every update fail with
      // "invalid input syntax for type uuid: undefined").
      const claimedSub = (ctx as { userClaims?: { sub?: unknown } }).userClaims?.sub
      const userId = (typeof claimedSub === 'string' && UUID_RE.test(claimedSub))
        ? claimedSub
        : userIdFromAuthHeader(req)

      if (!userId) {
        return json({ error: 'Unauthorized' }, 401)
      }

      const body = await req.json() as Partial<LocationPayload>
      const latitude = Number(body.latitude)
      const longitude = Number(body.longitude)

      if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
        return json({ error: 'latitude and longitude are required' }, 400)
      }

      if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
        return json({ error: 'Invalid coordinates' }, 400)
      }

      const geocodeUrl = new URL('https://nominatim.openstreetmap.org/reverse')
      geocodeUrl.searchParams.set('format', 'jsonv2')
      geocodeUrl.searchParams.set('lat', String(latitude))
      geocodeUrl.searchParams.set('lon', String(longitude))
      geocodeUrl.searchParams.set('zoom', '10')
      geocodeUrl.searchParams.set('accept-language', 'ar,en')

      const geocodeResponse = await fetch(geocodeUrl, {
        headers: {
          'User-Agent': 'Supabase-location-service/1.0',
          'Accept': 'application/json',
        },
      })

      if (!geocodeResponse.ok) {
        return json({ error: 'Unable to determine city from coordinates' }, 502)
      }

      const geocode = await geocodeResponse.json() as GeocodeResponse
      const address = geocode.address ?? {}
      const detectedCity = address.city ?? address.town ?? address.municipality ?? address.village ?? address.county

      if (!detectedCity) {
        return json({ error: 'No city found for these coordinates' }, 422)
      }

      const { data: cities, error: citiesError } = await ctx.supabase
        .from('cities')
        .select('id, name_ar, name_en')
        .eq('is_active', true)

      if (citiesError) {
        console.error('Failed to load cities', citiesError)
        return json({ error: 'Could not load cities' }, 500)
      }

      const detected = normalize(detectedCity)
      const city = (cities ?? []).find((item) =>
        normalize(item.name_ar ?? '') === detected ||
        normalize(item.name_en ?? '') === detected ||
        normalize(item.name_ar ?? '').includes(detected) ||
        normalize(item.name_en ?? '').includes(detected) ||
        detected.includes(normalize(item.name_ar ?? '')) ||
        detected.includes(normalize(item.name_en ?? ''))
      )

      if (!city) {
        return json({
          error: 'Detected city is not configured in the cities table',
          detected_city: detectedCity,
        }, 422)
      }

      const { error: updateError } = await ctx.supabase
        .from('profiles')
        .update({
          latitude,
          longitude,
          city_id: city.id,
          updated_at: new Date().toISOString(),
        })
        .eq('id', userId)

      if (updateError) {
        console.error('Failed to update profile location', updateError)
        return json({ error: 'Could not update profile location' }, 500)
      }

      return json({
        success: true,
        city_id: city.id,
        city_name_ar: city.name_ar,
        city_name_en: city.name_en,
        latitude,
        longitude,
      })
    } catch (error) {
      console.error('Location function error', error)
      return json({ error: 'Invalid request' }, 400)
    }
  }),
)
