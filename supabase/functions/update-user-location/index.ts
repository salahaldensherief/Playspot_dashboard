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

      let detectedCity: string | null = null

      // Primary reverse geocoder: OpenStreetMap Nominatim
      try {
        const geocodeUrl = new URL('https://nominatim.openstreetmap.org/reverse')
        geocodeUrl.searchParams.set('format', 'jsonv2')
        geocodeUrl.searchParams.set('lat', String(latitude))
        geocodeUrl.searchParams.set('lon', String(longitude))
        geocodeUrl.searchParams.set('zoom', '10')
        geocodeUrl.searchParams.set('accept-language', 'ar,en')

        const geocodeResponse = await fetch(geocodeUrl, {
          headers: {
            'User-Agent': 'Playspot-Dashboard-Location-Service/1.1',
            'Accept': 'application/json',
          },
        })

        if (geocodeResponse.ok) {
          const geocode = await geocodeResponse.json() as GeocodeResponse
          const address = geocode.address ?? {}
          detectedCity = address.city ?? address.town ?? address.municipality ?? address.village ?? address.county ?? null
        }
      } catch (err) {
        console.warn('Primary geocoder failed, attempting secondary API', err)
      }

      // Secondary reverse geocoder fallback: BigDataCloud API
      if (!detectedCity) {
        try {
          const bdcUrl = `https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${latitude}&longitude=${longitude}&localityLanguage=ar`
          const bdcRes = await fetch(bdcUrl)
          if (bdcRes.ok) {
            const bdcData = await bdcRes.json()
            detectedCity = bdcData.city || bdcData.locality || bdcData.principalSubdivision || null
          }
        } catch (err) {
          console.warn('Secondary geocoder failed', err)
        }
      }

      const { data: cities, error: citiesError } = await ctx.supabase
        .from('cities')
        .select('id, name_ar, name_en')
        .eq('is_active', true)

      if (citiesError) {
        console.error('Failed to load cities', citiesError)
      }

      let matchedCityId: string | null = null
      let matchedCityAr: string | null = null
      let matchedCityEn: string | null = null

      if (detectedCity && cities && cities.length > 0) {
        const detected = normalize(detectedCity)
        const city = cities.find((item) =>
          normalize(item.name_ar ?? '') === detected ||
          normalize(item.name_en ?? '') === detected ||
          normalize(item.name_ar ?? '').includes(detected) ||
          normalize(item.name_en ?? '').includes(detected) ||
          detected.includes(normalize(item.name_ar ?? '')) ||
          detected.includes(normalize(item.name_en ?? ''))
        )
        if (city) {
          matchedCityId = city.id
          matchedCityAr = city.name_ar
          matchedCityEn = city.name_en
        }
      }

      // Construct update payload - always update latitude & longitude even if city reverse geocode is unavailable
      const updateData: Record<string, unknown> = {
        latitude,
        longitude,
        updated_at: new Date().toISOString(),
      }
      if (matchedCityId) {
        updateData.city_id = matchedCityId
      }

      const { error: updateError } = await ctx.supabase
        .from('profiles')
        .update(updateData)
        .eq('id', userId)

      if (updateError) {
        console.error('Failed to update profile location', updateError)
        return json({ error: 'Could not update profile location' }, 500)
      }

      return json({
        success: true,
        city_id: matchedCityId,
        city_name_ar: matchedCityAr,
        city_name_en: matchedCityEn,
        latitude,
        longitude,
      })
    } catch (error) {
      console.error('Location function error', error)
      return json({ error: 'Invalid request' }, 400)
    }
  }),
)
