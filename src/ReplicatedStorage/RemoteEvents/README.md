# RemoteEvents

Client↔server арасындағы барлық сигналдардың орталық анықтамасы (мыс. `UseAbility`, `RequestClassSelect`, `PurchaseGamepass`).
Ереже: жаңа RemoteEvent осы жерде ғана декларацияланады, басқа скрипттер тек `require`/сілтеме арқылы пайдаланады — сигналдардың шашырап кетуін болдырмау үшін.
