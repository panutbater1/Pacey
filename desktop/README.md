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
2. In the project, open **Project Settings › API** and copy the **Project URL** and the **anon public** key.
3. Paste them into `desktop/pacey.config.json`:

   ```json
   {
     "supabaseUrl": "https://your-project.supabase.co",
     "supabaseAnonKey": "your-anon-public-key"
   }
   ```

   Both are meant to be public. Never put the **service_role** key here.
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
- Apple and Google sign-in aren't connected yet, so those buttons are hidden when real sign-in is on.
- Only the laptop app connects. The prototype link keeps the pretend sign-in.
