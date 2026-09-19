# ChipLab

ChipLab ist ein edukatives Tiny-Tapeout-Projekt in SystemVerilog mit digitalen Logikexperimenten auf einem Chip.

## Kurzüberblick

- Zielplattform: Tiny Tapeout / IHP26b
- Projektbeschreibung: „Educational digital logic experiments“
- Implementierungsstand: Abschnitte 1 bis 8 sind umgesetzt

## Einstieg

- Die HDL-Quellen liegen in [`src/`](src/).
- Projektmetadaten und Moduldefinitionen stehen in [`info.yaml`](info.yaml).
- Experimente werden über `uio_in[5:0]` ausgewählt; zusätzliche Betriebsarten nutzen `uio_in[7:6]`.
- Ergebnisse erscheinen auf `uo_out[7:0]`.

## Dokumentation

Weiterführende Informationen finden sich in [`docs/`](docs/), insbesondere:

- [`docs/info.md`](docs/info.md) – Funktionsübersicht und Bedienhinweise
- [`docs/local-simulation.md`](docs/local-simulation.md) – lokale Simulation und Tests
- [`docs/experiment-plan.md`](docs/experiment-plan.md) – Überblick über die Experimente
