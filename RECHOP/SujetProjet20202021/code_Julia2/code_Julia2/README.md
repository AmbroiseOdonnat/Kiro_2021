# Code Julia pour le projet REOP

## Utilisation

Ce dossier contient un code Julia permettant de bien démarrer le projet du cours de recherche opérationnelle. Il peut bien sûr être utilisé en Julia, mais aussi appelé via Python grâce à la librarie [pyjulia](https://pyjulia.readthedocs.io/en/stable/). Si vous débutez en Julia, n'hésitez pas à vous référer à mon tutoriel https://github.com/gdalle/IntroJulia.

Lors de la première exécution, il est probable que vous ne possédiez pas tous les packages Julia nécessaires. Dans ce cas, il suffit de suivre les instructions données par la console et d'installer chacun graĉe aux commandes suivantes :

```julia
import Pkg
Pkg.add("packagename")
```

S'il vous manque des packages Python (notamment folium), c'est dans le fichier `plot.jl` qu'il faut les installer via Conda, en décommentant la ligne appropriée au début du fichier.

Le notebook Jupyter `Projet REOP.ipynb` présente un exemple d'utilisation des principales fonctions.

## Contenu

Toutes les fonctions sont importées par le fichier `import_all.jl`, dans un ordre cohérent avec leurs dépendances mutuelles. Voici une brève description des autres fichiers :

- `cout.jl` : Calcul du coût d'une solution.
- `distances.jl` : Matrices de distance.
- `emballage.jl` : Définition de la classe `Emballage` et lecture à partir d'une chaîne de caractères.
- `export.jl` : Ecriture des instances et solutions dans un fichier texte.
- `faisabilite.jl` : Vérification d'une partie des contraintes pour une solution sur une instance. Tout n'est pas vérifié, on fait confiance à l'utilisateur du code pour certains aspects.
- `fournisseur.jl` : Définition de la classe `Fournisseur` et lecture à partir d'une chaîne de caractères.
- `instance.jl` : Définition de la classe `Instance`, qui regroupe tous les paramètres d'une instance ainsi qu'une solution (vide par défaut), et lecture à partir d'un fichier.
- `instance_modif.jl` : Restriction géographique.
- `plot.jl` : Outils de visualisation d'une instance ou d'une solution, notamment avec un fond OpenStreetMap.
- `route.jl` : Définition de la classe `Route` et lecture à partir d'une chaîne de caractères, interactions route / site.
- `solution.jl` : Deux structures différentes pour stocker une solution (`SolutionSimple` et `SolutionStructuree`), qui peut être lue à partir d'un fichier et modifée.
- `stocks.jl` : Calcul des stocks de chaque site à partir d'une `Solution`, soit *in-place* soit dans une nouvelle `Instance`.
- `usine.jl` : Définition de la classe `Usine` et lecture à partir d'une chaîne de caractères.
