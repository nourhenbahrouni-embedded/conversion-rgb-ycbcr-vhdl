import os
os.chdir(os.path.dirname(os.path.abspath(__file__)))
from PIL import Image
import numpy as np

# ---------------------------------------------------------------
# 1. Ouvrir l'image couleur
# ---------------------------------------------------------------
img = Image.open("Image.jpg").convert("RGB")   # force le format R, G, B
print("Taille originale (largeur, hauteur) :", img.size)

# ---------------------------------------------------------------
# 2. Réduire l'image (la mémoire du FPGA est petite)
# ---------------------------------------------------------------
LARGEUR = 128
HAUTEUR = 128
img = img.resize((LARGEUR, HAUTEUR))
img.save("image_rgb_redimensionnee.png")

# ---------------------------------------------------------------
# 3. Obtenir la matrice des pixels
# ---------------------------------------------------------------
M = np.array(img)                 # M[ligne, colonne] = [R, G, B]
print("Forme de la matrice :", M.shape)      # (128, 128, 3)

R = M[:, :, 0]                    # matrice du rouge (128 x 128)
G = M[:, :, 1]                    # matrice du vert
B = M[:, :, 2]                    # matrice du bleu

# ---------------------------------------------------------------
# 4. Regarder quelques valeurs
# ---------------------------------------------------------------
print("Pixel (0,0)   -> R, G, B =", M[0, 0])
print("Pixel (64,64) -> R, G, B =", M[64, 64])
print("Coin 5x5 de la matrice R :")
print(R[:5, :5])

# ---------------------------------------------------------------
# 5. Écrire la matrice dans image_rgb.txt (pour le VHDL)
#    une ligne = un pixel = 6 chiffres hexa RRGGBB
#    ordre : ligne 0 de gauche à droite, puis ligne 1, ...
# ---------------------------------------------------------------
with open("image_rgb.txt", "w") as f:
    for ligne in range(HAUTEUR):
        for colonne in range(LARGEUR):
            r = int(R[ligne, colonne])
            g = int(G[ligne, colonne])
            b = int(B[ligne, colonne])
            f.write(f"{r:02X}{g:02X}{b:02X}\n")
print("image_rgb.txt écrit :", LARGEUR * HAUTEUR, "lignes")

# ---------------------------------------------------------------
# 6. Résultat attendu, avec la même formule que le circuit VHDL
# ---------------------------------------------------------------
Y = (77 * R.astype(int) + 150 * G.astype(int) + 29 * B.astype(int)) >> 8

with open("reference_gris.txt", "w") as f:
    for valeur in Y.flatten():
        f.write(f"{int(valeur):02X}\n")
Image.fromarray(Y.astype(np.uint8)).save("reference_gris.png")
print("reference_gris.txt et reference_gris.png écrits")