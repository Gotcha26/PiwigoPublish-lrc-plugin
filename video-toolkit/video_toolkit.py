#!/usr/bin/env python3
"""
Video Toolkit — Point d'entrée principal.

Usage non-interactif (depuis Lightroom) :
    python video_toolkit.py --mode probe --input video.mp4
    python video_toolkit.py --mode batch --batch-file batch.json --status-file status.json
    python video_toolkit.py --mode status --input video.mp4

Usage interactif (terminal) :
    python video_toolkit.py

Codes de sortie :
    0 = succès
    1 = erreur (message JSON sur stderr)
"""

import sys
import os

# Ajouter le répertoire du script au path
sys.path.insert(0, os.path.dirname(__file__))

from src.cli import build_parser, run_probe, run_process, run_batch, run_status, run_clean, InteractiveCLI
from src.config import Config


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    # Charger la configuration
    cfg = Config(args.config if hasattr(args, "config") and args.config else None)

    # Mode non-interactif (avec --mode)
    if args.mode:
        if args.mode == "check":
            import json
            from pathlib import Path
            # Lire les chemins configurés depuis le fichier JSON passé par Lightroom
            explicit = {}
            check_cfg = getattr(args, "check_config", None)
            if check_cfg:
                try:
                    with open(check_cfg, "r", encoding="utf-8") as fh:
                        explicit = json.load(fh)
                except Exception:
                    pass

            tools_out = {}
            for tool in ["ffmpeg", "ffprobe", "exiftool"]:
                configured = explicit.get(tool)
                if configured:
                    # Chemin fourni explicitement : vérifier qu'il existe
                    if Path(configured).is_file():
                        tools_out[tool] = configured
                    else:
                        tools_out[tool] = f"not found at: {configured}"
                else:
                    # Auto-détection
                    found = cfg.resolve_tool(tool)
                    tools_out[tool] = found or "not found"

            any_invalid = any(v.startswith("not found at:") for v in tools_out.values() if v)
            ok = (tools_out["ffprobe"] not in (None, "not found")
                  and not tools_out["ffprobe"].startswith("not found at:")
                  and not any_invalid)
            print(json.dumps({
                "status":         "ok" if ok else "error",
                "python_version": sys.version.split()[0],
                "ffmpeg":         tools_out["ffmpeg"],
                "ffprobe":        tools_out["ffprobe"],
                "exiftool":       tools_out["exiftool"],
            }))
            return 0 if ok else 1
        if args.mode == "probe":
            return run_probe(args, cfg)
        if args.mode == "process":
            return run_process(args, cfg)
        if args.mode == "batch":
            return run_batch(args, cfg)
        if args.mode == "status":
            return run_status(args, cfg)
        if args.mode == "clean":
            return run_clean(args, cfg)

    # Mode interactif
    cli = InteractiveCLI(cfg)
    cli.run()
    return 0


if __name__ == "__main__":
    sys.exit(main())
