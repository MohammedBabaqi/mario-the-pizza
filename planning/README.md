# MARIO Pizza App — Planning Documentation

## Welcome to the Planning Folder

This folder contains complete technical documentation for the **MARIO** Flutter pizza delivery application.
It is structured to give a complete picture of the codebase — from architecture to enhancement ideas —
ready to paste into ChatGPT or any AI assistant for targeted improvements.

---

## 📁 File Index

| File | Purpose |
|------|---------|
| [01_project_overview.md](./01_project_overview.md) | Product vision, tech stack, feature list |
| [02_architecture.md](./02_architecture.md) | Clean Architecture + BLoC diagram, folder structure |
| [03_class_uml.md](./03_class_uml.md) | Full UML class diagrams for every entity, bloc, widget |
| [04_screen_flows.md](./04_screen_flows.md) | Navigation flows, screen state machines |
| [05_data_layer.md](./05_data_layer.md) | Repository pattern, mock vs Firebase, data models |
| [06_ui_system.md](./06_ui_system.md) | Design tokens, typography, color palette, components |
| [07_enhancements.md](./07_enhancements.md) | ⭐ Improvement wishlist: pizza icons, animations, features |
| [08_chatgpt_prompts.md](./08_chatgpt_prompts.md) | Ready-to-paste prompts for ChatGPT to improve specific parts |

---

## Quick Context for AI Assistants

> **MARIO** is a production-quality Flutter pizza delivery app built with:
> - **Flutter** (Dart) — cross-platform mobile/web UI
> - **BLoC + Cubit** — state management (flutter_bloc)
> - **GoRouter** — declarative navigation
> - **GetIt** — dependency injection
> - **Clean Architecture** — entities → repositories → blocs → screens
> - **Mock mode** — full app works offline with mock data (no Firebase needed)
> - **Custom vector pizza** rendered with `CustomPainter` (no image assets)

The app currently renders pizzas as **`CustomPainter` vector drawings** which look simplistic.
The main enhancement goal is to replace these with **proper SVG/Lottie illustrations**.
