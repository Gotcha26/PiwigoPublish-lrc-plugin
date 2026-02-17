"""
CLI — Interface en ligne de commande du Video Toolkit.

Deux modes :
  1. Mode non-interactif (appelé depuis Lightroom via args)
     python video_toolkit.py --mode probe --input video.mp4
     python video_toolkit.py --mode batch --batch-file batch.json

  2. Mode interactif (menu terminal, lancé sans args)
     python video_toolkit.py

L'interface interactive utilise les patterns Menu Generator :
  - Menus compacts par sections
  - Annulation systématique (0 / x / ENTRÉE)
  - Rapport structuré après chaque opération
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from .config import Config
from .ffprobe import FFprobe, ProbeError
from .hasher import partial_hash
from .presets import PresetManager, PRESET_ORDER
from .status import StatusManager
from .ui import Colors, OutputFormatter, clear_screen, pause

# ---------------------------------------------------------------------------
# Parser non-interactif
# ---------------------------------------------------------------------------

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="video_toolkit.py",
        description="Video Toolkit — Local video processing for PiwigoPublish",
    )
    p.add_argument(
        "--mode",
        choices=["probe", "batch", "status", "clean"],
        help="Mode d'exécution (sans --mode : mode interactif)",
    )
    p.add_argument("--input",       help="Fichier vidéo source")
    p.add_argument("--preset",      help="Preset : small/medium/large/xlarge/xxl/origin")
    p.add_argument("--config",      help="Chemin vers le fichier de configuration JSON")
    p.add_argument("--output-dir",  help="Dossier de sortie (défaut : même que la source)")
    p.add_argument("--batch-file",  help="Fichier JSON liste de vidéos (mode batch)")
    p.add_argument("--status-file", help="Fichier statut global pour le polling Lightroom")
    p.add_argument("--verbose",     action="store_true", help="Sortie détaillée")
    p.add_argument("--dry-run",     action="store_true", help="Simuler sans écrire")
    return p


# ---------------------------------------------------------------------------
# Mode probe (non-interactif — appelé par Lightroom)
# ---------------------------------------------------------------------------

def run_probe(args: argparse.Namespace, cfg: Config) -> int:
    """Analyse une vidéo et écrit le résultat JSON sur stdout. Exit 0 = OK."""
    if not args.input:
        _json_error("--input requis pour le mode probe")
        return 1

    ffprobe_bin = cfg.resolve_tool("ffprobe") or "ffprobe"
    prober = FFprobe(ffprobe_bin)

    try:
        info = prober.probe(args.input)
    except ProbeError as e:
        _json_error(str(e))
        return 1

    # Enrichir avec le hash partiel
    try:
        h = partial_hash(args.input)
    except OSError as e:
        _json_error(f"Impossible de lire le fichier : {e}")
        return 1

    result = info.to_dict()
    result["hash"] = h

    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0


# ---------------------------------------------------------------------------
# Mode batch (non-interactif — appelé par Lightroom)
# ---------------------------------------------------------------------------

def run_batch(args: argparse.Namespace, cfg: Config) -> int:
    """Traite un batch de vidéos depuis un fichier JSON."""
    if not args.batch_file:
        _json_error("--batch-file requis pour le mode batch")
        return 1

    batch_path = Path(args.batch_file)
    if not batch_path.exists():
        _json_error(f"Fichier batch introuvable : {args.batch_file}")
        return 1

    try:
        with batch_path.open("r", encoding="utf-8") as f:
            batch = json.load(f)
    except (json.JSONDecodeError, OSError) as e:
        _json_error(f"Erreur lecture batch : {e}")
        return 1

    # Phase 1A : mode probe seulement — retourner les infos probe pour chaque vidéo
    videos = batch.get("videos", [])
    ffprobe_bin = cfg.resolve_tool("ffprobe") or "ffprobe"
    prober = FFprobe(ffprobe_bin)

    results = []
    for item in videos:
        input_file = item.get("input", "")
        try:
            info = prober.probe(input_file)
            h = partial_hash(input_file)
            d = info.to_dict()
            d["hash"] = h
            d["status"] = "ok"
            results.append(d)
        except (ProbeError, OSError) as e:
            results.append({"input": input_file, "status": "error", "error": str(e)})

    print(json.dumps({"results": results}, indent=2, ensure_ascii=False))
    return 0


# ---------------------------------------------------------------------------
# Mode status (non-interactif)
# ---------------------------------------------------------------------------

def run_status(args: argparse.Namespace, cfg: Config) -> int:
    """Vérifie le statut d'une vidéo déjà traitée."""
    if not args.input:
        _json_error("--input requis pour le mode status")
        return 1

    sm = StatusManager(args.input, cfg.get("vtk_dir_name", ".vtk"))
    state = sm.get_state()
    source = sm.get_source()
    variants = {
        k: v for k, v in sm._data.get("variants", {}).items()
    }

    result = {
        "state": state,
        "source": source,
        "variants": variants,
        "thumbnail": sm.get_thumbnail(),
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0


# ---------------------------------------------------------------------------
# Mode interactif — Menu principal
# ---------------------------------------------------------------------------

class InteractiveCLI:
    """Menu interactif pour tester et configurer le Video Toolkit."""

    def __init__(self, cfg: Config):
        self.cfg = cfg
        self.c = Colors()
        self.fmt = OutputFormatter(self.c)
        self.presets = PresetManager(cfg.get_presets_file())

    def run(self) -> None:
        while True:
            clear_screen()
            self._print_header()
            self._print_main_menu()

            choice = input(self.c.prompt("Votre choix (0-4): ")).strip()

            if choice == "0":
                print(f"\n{self.c.DIM}Au revoir.{self.c.RESET}\n")
                break
            elif choice == "1":
                self._menu_probe()
            elif choice == "2":
                self._menu_presets()
            elif choice == "3":
                self._menu_tools()
            elif choice == "4":
                self._menu_config()
            else:
                print(self.c.error(f'Choix invalide : "{choice}"'))
                pause(self.c)

    # --- Header ---

    def _print_header(self) -> None:
        print()
        print(self.c.box_header("VIDEO TOOLKIT — PiwigoPublish", width=70))
        print()

        # Ligne de statut outils
        tools = self.cfg.tool_status()
        parts = []
        for name, path in tools.items():
            if path:
                parts.append(f"{self.c.KEY}{name}{self.c.RESET}: {self.c.OK}OK{self.c.RESET}")
            else:
                parts.append(f"{self.c.KEY}{name}{self.c.RESET}: {self.c.ERROR}absent{self.c.RESET}")
        print("  " + "  |  ".join(parts))
        print()

    # --- Menu principal ---

    def _print_main_menu(self) -> None:
        c = self.c

        print(c.title("ANALYSE & TEST"))
        print(c.separator())
        print(c.menu_option("1", "Probe          - Analyser une vidéo (résolution, codecs, durée...)"))
        print()
        print(c.title("CONFIGURATION"))
        print(c.separator())
        print(c.menu_option("2", "Presets        - Voir et gérer les presets vidéo"))
        print(c.menu_option("3", "Outils         - Vérifier FFmpeg / FFprobe / ExifTool"))
        print(c.menu_option("4", "Paramètres     - Configuration générale"))
        print()
        print(c.menu_option("0", f"{c.DIM}Quitter{c.RESET}"))
        print()

    # --- 1. Menu Probe ---

    def _menu_probe(self) -> None:
        while True:
            clear_screen()
            print()
            print(self.c.box_header("PROBE — Analyse d'une vidéo", width=70))
            print()

            ffprobe_path = self.cfg.resolve_tool("ffprobe")
            if ffprobe_path:
                print(f"  ffprobe : {self.c.OK}OK{self.c.RESET} ({self.c.VALUE}{ffprobe_path}{self.c.RESET})")
            else:
                print(f"  ffprobe : {self.c.ERROR}non trouvé{self.c.RESET}")
                print(f"  {self.c.DIM}Configurez le chemin dans Outils (option 3).{self.c.RESET}")
                pause(self.c)
                return
            print()

            print(f"  {self.c.DIM}Entrez le chemin vers un fichier vidéo (x pour annuler) :{self.c.RESET}")
            path = input(self.c.prompt("  > ")).strip()

            if path.lower() == "x" or not path:
                return

            video_path = Path(path.strip('"').strip("'"))
            if not video_path.exists():
                print(self.c.error(f"Fichier introuvable : {video_path}"))
                pause(self.c)
                continue

            # Lancer probe
            print(f"\n{self.c.DIM}Analyse en cours...{self.c.RESET}")
            prober = FFprobe(ffprobe_path)
            try:
                info = prober.probe(str(video_path))
                h = partial_hash(str(video_path))
            except ProbeError as e:
                print(self.c.error(str(e)))
                pause(self.c)
                continue
            except OSError as e:
                print(self.c.error(f"Erreur lecture : {e}"))
                pause(self.c)
                continue

            # Rapport
            self.fmt.print_section_header("RÉSULTAT PROBE")
            self.fmt.aligned_output([
                ("Fichier",        video_path.name),
                ("Résolution",     info.resolution),
                ("Durée",          info.duration_str),
                ("FPS",            f"{info.fps:.3f}"),
                ("Codec vidéo",    info.video_codec),
                ("Codec audio",    info.audio_codec),
                ("Bitrate vidéo",  f"{info.video_bitrate} kbps" if info.video_bitrate else "inconnu"),
                ("Bitrate audio",  f"{info.audio_bitrate} kbps" if info.audio_bitrate else "inconnu"),
                ("Taille",         _format_size(info.size)),
                ("Container",      info.container),
                ("Hash (partiel)", h),
            ])

            # Suggestion de preset adapté
            print()
            suggested = _suggest_preset(info.width, info.height)
            print(f"  {self.c.DIM}Preset suggéré :{self.c.RESET} {self.c.VALUE}{suggested}{self.c.RESET}")

            self.fmt.print_section_divider()
            pause(self.c)
            return

    # --- 2. Menu Presets ---

    def _menu_presets(self) -> None:
        clear_screen()
        print()
        print(self.c.box_header("PRESETS — Configuration des presets vidéo", width=70))
        print()

        all_presets = self.presets.list_presets()
        default_key = self.cfg.get("default_preset", "medium")

        print(self.c.title("Presets disponibles"))
        print(self.c.separator())
        print()

        for key, preset in all_presets:
            marker = f" {self.c.OK}← défaut{self.c.RESET}" if key == default_key else ""
            print(
                f"  {self.c.BOLD}{preset.name:<8}{self.c.RESET}"
                f"  {self.c.VALUE}{preset.max_width}×{preset.max_height}{self.c.RESET:<6}"
                f"  {self.c.DIM}{preset.video_bitrate:>6} kbps vidéo"
                f"  {preset.audio_bitrate:>4} kbps audio"
                f"  {preset.h264_profile:<8}{self.c.RESET}"
                f"{marker}"
            )
        print()

        presets_file = self.cfg.get_presets_file()
        if presets_file.exists():
            print(f"  {self.c.DIM}Fichier :{self.c.RESET} {self.c.VALUE}{presets_file}{self.c.RESET}")
        else:
            print(f"  {self.c.DIM}Fichier presets non configuré (presets builtin utilisés){self.c.RESET}")

        print()
        pause(self.c)

    # --- 3. Menu Outils ---

    def _menu_tools(self) -> None:
        while True:
            clear_screen()
            print()
            print(self.c.box_header("OUTILS — Vérification des dépendances", width=70))
            print()

            tools = {
                "ffmpeg":   ("FFmpeg",   "Transcodage vidéo", True),
                "ffprobe":  ("FFprobe",  "Analyse vidéo (inclus avec FFmpeg)", True),
                "exiftool": ("ExifTool", "Copie de métadonnées (optionnel)", False),
            }

            all_ok = True
            missing = []

            for tool_key, (tool_name, description, required) in tools.items():
                path = self.cfg.resolve_tool(tool_key)
                if path:
                    version = _get_tool_version(tool_key, path)
                    ver_str = f" {self.c.DIM}v{version}{self.c.RESET}" if version else ""
                    print(f"  {self.c.ok_marker()} {self.c.KEY}{tool_name:<12}{self.c.RESET} {self.c.VALUE}{path}{self.c.RESET}{ver_str}")
                    print(f"      {self.c.DIM}{description}{self.c.RESET}\n")
                else:
                    all_ok = False
                    severity = "REQUIS" if required else "OPTIONNEL"
                    marker = self.c.error_marker() if required else self.c.warn_marker()
                    print(f"  {marker} {self.c.KEY}{tool_name:<12}{self.c.RESET} non trouvé ({severity})")
                    print(f"      {self.c.DIM}{description}{self.c.RESET}\n")
                    missing.append((tool_key, tool_name, required))

            # Afficher les instructions d'installation pour les outils manquants
            if missing:
                print()
                print(self.c.title("Installation des outils manquants"))
                print(self.c.separator())
                print()

                for tool_key, tool_name, _ in missing:
                    _print_install_instructions(self.c, tool_key, tool_name)

            else:
                print(self.c.success("Tous les outils requis sont disponibles."))

            print()
            if missing:
                print(f"  {self.c.YELLOW}1{self.c.RESET}. Configurer les chemins manuellement")
                print(f"  {self.c.YELLOW}0{self.c.RESET}. Retour\n")
                choice = input(self.c.prompt("Votre choix (0-1): ")).strip()
                if choice == "0":
                    return
                elif choice == "1":
                    self._menu_config()
                else:
                    print(self.c.error(f'Choix invalide : "{choice}"'))
                    pause(self.c)
            else:
                pause(self.c)
                return

    # --- 4. Menu Config ---

    def _menu_config(self) -> None:
        while True:
            clear_screen()
            print()
            print(self.c.box_header("PARAMÈTRES — Configuration générale", width=70))
            print()

            default_preset = self.cfg.get("default_preset", "medium")
            generate_poster = self.cfg.get("generate_poster", True)
            poster_ts = self.cfg.get("poster_timestamp_pct", 10)
            ffmpeg_path = self.cfg.get("ffmpeg_path", "") or self.c.DIM + "(auto)" + self.c.RESET
            ffprobe_path = self.cfg.get("ffprobe_path", "") or self.c.DIM + "(auto)" + self.c.RESET
            exiftool_path = self.cfg.get("exiftool_path", "") or self.c.DIM + "(auto)" + self.c.RESET
            presets_file = str(self.cfg.get_presets_file())

            poster_status = f"{self.c.OK}activé{self.c.RESET}" if generate_poster else f"{self.c.DIM}désactivé{self.c.RESET}"

            print(self.c.title("Paramètres actuels"))
            print()
            print(self.c.config_line("1. Preset par défaut",    default_preset))
            print(self.c.config_line("2. Génération poster",    poster_status))
            print(self.c.config_line("3. Timestamp poster",     f"{poster_ts}% de la durée"))
            print(self.c.config_line("4. FFmpeg path",          ffmpeg_path))
            print(self.c.config_line("5. FFprobe path",         ffprobe_path))
            print(self.c.config_line("6. ExifTool path",        exiftool_path))
            print(self.c.config_line("7. Fichier presets",      presets_file))
            print()
            print(self.c.separator())
            print(f"  {self.c.DIM}Numéro pour modifier, 0 pour revenir{self.c.RESET}")
            print()

            choice = input(self.c.prompt("Votre choix (0-7): ")).strip()

            if choice == "0":
                return
            elif choice == "1":
                self._edit_default_preset()
            elif choice == "2":
                current = self.cfg.get("generate_poster", True)
                self.cfg.set("generate_poster", not current)
                self.cfg.save()
            elif choice == "3":
                self._edit_poster_timestamp()
            elif choice in ("4", "5", "6"):
                key_map = {"4": "ffmpeg", "5": "ffprobe", "6": "exiftool"}
                self._edit_tool_path(key_map[choice])
            elif choice == "7":
                self._edit_presets_file()
            else:
                print(self.c.error(f'Choix invalide : "{choice}"'))
                pause(self.c)

    def _edit_default_preset(self) -> None:
        print()
        print(self.c.title("Preset par défaut"))
        print(self.c.separator())
        for i, key in enumerate(PRESET_ORDER, 1):
            preset = self.presets.get_preset(key)
            print(f"  {self.c.YELLOW}{i}{self.c.RESET}. {preset.name} ({preset.max_width}×{preset.max_height})")
        print()
        choice = input(self.c.prompt("Choix (1-6, x pour annuler): ")).strip()
        if choice.lower() == "x":
            return
        try:
            idx = int(choice) - 1
            if 0 <= idx < len(PRESET_ORDER):
                self.cfg.set("default_preset", PRESET_ORDER[idx])
                self.cfg.save()
                print(self.c.success(f"Preset par défaut : {PRESET_ORDER[idx]}"))
            else:
                print(self.c.error(f'Choix invalide : "{choice}"'))
        except ValueError:
            print(self.c.error(f'Choix invalide : "{choice}"'))
        pause(self.c)

    def _edit_poster_timestamp(self) -> None:
        print()
        current = self.cfg.get("poster_timestamp_pct", 10)
        val = input(self.c.prompt(f"Timestamp poster en % (actuel: {current}%, x pour annuler): ")).strip()
        if val.lower() == "x" or not val:
            return
        try:
            pct = int(val)
            if 0 <= pct <= 95:
                self.cfg.set("poster_timestamp_pct", pct)
                self.cfg.save()
                print(self.c.success(f"Timestamp poster : {pct}%"))
            else:
                print(self.c.error("Valeur entre 0 et 95"))
        except ValueError:
            print(self.c.error(f'Valeur invalide : "{val}"'))
        pause(self.c)

    def _edit_tool_path(self, tool: str) -> None:
        print()
        current = self.cfg.get(f"{tool}_path", "")
        if current:
            print(f"  Actuel : {self.c.VALUE}{current}{self.c.RESET}")
        print(f"  {self.c.DIM}Laissez vide pour auto-détection (ENTRÉE pour garder, x pour annuler){self.c.RESET}")
        val = input(self.c.prompt(f"Chemin {tool}: ")).strip()
        if val.lower() == "x":
            return
        if val == "":
            print(self.c.success("Chemin inchangé"))
            return
        self.cfg.set(f"{tool}_path", val)
        self.cfg.save()
        print(self.c.success(f"{tool} configuré : {val}"))
        pause(self.c)

    def _edit_presets_file(self) -> None:
        print()
        current = str(self.cfg.get_presets_file())
        print(f"  Actuel : {self.c.VALUE}{current}{self.c.RESET}")
        val = input(self.c.prompt("Chemin fichier presets (ENTRÉE pour garder, x pour annuler): ")).strip()
        if val.lower() == "x":
            return
        if val == "":
            print(self.c.success("Chemin inchangé"))
            return
        self.cfg.set("presets_file", val)
        self.cfg.save()
        print(self.c.success(f"Fichier presets : {val}"))
        pause(self.c)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _json_error(msg: str) -> None:
    """Écrit une erreur JSON sur stderr (pour les appels Lightroom)."""
    import json as _json
    print(_json.dumps({"status": "error", "error": msg}), file=sys.stderr)


def _format_size(size: int) -> str:
    for unit in ("o", "Ko", "Mo", "Go"):
        if size < 1024:
            return f"{size:.1f} {unit}"
        size /= 1024
    return f"{size:.1f} To"


def _suggest_preset(width: int, height: int) -> str:
    """Suggère le preset le plus adapté à la résolution source."""
    if width >= 3840 or height >= 2160:
        return "xxl"
    if width >= 2560 or height >= 1440:
        return "xlarge"
    if width >= 1920 or height >= 1080:
        return "large"
    if width >= 1280 or height >= 720:
        return "medium"
    return "small"


def _get_tool_version(tool: str, path: str) -> str | None:
    """Extrait la version d'un outil (ffmpeg, ffprobe, exiftool)."""
    import subprocess
    try:
        r = subprocess.run([path, "-version"], capture_output=True, text=True, timeout=5)
        first = r.stdout.splitlines()[0] if r.stdout else ""
        parts = first.split()
        if tool in ("ffmpeg", "ffprobe") and len(parts) >= 3:
            return parts[2]
        if tool == "exiftool" and len(parts) >= 2:
            return parts[-1]
    except Exception:
        pass
    return None


INSTALL_INSTRUCTIONS = {
    "ffmpeg": {
        "Windows": [
            ("Méthode 1 (recommandée):", "winget install ffmpeg"),
            ("Méthode 2 (Chocolatey):", "choco install ffmpeg"),
            ("Méthode 3 (manuel):", "Télécharger sur https://ffmpeg.org/download.html"),
        ],
        "macOS": [
            ("Avec Homebrew:", "brew install ffmpeg"),
            ("Voir aussi:", "https://ffmpeg.org/download.html"),
        ],
        "Linux": [
            ("Debian/Ubuntu:", "sudo apt install ffmpeg"),
            ("Fedora/RHEL:", "sudo dnf install ffmpeg"),
            ("Arch:", "sudo pacman -S ffmpeg"),
        ],
    },
    "exiftool": {
        "Windows": [
            ("Méthode 1 (winget):", "winget install exiftool"),
            ("Méthode 2 (Chocolatey):", "choco install exiftool"),
            ("Méthode 3 (manuel):", "Télécharger sur https://exiftool.org/"),
        ],
        "macOS": [
            ("Avec Homebrew:", "brew install exiftool"),
            ("Voir aussi:", "https://exiftool.org/"),
        ],
        "Linux": [
            ("Debian/Ubuntu:", "sudo apt install libimage-exiftool-perl"),
            ("Fedora/RHEL:", "sudo dnf install perl-Image-ExifTool"),
            ("Arch:", "sudo pacman -S perl-image-exiftool"),
        ],
    },
}


def _print_install_instructions(c: Colors, tool: str, tool_name: str) -> None:
    """Affiche les instructions d'installation pour un outil."""
    import sys

    instructions = INSTALL_INSTRUCTIONS.get(tool, {})
    if not instructions:
        print(f"  {c.DIM}Aucune instruction d'installation pour {tool_name}{c.RESET}\n")
        return

    platform = "Windows" if sys.platform == "win32" else ("macOS" if sys.platform == "darwin" else "Linux")
    methods = instructions.get(platform, instructions.get("Linux", []))

    print(f"  {c.BOLD}{tool_name}{c.RESET}")
    for label, cmd in methods:
        print(f"    {c.DIM}{label}{c.RESET}")
        print(f"      {c.VALUE}{cmd}{c.RESET}")
    print()
