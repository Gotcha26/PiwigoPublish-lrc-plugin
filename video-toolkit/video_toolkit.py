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
