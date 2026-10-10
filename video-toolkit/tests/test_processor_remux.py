"""
Tests unitaires — processor._source_fits_preset
Règle de remux : une source SDR n'est copiée sans réencodage que si elle tient déjà
dans le preset demandé et qu'elle est en H.264.
"""

import sys
from pathlib import Path

# Ajout du répertoire parent pour l'import
sys.path.insert(0, str(Path(__file__).parent.parent))

from src.ffprobe import VideoInfo
from src.presets import BUILTIN_PRESETS
from src.processor import _source_fits_preset


def make_info(width, height, codec="h264"):
    return VideoInfo(
        path="x.mp4", width=width, height=height, duration=3.0,
        video_codec=codec, audio_codec="aac", video_bitrate=0, audio_bitrate=0,
        fps=30.0, size=0, container="mp4",
    )


class TestSourceFitsPreset:
    def test_4k_hevc_does_not_fit_small(self):
        # Cas réel du 2026-10-10 : 4K HEVC SDR + preset small → doit être réencodée
        assert _source_fits_preset(make_info(3840, 2160, "hevc"), BUILTIN_PRESETS["small"]) is False

    def test_4k_h264_does_not_fit_small(self):
        assert _source_fits_preset(make_info(3840, 2160), BUILTIN_PRESETS["small"]) is False

    def test_480p_h264_fits_small(self):
        assert _source_fits_preset(make_info(854, 480), BUILTIN_PRESETS["small"]) is True

    def test_smaller_h264_fits_medium(self):
        assert _source_fits_preset(make_info(640, 360), BUILTIN_PRESETS["medium"]) is True

    def test_small_hevc_never_fits(self):
        # Résolution OK mais codec non lisible partout → réencodage en H.264
        assert _source_fits_preset(make_info(640, 360, "hevc"), BUILTIN_PRESETS["medium"]) is False

    def test_portrait_orientation_agnostic(self):
        # 480x854 portrait tient dans la boîte 854x480 du preset small
        assert _source_fits_preset(make_info(480, 854), BUILTIN_PRESETS["small"]) is True

    def test_portrait_too_large(self):
        assert _source_fits_preset(make_info(1080, 1920), BUILTIN_PRESETS["small"]) is False

    def test_codec_case_insensitive(self):
        assert _source_fits_preset(make_info(640, 360, "H264"), BUILTIN_PRESETS["medium"]) is True
