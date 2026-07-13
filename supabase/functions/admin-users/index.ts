import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type, apikey, x-client-info',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}
const json = (o: unknown, s = 200) =>
  new Response(JSON.stringify(o), { status: s, headers: { ...cors, 'Content-Type': 'application/json' } })

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })
  try {
    const url = Deno.env.get('SUPABASE_URL')!
    const svc = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const admin = createClient(url, svc, { auth: { persistSession: false } })

    // quem está chamando?
    const jwt = (req.headers.get('Authorization') || '').replace('Bearer ', '')
    const { data: { user } } = await admin.auth.getUser(jwt)
    if (!user) return json({ error: 'Não autenticado' }, 401)
    const email = (user.email || '').toLowerCase()

    // precisa ser admin na allowlist
    const { data: me } = await admin.from('app_allow').select('role').eq('email', email).maybeSingle()
    if (!me || me.role !== 'admin') return json({ error: 'Apenas administradores' }, 403)

    const body = await req.json().catch(() => ({}))
    const action = body.action

    if (action === 'list') {
      const { data } = await admin.from('app_allow').select('email,role,nome,created_at').order('created_at')
      return json({ users: data || [] })
    }

    if (action === 'create') {
      const em = String(body.email || '').toLowerCase().trim()
      const role = ['admin', 'analista', 'operacoes'].includes(body.role) ? body.role : 'operacoes'
      const nome = String(body.nome || '').trim()
      if (!em || !em.includes('@')) return json({ error: 'E-mail inválido' }, 400)
      const { error: ce } = await admin.auth.admin.createUser({
        email: em, password: 'slr2025', email_confirm: true,
        user_metadata: { nome, role, must_change_password: true },
      })
      if (ce && !String(ce.message).toLowerCase().includes('already')) return json({ error: ce.message }, 400)
      await admin.from('app_allow').upsert({ email: em, role, nome })
      return json({ ok: true, senhaInicial: 'slr2025' })
    }

    if (action === 'delete') {
      const em = String(body.email || '').toLowerCase().trim()
      if (em === email) return json({ error: 'Você não pode remover a si mesmo' }, 400)
      const { data: admins } = await admin.from('app_allow').select('email').eq('role', 'admin')
      if ((admins || []).length <= 1 && (admins || [])[0]?.email === em)
        return json({ error: 'Não pode remover o último administrador' }, 400)
      const { data: list } = await admin.auth.admin.listUsers({ perPage: 1000 })
      const u = (list?.users || []).find((x) => (x.email || '').toLowerCase() === em)
      if (u) await admin.auth.admin.deleteUser(u.id)
      await admin.from('app_allow').delete().eq('email', em)
      return json({ ok: true })
    }

    return json({ error: 'Ação inválida' }, 400)
  } catch (e) {
    return json({ error: String((e as Error).message || e) }, 500)
  }
})
