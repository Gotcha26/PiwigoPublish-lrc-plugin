# Video Toolkit — Installation

## Dépendances

### Requis

- **Python** 3.8+
- **FFmpeg** 5.0+ (transccodage vidéo + analyse avec ffprobe)

### Optionnel

- **ExifTool** 12+ (copie de métadonnées — sans lui, les métadonnées ne sont pas copiées)

## Installation par système

### Windows

#### Via winget (recommandé)
```bash
winget install ffmpeg
winget install exiftool
```

#### Via Chocolatey
```bash
choco install ffmpeg
choco install exiftool
```

#### Manuel
1. Télécharger FFmpeg : https://ffmpeg.org/download.html
   - Extraire le ZIP dans `C:\ffmpeg\`
   - Ajouter `C:\ffmpeg\bin` à la variable PATH (ou configurer dans le toolkit)

2. Télécharger ExifTool : https://exiftool.org/
   - Mettre le `.exe` dans `C:\exiftool\` (ou un dossier dans PATH)

### macOS

```bash
brew install python@3.11
brew install ffmpeg
brew install exiftool
```

### Linux (Debian/Ubuntu)

```bash
sudo apt update
sudo apt install python3 ffmpeg exiftool
```

### Linux (Fedora/RHEL)

```bash
sudo dnf install python3 ffmpeg perl-Image-ExifTool
```

### Linux (Arch)

```bash
sudo pacman -S python ffmpeg perl-image-exiftool
```

## Configuration du toolkit

### Mode 1 : Auto-détection (recommandé)

Les outils sont détectés automatiquement si :
- Ils sont dans le PATH système
- Ou aux emplacements courants (Windows: `C:\ffmpeg\bin\ffmpeg.exe`, etc.)

Lancez le toolkit en mode interactif pour vérifier :
```bash
cd video-toolkit
python video_toolkit.py
# Menu "Outils" affichera l'état de chaque outil
```

### Mode 2 : Configurer manuellement

Si l'auto-détection échoue, configurez les chemins dans le menu "Paramètres" du toolkit interactif.

```bash
python video_toolkit.py
# → Paramètres (option 4)
# → Modifier FFmpeg path / FFprobe path / ExifTool path
```

Ou éditer directement `~/.piwigoPublish/video-toolkit.json` :

```json
{
  "ffmpeg_path": "C:\\Program Files\\ffmpeg\\bin\\ffmpeg.exe",
  "ffprobe_path": "C:\\Program Files\\ffmpeg\\bin\\ffprobe.exe",
  "exiftool_path": "C:\\exiftool\\exiftool.exe"
}
```

## Vérification

```bash
python video_toolkit.py --mode probe --input sample_video.mp4
```

Doit retourner un JSON avec résolution, durée, codecs, etc.

```bash
python video_toolkit.py
# Menu interactif → Outils (option 3) pour vérifier l'état des dépendances
```
