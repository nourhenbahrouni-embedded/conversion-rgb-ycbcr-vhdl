import os
import numpy as np
from PIL import Image

os.chdir(os.path.dirname(os.path.abspath(__file__)))   # travailler dans le dossier du script

LARGEUR = 128
HAUTEUR = 128

# 1. Lire les deux fichiers (une valeur hexa par ligne)
def lire_hex(nom):
    with open(nom) as f:
        return np.array([int(l, 16) for l in f if l.strip()], dtype=np.uint8)

sortie = lire_hex("gris_sortie.txt")         # resultat du VHDL (ModelSim)
reference = lire_hex("reference_gris.txt")   # resultat attendu (Python)

print("gris_sortie.txt    :", len(sortie), "pixels")
print("reference_gris.txt :", len(reference), "pixels")

# 2. Reconstruire l'image produite par le VHDL
img = sortie.reshape(HAUTEUR, LARGEUR)
Image.fromarray(img, mode="L").save("sortie_gris.png")
print("Image reconstruite : sortie_gris.png")

# 3. Comparer pixel par pixel
differences = np.nonzero(sortie != reference)[0]
if len(differences) == 0:
    print("RESULTAT : 0 pixel different -> le circuit VHDL est correct !")
else:
    print("RESULTAT :", len(differences), "pixel(s) different(s). Les 10 premiers :")
    for a in differences[:10]:
        print(f"  ligne {a // LARGEUR}, colonne {a % LARGEUR} : "
              f"VHDL = {sortie[a]}, attendu = {reference[a]}")