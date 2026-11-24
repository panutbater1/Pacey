# Pacey on your laptop

Runs Pacey as a real app in a phone-shaped window: real time, your nights saved between launches, and notifications from your computer.

## Open the app

From the main Pacey folder (one level up from here):

```bash
npm start
```

Or type `pacey` in any terminal after a one-time `npm install -g .` in the main Pacey folder. The first launch sets itself up, which takes about a minute.

You can also run it from this folder with `npm install` once, then `npm start`.

## Testing mode

```bash
pacey --dev
```

Shows the testing buttons: **Skip setup** during first launch and **Lock** (top left during a night) to preview the lock screen widgets and Live Activity.

## Demo mode

```bash
pacey --demo
```

Opens with the prototype's sample nights and sped-up time (one second is one minute), so you can see the charts, Weeks, Months, All time and Calories filled in. Nothing you do in demo mode is saved.

## How it works

- The app is built from `../prototype/Main.dc.html` every time you start it, so it always matches the prototype.
- Unlike the prototype, it uses the real clock (no sped-up time) and starts with no sample nights.
- Everything you enter is saved on this computer. To start again from the welcome screen, open the developer tools (View › Toggle Developer Tools) and run `paceyReset()` in the console.
- The phone shrinks to fit if your screen is small.

## Real sign-in (Supabase)

Without any settings, the account screen only pretends to sign in. To make it real:

1. Create a free project at [supabase.com](https://supabase.com).
2. In the project, copy the **Project URL** (`https://<project-id>.supabase.co`) and the **publishable** key (`sb_publishable_…`, under **Project Settings › API Keys**). The older **anon public** key works too.
3. Paste them into `desktop/pacey.config.json`:

   ```json
   {
     "supabaseUrl": "https://your-project.supabase.co",
     "supabaseAnonKey": "your-anon-public-key"
   }
   ```

   Both are meant to be public. Never put the **secret** (`sb_secret_…`) or **service_role** key here.
4. So that people can delete their own account (Settings › Profile › Delete my account), open **SQL Editor** in Supabase and run:

   ```sql
   create or replace function public.delete_user()
   returns void
   language sql
   security definer
   set search_path = ''
   as $$
     delete from auth.users where id = auth.uid();
   $$;

   revoke all on function public.delete_user() from public, anon;
   grant execute on function public.delete_user() to authenticated;
   ```
5. Optional: under **Authentication › Sign In / Providers › Email**, turn **Confirm email** on or off. With it on, people get a link to confirm before they can sign in, and the app tells them to check their email.

Then run `npm start` again. The terminal says "(real sign-in on)" when the settings are picked up.

What it does:

- **Create account** and **Sign in** with email and password, with clear messages for a wrong password, an email that's already registered, or an unconfirmed email.
- Saves the person's plan (their limit and usual night) with the account, and brings it back when they sign in on another computer.
- **Sign out** and **Delete my account** in Settings › Profile.
- **Continue with Google** works once it's set up (see below). Apple sign-in isn't connected yet, so its button is hidden when real sign-in is on.
- Only the laptop app connects. The prototype link keeps the pretend sign-in.

## Google sign-in

The laptop app opens Google in your own browser, then catches the reply on this computer at `http://127.0.0.1:53682/auth/callback`.

1. In [Google Cloud Console](https://console.cloud.google.com), create a project, then **APIs & Services › OAuth consent screen**: app name Pacey, your email as support and developer contact, audience **External**.
2. **APIs & Services › Credentials › Create credentials › OAuth client ID**, type **Web application**. Under **Authorised redirect URIs** add your Supabase callback, `https://<project-id>.supabase.co/auth/v1/callback`. Create it and keep the **Client ID** and **Client secret**.
3. In Supabase, **Authentication › Sign In / Providers › Google**: turn it on and paste the Client ID and Client secret. Save.
4. In Supabase, **Authentication › URL Configuration › Redirect URLs**: add `http://127.0.0.1:53682/auth/callback`.
5. In `desktop/pacey.config.json`, set `"googleSignIn": true`, then start Pacey again.

The client secret only goes into Supabase, never into this folder.

