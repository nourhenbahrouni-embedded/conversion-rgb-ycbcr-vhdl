import os
import numpy as np
from PIL import Image

os.chdir(os.path.dirname(os.path.abspath(__file__)))   # travailler dans le dossier du script

LARGEUR = 128
HAUTEUR = 128


def lire_hex24(nom):
    """Lit un fichier 'AABBCC' par ligne -> 3 tableaux d'entiers."""
    with open(nom) as f:
        v = np.array([int(l, 16) for l in f if l.strip()], dtype=np.int64)
    return (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF


# ---------------------------------------------------------------
# 1. Entrée : les pixels R, G, B
# ---------------------------------------------------------------
R, G, B = lire_hex24("image_rgb.txt")

# ---------------------------------------------------------------
# 2. Corrigé : mêmes formules entières que matricage.vhd
# ---------------------------------------------------------------
Y_ref  = (77 * R + 150 * G + 29 * B) >> 8
Cb_ref = (128 * B + 32768 - 43 * R - 85 * G) >> 8
Cr_ref = (128 * R + 32768 - 107 * G - 21 * B) >> 8

# ---------------------------------------------------------------
# 3. Sortie du VHDL : une ligne = YYCbCr
# ---------------------------------------------------------------
Y_vhdl, Cb_vhdl, Cr_vhdl = lire_hex24("matricage_sortie.txt")
print("image_rgb.txt        :", len(R), "pixels")
print("matricage_sortie.txt :", len(Y_vhdl), "pixels")

# ---------------------------------------------------------------
# 4. Comparaison, composante par composante
# ---------------------------------------------------------------
erreurs = 0
for nom, vhdl, ref in [("Y ", Y_vhdl, Y_ref), ("Cb", Cb_vhdl, Cb_ref), ("Cr", Cr_vhdl, Cr_ref)]:
    diff = np.nonzero(vhdl != ref)[0]
    erreurs += len(diff)
    print(f"  {nom} : {len(diff)} pixel(s) different(s)")
    for a in diff[:5]:
        print(f"       ligne {a // LARGEUR}, colonne {a % LARGEUR} : VHDL = {vhdl[a]}, attendu = {ref[a]}")

if erreurs == 0:
    print("RESULTAT : 0 difference -> le matricage VHDL est correct !")

# Le Y doit aussi être identique à l'ancienne conversion en gris
if os.path.exists("reference_gris.txt"):
    with open("reference_gris.txt") as f:
        gris = np.array([int(l, 16) for l in f if l.strip()])
    print("Y identique a reference_gris.txt :", "oui" if np.array_equal(gris, Y_vhdl) else "NON")

# ---------------------------------------------------------------
# 5. Dématriçage : Y Cb Cr -> R G B (matrice inverse)
# ---------------------------------------------------------------
Yf, Cbf, Crf = Y_vhdl.astype(float), Cb_vhdl - 128.0, Cr_vhdl - 128.0
R2 = np.clip(np.round(Yf + 1.402 * Crf), 0, 255)
G2 = np.clip(np.round(Yf - 0.344136 * Cbf - 0.714136 * Crf), 0, 255)
B2 = np.clip(np.round(Yf + 1.772 * Cbf), 0, 255)

ecart = np.abs(np.stack([R2 - R, G2 - G, B2 - B]))
print(f"Dematricage : ecart moyen {ecart.mean():.2f}, ecart max {int(ecart.max())} "
      "(sur 255, du aux arrondis)")

# ---------------------------------------------------------------
# 6. Image : original | Y | Cb | Cr | couleur reconstruite
# ---------------------------------------------------------------
def gris(v):
    return Image.fromarray(v.reshape(HAUTEUR, LARGEUR).astype(np.uint8), mode="L").convert("RGB")

def couleur(r, g, b):
    return Image.fromarray(np.stack([r, g, b], axis=-1).reshape(HAUTEUR, LARGEUR, 3).astype(np.uint8))

images = [couleur(R, G, B), gris(Y_vhdl), gris(Cb_vhdl), gris(Cr_vhdl), couleur(R2, G2, B2)]
planche = Image.new("RGB", (5 * LARGEUR + 40, HAUTEUR), "white")
for i, im in enumerate(images):
    planche.paste(im, (i * (LARGEUR + 10), 0))
planche.save("matricage_resultat.png")
print("Images : matricage_resultat.png  (original | Y | Cb | Cr | couleur reconstruite)")