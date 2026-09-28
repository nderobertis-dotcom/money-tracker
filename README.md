# Money Tracker

PWA personale per tracciare entrate e uscite. Supabase + GitHub Pages.

## Setup

Installato sul progetto Supabase `nico-personale` (ref `ctmqvddvepybqnwpbszl`).
Schema già applicato e `index.html` già configurato con URL e chiave pubblica.

1. Accesso con l'utente già presente nel progetto (nderobertis@gmail.com). Se non ricordi la password:
   **Authentication → Users → … → Send password recovery**.
2. **Authentication → Sign In / Providers**: disattiva *Allow new users to sign up*.
3. Pubblica la cartella su **GitHub Pages** (repository privato o pubblico: la chiave nel codice è pubblica per design, i dati sono protetti dalla RLS).
4. Sul telefono apri il sito e aggiungilo alla schermata Home (Safari: Condividi → Aggiungi alla schermata Home).

`schema.sql` resta come riferimento per reinstallare da zero su un altro progetto.

Al primo accesso vengono creati 3 conti (Contanti, Conto corrente, Carta) e un set di categorie. Imposta subito il **saldo iniziale** di ogni conto nella scheda Conti.

## Uso quotidiano

Scrivi l'importo, tocca la categoria: il movimento è salvato. "Annulla" nel messaggio in basso per correggere subito.
Data, conto e nota sono sotto "Data, conto e nota" solo quando servono.

## Importare le spese annotate altrove

Impostazioni → Importa. Una riga per movimento, separatore `;`:

```
01/10;12,50;Spesa;Coop
02/10;3,20;Ristoranti
05/10;+1500;Stipendio
```

Importo senza segno = uscita, con `+` = entrata. Categorie non riconosciute finiscono in "Altro".

## Limiti noti (v1)

- Serve la connessione per salvare (niente coda offline).
- Nessun collegamento alla banca: tutto manuale, per scelta.
- Piano gratuito Supabase: i progetti inattivi per 7 giorni vengono messi in pausa. Se lo usi ogni giorno non succede.
