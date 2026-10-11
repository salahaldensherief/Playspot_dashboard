import {pathToFileURL} from 'node:url';
import {readFile,writeFile} from 'node:fs/promises';
import {createServer} from 'node:http';
import {resolve,extname} from 'node:path';
const backendRoot=resolve(process.env.PLAYSPOT_BACKEND_ROOT??'D:/PlaySpotWork/mobile-dev-test');
const {fixedSessionFixture}=await import(pathToFileURL(resolve(backendRoot,'supabase/tests/runtime/fixed_session_fixture.mjs')));
const f=await fixedSessionFixture();
await f.admin(`ALTER TABLE public.rooms ADD pricing_model text DEFAULT 'single_multi_hour';
CREATE TABLE public.booking_holds(id uuid PRIMARY KEY,lounge_id uuid,room_id uuid,start_at timestamp,end_at timestamp,expires_at timestamptz,released_at timestamptz,user_id uuid);
ALTER TABLE public.lounges ADD contact_phone text;
UPDATE public.lounges SET is_open=true,contact_phone='01000000000';`);
for(const path of ['supabase/repairs/offline_cashier_bootstrap.sql','supabase/migrations/20261004151006_cashier_writer_generation_handover.sql','supabase/migrations/20261004153152_lounge_public_operating_status.sql','supabase/migrations/20261009000002_cashier_writer_renewal_without_mode_change.sql'])await f.db.exec(await readFile(resolve(backendRoot,path),'utf8'));
await f.admin(`DELETE FROM private.cashier_writer_authorities;INSERT INTO public.fixture_permissions VALUES('${f.actor}','${f.lounge}','bookings.view'),('${f.actor}','${f.lounge}','menu_view');`);
const root=resolve('build/offline-fixture');
const meta={FIXTURE_URL:'http://127.0.0.1:51463',FIXTURE_ACTOR:f.actor,FIXTURE_LOUNGE:f.lounge};
await writeFile(new URL('../../build/offline-fixture-defines.json',import.meta.url),JSON.stringify(meta));
const user={id:f.actor,aud:'authenticated',role:'authenticated',email:'fixture@example.invalid',email_confirmed_at:new Date().toISOString(),created_at:new Date().toISOString(),updated_at:new Date().toISOString(),app_metadata:{provider:'email',providers:['email'],lounge_id:f.lounge},user_metadata:{}};
function session(){const now=Math.floor(Date.now()/1000),encode=value=>Buffer.from(JSON.stringify(value)).toString('base64url');return {access_token:encode({alg:'HS256',typ:'JWT'})+'.'+encode({sub:f.actor,role:'authenticated',aud:'authenticated',iat:now,exp:now+3600})+'.synthetic',refresh_token:'synthetic-local-refresh',expires_in:3600,expires_at:now+3600,token_type:'bearer',user};}
const stats={bootstrap:0,operations:0,refresh:0,release:0};
let transportDown=false;
const server=createServer(async(req,res)=>{
 res.setHeader('Access-Control-Allow-Origin','*');res.setHeader('Access-Control-Allow-Headers','*');res.setHeader('Access-Control-Allow-Methods','GET,POST,OPTIONS');
 if(req.method==='OPTIONS'){res.writeHead(204);res.end();return;}
 const json=(status,data)=>{res.writeHead(status,{'Content-Type':'application/json'});res.end(JSON.stringify(data));};
 try{
  const path=new URL(req.url,'http://localhost').pathname;
  // Synthetic transport outage only; never edit persisted writer flags.
  if(path==='/__fixture/transport' && req.method==='POST'){
   const chunks=[];for await(const chunk of req)chunks.push(chunk);
   transportDown=JSON.parse(Buffer.concat(chunks).toString()).down===true;
   return json(200,{transportDown});
  }
  if(path==='/__fixture/status'){await f.admin('');const value=(await f.db.query(`SELECT (SELECT count(*) FROM public.bookings)::int AS bookings,(SELECT count(*) FROM public.shift_payments)::int AS cash_receipts,(SELECT count(*) FROM private.cashier_operation_receipts)::int AS receipts,
    public.get_lounge_operating_status('${f.lounge}') AS operating,
    (SELECT jsonb_build_object('online_requested',online_requested,'heartbeat_alive',heartbeat_expires_at>clock_timestamp(),'device_id',device_id,'permit_id',permit_id) FROM private.cashier_writer_authorities WHERE lounge_id='${f.lounge}') AS writer`)).rows[0];return json(200,{...stats,...value});}
  if(path.startsWith('/auth/v1/token'))return json(200,session());
  if(path==='/auth/v1/user')return json(200,user);
  if(path==='/auth/v1/logout')return json(200,{});
  if(path.startsWith('/rest/v1/rpc/')){
   if(transportDown)return json(503,{code:'FIXTURE_OFFLINE',message:'Synthetic transport unavailable'});
   const chunks=[];for await(const chunk of req)chunks.push(chunk);const body=JSON.parse(Buffer.concat(chunks).toString()||'{}');await f.login();
   let result;const rpc=path.split('/').at(-1);
   if(rpc==='bootstrap_offline_cashier'){stats.bootstrap++;result=await f.db.query('SELECT public.bootstrap_offline_cashier($1,$2,$3) AS result',[body.p_lounge_id,body.p_device_id,body.p_online]);}
   else if(rpc==='apply_offline_cashier_operation'){stats.operations++;result=await f.db.query('SELECT public.apply_offline_cashier_operation($1::jsonb) AS result',[JSON.stringify(body.p_operation)]);}
   else if(rpc==='refresh_cashier_writer'){stats.refresh++;result=await f.db.query('SELECT public.refresh_cashier_writer($1,$2,$3) AS result',[body.p_lounge_id,body.p_device_id,body.p_online]);}
   else if(rpc==='release_cashier_writer'){stats.release++;result=await f.db.query('SELECT public.release_cashier_writer($1,$2,$3,$4) AS result',[body.p_lounge_id,body.p_device_id,body.p_permit_id,body.p_last_applied_sequence]);}
   else return json(404,{code:'PGRST202',message:'Synthetic RPC unavailable'});
   return json(200,result.rows[0].result);
  }
  const file=resolve(root,path==='/'||!extname(path)?'index.html':'.'+path);if(!file.startsWith(root))return json(403,{});
  const data=await readFile(file);const type={'.html':'text/html','.js':'text/javascript','.json':'application/json','.wasm':'application/wasm','.ttf':'font/ttf','.woff2':'font/woff2'}[extname(file)]??'application/octet-stream';res.writeHead(200,{'Content-Type':type});res.end(data);
 }catch(error){json(400,{code:error.code??'FIXTURE_ERROR',message:error.message});}
});
server.listen(51463,'127.0.0.1',()=>console.log('Isolated browser fixture ready on 127.0.0.1:51463'));
async function stop(){server.close();await f.db.close();process.exit(0);}
process.on('SIGINT',stop);process.on('SIGTERM',stop);
