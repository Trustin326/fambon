/* FamBon cloud account + family-space controls.
   Uses only the Supabase anon/publishable key. RLS is the security boundary. */
(() => {
  'use strict';
  const cfg = window.FAMBON_CONFIG || {};
  const configured = cfg.enableSupabase === true && /^https:\/\//.test(cfg.supabaseUrl || '') && !!cfg.supabaseAnonKey;
  const style = document.createElement('style');
  style.textContent = `
    .fb-cloud-launch{position:fixed;right:20px;bottom:20px;z-index:30;border:0;border-radius:999px;background:#302a3b;color:#fff;padding:13px 18px;font:700 13px Nunito,sans-serif;box-shadow:0 8px 28px #302a3b35;cursor:pointer}
    .fb-cloud-panel{position:fixed;z-index:31;right:20px;bottom:78px;width:min(390px,calc(100vw - 28px));max-height:min(78vh,680px);overflow:auto;background:#fff;border:1px solid #eee4e0;border-radius:20px;padding:20px;box-shadow:0 18px 60px #302a3b2b;color:#302a3b;font:13px 'DM Sans',sans-serif}
    .fb-cloud-panel[hidden]{display:none}.fb-cloud-panel h2{font:900 21px Nunito,sans-serif;margin:4px 0 8px}.fb-cloud-panel p{line-height:1.55;color:#756e7d}.fb-cloud-panel label{display:block;font-weight:700;margin:12px 0 5px}.fb-cloud-panel input{width:100%;box-sizing:border-box;padding:11px;border:1px solid #e8deda;border-radius:10px;font:inherit;background:#fff}.fb-cloud-actions{display:flex;gap:8px;flex-wrap:wrap;margin-top:12px}.fb-cloud-actions button,.fb-cloud-panel button{border:0;border-radius:10px;padding:10px 13px;background:#302a3b;color:white;font-weight:700;cursor:pointer}.fb-cloud-actions .secondary{background:#f3edf8;color:#594d68}.fb-cloud-panel button:disabled{opacity:.5;cursor:wait}.fb-cloud-status{padding:10px;border-radius:10px;background:#f8f3ef;margin:12px 0;line-height:1.5}.fb-cloud-status.error{background:#fff0ee;color:#9b4039}.fb-cloud-list{padding:10px;border:1px solid #eee4e0;border-radius:11px;margin:8px 0}.fb-cloud-list strong{display:block;margin-bottom:4px}.fb-cloud-panel .fb-close{float:right;background:#f3edf8;color:#594d68;padding:7px 10px}
    @media(max-width:520px){.fb-cloud-launch{right:12px;bottom:12px}.fb-cloud-panel{right:8px;bottom:68px}}
  `;
  document.head.appendChild(style);
  const launch = document.createElement('button');
  launch.className = 'fb-cloud-launch'; launch.type = 'button'; launch.textContent = '☁ Family account';
  launch.setAttribute('aria-expanded','false'); launch.setAttribute('aria-controls','fbCloudPanel');
  const panel = document.createElement('section');
  panel.id = 'fbCloudPanel'; panel.className = 'fb-cloud-panel'; panel.hidden = true;
  panel.setAttribute('aria-label','FamBon family account');
  panel.innerHTML = '<button class="fb-close" type="button" aria-label="Close">×</button><span class="eyebrow">FAMBON CLOUD</span><h2>Bring your family space together</h2><div id="fbCloudBody"></div>';
  document.body.append(launch,panel);
  const body = panel.querySelector('#fbCloudBody');
  let client = null, user = null, busy = false;
  const esc = s => String(s ?? '').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  function status(msg, error=false){const el=body.querySelector('.fb-cloud-status');if(el){el.textContent=msg;el.classList.toggle('error',error)}}
  function setBody(html){body.innerHTML=html}
  function message(msg,error=false){const el=document.createElement('div');el.className='fb-cloud-status'+(error?' error':'');el.setAttribute('role','status');el.textContent=msg;body.prepend(el)}
  function loading(){return '<div class="fb-cloud-status" role="status">Connecting securely…</div>'}
  function authForm(note=''){setBody((note?'<div class="fb-cloud-status">'+esc(note)+'</div>':'')+
    '<p>Sign in to sync a family space across devices, or create an account to get started.</p>'+
    '<label for="fbEmail">Email</label><input id="fbEmail" type="email" autocomplete="email" maxlength="254" required placeholder="you@example.com">'+
    '<label for="fbPassword">Password</label><input id="fbPassword" type="password" autocomplete="current-password" minlength="8" required placeholder="At least 8 characters">'+
    '<div class="fb-cloud-actions"><button id="fbSignIn" type="button">Sign in</button><button id="fbSignUp" class="secondary" type="button">Create account</button></div>'+
    '<p>Use a password unique to this account. Email confirmation may be required by your Supabase settings.</p>');
    body.querySelector('#fbSignIn').onclick=()=>authenticate(false);
    body.querySelector('#fbSignUp').onclick=()=>authenticate(true);
  }
  async function authenticate(signUp){
    const email=body.querySelector('#fbEmail').value.trim(),password=body.querySelector('#fbPassword').value;
    if(!email||password.length<8)return message('Enter a valid email and a password with at least 8 characters.',true);
    try{const r=signUp?await client.auth.signUp({email,password}):await client.auth.signInWithPassword({email,password});
      if(r.error)throw r.error;
      if(signUp&&!r.data.session){authForm('Check your email for the confirmation link, then return here to sign in.');return}
      user=r.data.user;await renderAccount();
    }catch(e){message(e.message||'Could not complete sign-in.',true)}
  }
  async function renderAccount(){
    if(!user){authForm();return}
    setBody('<div class="fb-cloud-status">Signed in as <strong>'+esc(user.email)+'</strong></div>'+
      '<h2>Your family spaces</h2><div id="fbFamilies">'+loading()+'</div>'+
      '<h2 style="margin-top:18px">Create a family space</h2><label for="fbFamilyName">Family name</label><input id="fbFamilyName" maxlength="70" placeholder="The Harbin family">'+
      '<label for="fbDisplayName">Your display name</label><input id="fbDisplayName" maxlength="50" placeholder="How family sees you">'+
      '<div class="fb-cloud-actions"><button id="fbCreateFamily" type="button">Create family</button></div>'+
      '<h2 style="margin-top:18px">Join with an invitation</h2><label for="fbInviteToken">Invitation token</label><input id="fbInviteToken" maxlength="128" autocomplete="off" placeholder="Paste the invitation token">'+
      '<label for="fbJoinName">Your display name</label><input id="fbJoinName" maxlength="50" placeholder="How family sees you">'+
      '<div class="fb-cloud-actions"><button id="fbJoinFamily" class="secondary" type="button">Join family</button><button id="fbSignOut" class="secondary" type="button">Sign out</button></div>');
    body.querySelector('#fbCreateFamily').onclick=createFamily;
    body.querySelector('#fbJoinFamily').onclick=joinFamily;
    body.querySelector('#fbSignOut').onclick=async()=>{await client.auth.signOut();user=null;authForm('You have signed out.')};
    await loadFamilies();
  }
  async function loadFamilies(){
    const wrap=body.querySelector('#fbFamilies');if(!wrap)return;
    try{
      const m=await client.from('family_members').select('family_id,display_name,role').eq('user_id',user.id);
      if(m.error)throw m.error;
      if(!m.data.length){wrap.innerHTML='<div class="fb-cloud-status">You have not joined a family space yet.</div>';return}
      const ids=m.data.map(x=>x.family_id);
      const f=await client.from('families').select('id,name').in('id',ids);
      if(f.error)throw f.error;
      wrap.innerHTML=f.data.map(x=>{const member=m.data.find(y=>y.family_id===x.id);return '<div class="fb-cloud-list"><strong>'+esc(x.name)+'</strong><span>'+esc(member.display_name)+' · '+esc(member.role)+'</span>'+(member.role==='owner'||member.role==='adult'?'<div class="fb-cloud-actions"><button class="fbInvite" data-family="'+esc(x.id)+'" type="button">Create invite</button></div>':'')+'</div>'}).join('')||'<div class="fb-cloud-status">No family spaces found.</div>';
      wrap.querySelectorAll('.fbInvite').forEach(b=>b.onclick=()=>createInvite(b.dataset.family));
    }catch(e){wrap.innerHTML='<div class="fb-cloud-status error">'+esc(e.message||'Could not load family spaces. Check that the schema is installed.')+'</div>'}
  }
  async function createFamily(){
    const name=body.querySelector('#fbFamilyName').value.trim(),display=body.querySelector('#fbDisplayName').value.trim();
    if(!name||!display)return message('Add both a family name and your display name.',true);
    try{const r=await client.rpc('create_family',{family_name:name,member_display_name:display});if(r.error)throw r.error;message('Family space created. You can now invite family members.');await renderAccount()}
    catch(e){message(e.message||'Could not create the family space.',true)}
  }
  async function createInvite(familyId){
    try{const r=await client.rpc('create_family_invite',{target_family:familyId,member_role:'member'});if(r.error)throw r.error;
      const token=r.data;setBody('<h2>Invitation ready</h2><p>This single-use invitation expires in 7 days. Share it privately with the person you want to invite. They must create an account or sign in, then paste this token in the Join section.</p><input id="fbTokenOutput" readonly value="'+esc(token)+'"><div class="fb-cloud-actions"><button id="fbCopyToken" type="button">Copy invitation token</button><button id="fbBack" class="secondary" type="button">Back to family spaces</button></div>');
      body.querySelector('#fbCopyToken').onclick=async()=>{try{await navigator.clipboard.writeText(token);message('Invitation token copied.')}catch{body.querySelector('#fbTokenOutput').select();message('Select and copy the token manually.')}};
      body.querySelector('#fbBack').onclick=renderAccount;
    }catch(e){message(e.message||'Could not create invitation.',true)}
  }
  async function joinFamily(){
    const token=body.querySelector('#fbInviteToken').value.trim(),display=body.querySelector('#fbJoinName').value.trim();
    if(!token||!display)return message('Paste an invitation token and enter your display name.',true);
    try{const r=await client.rpc('accept_family_invite',{invite_token:token,member_display_name:display});if(r.error)throw r.error;message('You joined the family space.');await renderAccount()}
    catch(e){message(e.message||'Could not redeem that invitation.',true)}
  }
  async function initialize(){
    if(!configured){setBody('<div class="fb-cloud-status">Cloud accounts are not active yet. The local FamBon demo remains available on this device.</div><p>To enable shared family spaces:</p><ol><li>Create a Supabase project.</li><li>Run <code>supabase/schema.sql</code> in its SQL Editor.</li><li>Add your project URL and anon/publishable key to <code>config.js</code>, then set <code>enableSupabase: true</code>.</li><li>Configure email authentication and allowed redirect URLs in Supabase.</li></ol><p>Never put a service-role key in this website.</p>');return}
    setBody(loading());
    try{
      if(!window.supabase){await new Promise((resolve,reject)=>{const s=document.createElement('script');s.src='https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2';s.onload=resolve;s.onerror=()=>reject(new Error('Could not load the Supabase client library.'));document.head.appendChild(s)})}
      client=window.supabase.createClient(cfg.supabaseUrl,cfg.supabaseAnonKey,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
      const r=await client.auth.getSession();if(r.error)throw r.error;user=r.data.session?.user||null;
      await renderAccount();
      client.auth.onAuthStateChange((_event,session)=>{user=session?.user||null;renderAccount()});
    }catch(e){setBody('<div class="fb-cloud-status error">'+esc(e.message||'Cloud service unavailable.')+'</div><button id="fbRetry" type="button">Try again</button>');body.querySelector('#fbRetry').onclick=initialize}
  }
  launch.addEventListener('click',async()=>{const opening=panel.hidden;panel.hidden=!opening;launch.setAttribute('aria-expanded',String(opening));if(opening&&!panel.dataset.loaded){panel.dataset.loaded='1';await initialize()}});
  panel.querySelector('.fb-close').onclick=()=>{panel.hidden=true;launch.setAttribute('aria-expanded','false')};
  document.addEventListener('keydown',e=>{if(e.key==='Escape'&&!panel.hidden){panel.hidden=true;launch.setAttribute('aria-expanded','false')}});
})();
